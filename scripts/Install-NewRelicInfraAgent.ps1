#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs (or upgrades) the New Relic infrastructure agent on a Windows host.

.DESCRIPTION
    Downloads the current agent MSI and installs it unattended, writing newrelic-infra.yml
    with the license key and a display name. Safe to paste onto a host that already has the
    agent: an install over an existing one is an in-place upgrade and preserves both the
    config file and anything under integrations.d, so it will not undo a winservices setup.

    Run Enable-NriWinservices.ps1 afterwards to turn on Windows service monitoring -- that
    integration ships bundled with this agent, so it needs no separate download.

    Notes:
      * The LICENSE key is the ingest key, NOT the NRAK- user key used by Terraform.
        Retrieve it with:
          SELECT 1  -- or, from a shell with .env loaded:
          curl -s -X POST https://api.newrelic.com/graphql -H "Api-Key: $NEW_RELIC_API_KEY" \
            -H 'Content-Type: application/json' \
            -d '{"query":"{ actor { account(id: 1468011) { licenseKey } } }"}'
      * The agent only needs outbound HTTPS. A proxy already working for other agents needs
        no extra handling here; set -Proxy explicitly only on a host that requires one.
      * TLS 1.2 is forced before the download because Server 2016 and older negotiate TLS 1.0
        by default, and download.newrelic.com refuses it.

.PARAMETER LicenseKey
    New Relic ingest license key. Required.

.PARAMETER DisplayName
    Name the host reports under. Defaults to the machine's own hostname.

.PARAMETER Proxy
    Proxy URL, e.g. http://proxy.corp:8080. Omit unless the host needs one.

.PARAMETER Tags
    Extra labels attached to every sample, e.g. @{ env = 'test'; tier = 'web' }.
    These become facets you can filter dashboards and alerts by.

.EXAMPLE
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL'

.EXAMPLE
    .\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' -Tags @{ env = 'test' }

.EXAMPLE
    # Whole fleet at once (requires WinRM)
    $hosts = 'UE1-TEST-ADC-A2','UE1-TEST-ADC-B2','UE1-TEST-WEB-B1','UE1-TEST-SQL-A2','UE1-TEST-SQL-B2'
    Invoke-Command -ComputerName $hosts -FilePath .\Install-NewRelicInfraAgent.ps1 `
        -ArgumentList 'xxxxxxxxNRAL' -ErrorAction Continue
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]    $LicenseKey,

    [string]    $DisplayName = $env:COMPUTERNAME,

    [string]    $Proxy,

    [hashtable] $Tags = @{}
)

$ErrorActionPreference = 'Stop'

$msiUrl    = 'https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.msi'
$agentRoot = 'C:\Program Files\New Relic\newrelic-infra'
$config    = Join-Path $agentRoot 'newrelic-infra.yml'
$msiPath   = Join-Path $env:TEMP 'newrelic-infra.msi'
$msiLog    = Join-Path $env:TEMP 'newrelic-infra-install.log'

function Write-Step { param([string] $Message) Write-Host "  $Message" -ForegroundColor Cyan }
function Write-Ok   { param([string] $Message) Write-Host "  $Message" -ForegroundColor Green }
function Write-Warn { param([string] $Message) Write-Host "  $Message" -ForegroundColor Yellow }

Write-Host "`nNew Relic infrastructure agent -- $env:COMPUTERNAME`n" -ForegroundColor White

# ---------------------------------------------------------------- preflight

if ([Environment]::Is64BitOperatingSystem -eq $false) {
    throw 'This agent requires a 64-bit version of Windows.'
}

$existing = Get-Service -Name 'newrelic-infra' -ErrorAction SilentlyContinue
if ($existing) {
    $current = (Get-Item (Join-Path $agentRoot 'newrelic-infra.exe') -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
    Write-Warn "Agent already installed (version $current, service $($existing.Status)). Upgrading in place."
}

# ---------------------------------------------------------------- download

Write-Step 'Downloading the installer...'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$download = @{ Uri = $msiUrl; OutFile = $msiPath; UseBasicParsing = $true }
if ($Proxy) { $download.Proxy = $Proxy; $download.ProxyUseDefaultCredentials = $true }

$progressPreferenceBefore = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'   # a visible progress bar makes this ~10x slower
try   { Invoke-WebRequest @download }
finally { $ProgressPreference = $progressPreferenceBefore }

$sizeMb = [math]::Round((Get-Item $msiPath).Length / 1MB, 1)
if ($sizeMb -lt 1) { throw "The downloaded file is only $sizeMb MB -- it is not a valid MSI." }
Write-Ok "Downloaded $sizeMb MB."

# ---------------------------------------------------------------- install

Write-Step 'Installing...'
$msiArgs = @(
    '/qn', '/norestart',
    '/i', "`"$msiPath`"",
    "GENERATE_CONFIG=true",
    "LICENSE_KEY=$LicenseKey",
    "DISPLAY_NAME=$DisplayName",
    '/L*v', "`"$msiLog`""
)
if ($Proxy) { $msiArgs += "PROXY=$Proxy" }
if ($Tags.Count -gt 0) {
    # CUSTOM_ATTRIBUTES takes JSON and lets the installer write the config itself,
    # which beats hand-editing the generated YAML afterwards.
    $json = ($Tags | ConvertTo-Json -Compress)
    $msiArgs += "CUSTOM_ATTRIBUTES=$json"
    Write-Step "Attaching $($Tags.Count) custom attribute(s): $json"
}

$proc = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
# 3010 = success, reboot queued. Neither the agent nor this script needs the reboot.
if ($proc.ExitCode -notin 0, 3010) {
    throw "msiexec returned $($proc.ExitCode). Full log: $msiLog"
}
Write-Ok 'Installed.'

# ---------------------------------------------------------------- verify

if (-not (Test-Path $config)) {
    throw "Expected the installer to create $config, but it is missing. Full log: $msiLog"
}

Write-Step 'Verifying...'
$svc = Get-Service -Name 'newrelic-infra' -ErrorAction SilentlyContinue
if (-not $svc) { throw 'The newrelic-infra service does not exist after installation.' }
if ($svc.Status -ne 'Running') {
    Start-Service newrelic-infra
    Start-Sleep -Seconds 3
    $svc.Refresh()
}

$version = (Get-Item (Join-Path $agentRoot 'newrelic-infra.exe')).VersionInfo.ProductVersion
Remove-Item $msiPath -ErrorAction SilentlyContinue

Write-Host ''
Write-Ok  "Service : $($svc.Status)"
Write-Ok  "Version : $version"
Write-Ok  "Reports as: $DisplayName"
Write-Host @"

  Data reaches New Relic within about 2 minutes. Confirm with:

    SELECT latest(agentVersion) FROM SystemSample
    WHERE hostname = '$DisplayName' SINCE 10 minutes ago

  Then run Enable-NriWinservices.ps1 on this host to turn on Windows service monitoring.

"@ -ForegroundColor Gray
