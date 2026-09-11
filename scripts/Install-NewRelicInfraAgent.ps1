#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs (or upgrades) the latest New Relic infrastructure agent on a Windows host,
    with or without a proxy.

.DESCRIPTION
    Downloads the current agent MSI from download.newrelic.com and installs it unattended.
    Safe to paste onto a host that already has the agent: an install over an existing one
    is an in-place upgrade that preserves newrelic-infra.yml and everything under
    integrations.d, so it will not undo a winservices setup.

    Run Enable-NriWinservices.ps1 afterwards to turn on Windows service monitoring -- that
    integration ships inside this agent, so it needs no separate download.

    PROXY
    -----
    Three cases, in order of how common they are here:

      1. No proxy. Omit every proxy parameter. This is the right call for the AWS hosts,
         which reach New Relic directly.

      2. Plain proxy. Pass -Proxy 'http://HOST:PORT'. The value is written to the agent's
         config and also used for the MSI download itself, since a host behind a proxy
         usually cannot reach download.newrelic.com either.

      3. Proxy that intercepts TLS (MITM with its own CA). Pass -Proxy together with
         -ProxyCaBundleFile pointing at the proxy's CA certificate in PEM form. Without
         it the agent cannot open an HTTPS connection through the proxy and fails with
         certificate errors that do not name the proxy as the cause. Use
         -SkipProxyCertValidation only to confirm a diagnosis, never as the end state:
         it turns off validation of the proxy certificate entirely.

    To discover an existing proxy on a host that already works:
        netsh winhttp show proxy
        Select-String -Path 'C:\Program Files\New Relic\newrelic-infra\newrelic-infra.yml' -Pattern proxy

    NOTES
      * LicenseKey is the ingest key, NOT the NRAK- user key Terraform uses. Fetch it with:
          curl -s -X POST https://api.newrelic.com/graphql -H "Api-Key: $NEW_RELIC_API_KEY" \
            -H 'Content-Type: application/json' \
            -d '{"query":"{ actor { account(id: 1468011) { licenseKey } } }"}'
      * TLS 1.2 is forced before the download: Server 2016 and older negotiate TLS 1.0 by
        default and download.newrelic.com refuses it.
      * Exit code 3010 is treated as success. It means "installed, reboot queued"; neither
        the agent nor this script needs that reboot.

.PARAMETER LicenseKey
    New Relic ingest license key. Required.

.PARAMETER DisplayName
    Name the host reports under. Defaults to the machine's own hostname.

.PARAMETER Proxy
    Proxy URL: http://HOST:PORT, or http://user:password@HOST:PORT when it authenticates.

.PARAMETER UseSystemProxy
    Read the proxy from the machine's WinHTTP configuration instead of passing it by hand.
    Fails if WinHTTP has none set, rather than silently installing without a proxy.

.PARAMETER ProxyCaBundleFile
    Path to the proxy's CA certificate (PEM). Required when the proxy intercepts TLS.
    The file is copied next to the agent config so it survives an agent upgrade.

.PARAMETER SkipProxyCertValidation
    Disable proxy certificate validation. Diagnostic only.

.PARAMETER Tags
    Custom attributes attached to every sample, e.g. @{ env = 'test' }. They become facets
    you can filter dashboards and alerts by.

.EXAMPLE
    # No proxy
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' -Tags @{ env = 'test' }

.EXAMPLE
    # Plain proxy
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' -Proxy 'http://10.0.0.10:8080'

.EXAMPLE
    # Proxy that intercepts TLS
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' `
        -Proxy 'http://10.0.0.10:8080' -ProxyCaBundleFile 'C:\certs\corp-ca.pem'

.EXAMPLE
    # Take the proxy from the machine's own WinHTTP settings
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' -UseSystemProxy

.EXAMPLE
    # Whole fleet at once (requires WinRM)
    $hosts = 'UE1-TEST-ADC-A2','UE1-TEST-ADC-B2','UE1-TEST-WEB-B1','UE1-TEST-SQL-A2','UE1-TEST-SQL-B2'
    Invoke-Command -ComputerName $hosts -FilePath .\Install-NewRelicInfraAgent.ps1 `
        -ArgumentList 'xxxxxxxxNRAL' -ErrorAction Continue
#>
[CmdletBinding(DefaultParameterSetName = 'Direct')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]    $LicenseKey,

    [string]    $DisplayName = $env:COMPUTERNAME,

    [Parameter(ParameterSetName = 'Proxy')]
    [ValidatePattern('^https?://')]
    [string]    $Proxy,

    [Parameter(ParameterSetName = 'SystemProxy')]
    [switch]    $UseSystemProxy,

    [Parameter(ParameterSetName = 'Proxy')]
    [Parameter(ParameterSetName = 'SystemProxy')]
    [string]    $ProxyCaBundleFile,

    [Parameter(ParameterSetName = 'Proxy')]
    [Parameter(ParameterSetName = 'SystemProxy')]
    [switch]    $SkipProxyCertValidation,

    [hashtable] $Tags = @{}
)

$ErrorActionPreference = 'Stop'

$msiUrl    = 'https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.msi'
$agentRoot = 'C:\Program Files\New Relic\newrelic-infra'
$agentExe  = Join-Path $agentRoot 'newrelic-infra.exe'
$config    = Join-Path $agentRoot 'newrelic-infra.yml'
$msiPath   = Join-Path $env:TEMP 'newrelic-infra.msi'
$msiLog    = Join-Path $env:TEMP 'newrelic-infra-install.log'

function Write-Step { param([string] $m) Write-Host "  $m" -ForegroundColor Cyan }
function Write-Ok   { param([string] $m) Write-Host "  $m" -ForegroundColor Green }
function Write-Warn { param([string] $m) Write-Host "  $m" -ForegroundColor Yellow }

Write-Host "`nNew Relic infrastructure agent -- $env:COMPUTERNAME`n" -ForegroundColor White

# ---------------------------------------------------------------- preflight

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'This agent requires a 64-bit version of Windows.'
}

$existing = Get-Service -Name 'newrelic-infra' -ErrorAction SilentlyContinue
if ($existing) {
    $before = (Get-Item $agentExe -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
    Write-Warn "Already installed (version $before, service $($existing.Status)). Upgrading in place."
}

# Resolve the proxy from WinHTTP when asked to.
if ($UseSystemProxy) {
    $winhttp = (netsh winhttp show proxy) -join ' '
    if ($winhttp -match 'Proxy Server\(s\)\s*:\s*(\S+)') {
        $found = $Matches[1]
        $Proxy = if ($found -match '^https?://') { $found } else { "http://$found" }
        Write-Ok "Proxy from WinHTTP: $Proxy"
    }
    else {
        throw 'WinHTTP has no proxy configured. Pass -Proxy explicitly, or drop -UseSystemProxy if the host needs none.'
    }
}

if ($ProxyCaBundleFile) {
    if (-not (Test-Path -LiteralPath $ProxyCaBundleFile)) {
        throw "CA bundle not found: $ProxyCaBundleFile"
    }
    if ((Get-Content -LiteralPath $ProxyCaBundleFile -Raw) -notmatch '-----BEGIN CERTIFICATE-----') {
        throw "$ProxyCaBundleFile is not PEM. Convert a .cer/.crt with: certutil -encode in.cer out.pem"
    }
}

if ($Proxy) { Write-Step "Using proxy: $Proxy" } else { Write-Step 'No proxy: connecting directly.' }

# ---------------------------------------------------------------- download

Write-Step 'Downloading the latest installer...'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$download = @{ Uri = $msiUrl; OutFile = $msiPath; UseBasicParsing = $true }
if ($Proxy) {
    # A host behind a proxy usually cannot reach download.newrelic.com directly either.
    $download.Proxy = $Proxy
    $download.ProxyUseDefaultCredentials = $true
}

$progressBefore = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'   # a visible progress bar makes this ~10x slower
try     { Invoke-WebRequest @download }
finally { $ProgressPreference = $progressBefore }

$sizeMb = [math]::Round((Get-Item $msiPath).Length / 1MB, 1)
if ($sizeMb -lt 1) { throw "The downloaded file is only $sizeMb MB -- it is not a valid MSI." }
Write-Ok "Downloaded $sizeMb MB."

# ---------------------------------------------------------------- install

Write-Step 'Installing...'
$msiArgs = @(
    '/qn', '/norestart',
    '/i', "`"$msiPath`"",
    'GENERATE_CONFIG=true',
    "LICENSE_KEY=$LicenseKey",
    "DISPLAY_NAME=$DisplayName",
    '/L*v', "`"$msiLog`""
)
if ($Proxy)        { $msiArgs += "PROXY=$Proxy" }
if ($Tags.Count)   {
    # CUSTOM_ATTRIBUTES takes JSON and lets the installer own the config file end to end,
    # which beats hand-editing the YAML it just generated.
    $json = $Tags | ConvertTo-Json -Compress
    $msiArgs += "CUSTOM_ATTRIBUTES=$json"
    Write-Step "Custom attributes: $json"
}

$proc = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
if ($proc.ExitCode -notin 0, 3010) {
    throw "msiexec returned $($proc.ExitCode). Full log: $msiLog"
}
if (-not (Test-Path $config)) { throw "The installer did not create $config. Full log: $msiLog" }
Write-Ok 'Installed.'

# ---------------------------------------------------------------- proxy TLS

# The MSI writes `proxy:` but has no property for the certificate settings, so a proxy
# that intercepts TLS needs these appended afterwards.
if ($ProxyCaBundleFile -or $SkipProxyCertValidation) {
    Write-Step 'Configuring proxy certificate handling...'

    $lines = @(Get-Content -LiteralPath $config |
               Where-Object { $_ -notmatch '^\s*(ca_bundle_file|ca_bundle_dir|proxy_validate_certificates)\s*:' })

    if ($ProxyCaBundleFile) {
        # Keep our own copy: the source path may be a share that is gone at next boot.
        $caTarget = Join-Path $agentRoot 'proxy-ca.pem'
        Copy-Item -LiteralPath $ProxyCaBundleFile -Destination $caTarget -Force
        $lines += "ca_bundle_file: $caTarget"
        $lines += 'proxy_validate_certificates: true'
        Write-Ok "CA bundle installed at $caTarget"
    }
    if ($SkipProxyCertValidation) {
        $lines += 'proxy_validate_certificates: false'
        Write-Warn 'Proxy certificate validation is OFF. Diagnostic only -- do not leave a host like this.'
    }

    # UTF-8 without BOM: the agent's YAML parser rejects a BOM and logs nothing useful.
    [System.IO.File]::WriteAllLines($config, $lines, (New-Object System.Text.UTF8Encoding $false))
    Restart-Service newrelic-infra
}

# ---------------------------------------------------------------- verify

Write-Step 'Verifying...'
$svc = Get-Service -Name 'newrelic-infra' -ErrorAction SilentlyContinue
if (-not $svc) { throw 'The newrelic-infra service does not exist after installation.' }
if ($svc.Status -ne 'Running') {
    Start-Service newrelic-infra
    Start-Sleep -Seconds 3
    $svc.Refresh()
}

$version = (Get-Item $agentExe).VersionInfo.ProductVersion
Remove-Item $msiPath -ErrorAction SilentlyContinue

Write-Host ''
Write-Ok "Service    : $($svc.Status)"
Write-Ok "Version    : $version"
Write-Ok "Reports as : $DisplayName"
if ($Proxy) { Write-Ok "Proxy      : $Proxy" }

Write-Host @"

  Data reaches New Relic within about 2 minutes. Confirm with:

    SELECT latest(agentVersion) FROM SystemSample
    WHERE hostname = '$DisplayName' SINCE 10 minutes ago

  If nothing arrives, the agent log names the reason:
    Get-Content '$agentRoot\newrelic-infra.log' -Tail 40

  Then run Enable-NriWinservices.ps1 on this host for Windows service monitoring.

"@ -ForegroundColor Gray
