#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables the nri-winservices integration on a Windows host.

.DESCRIPTION
    nri-winservices ships bundled with the Windows infrastructure agent, so there is
    nothing to install: this script writes the configuration file and restarts the agent.
    It is idempotent -- re-running it on an already configured host backs up the previous
    config and replaces it.

    Defaults report EVERY Windows service every 400 seconds. That combination is a
    deliberate cost trade-off: a long scrape interval is far cheaper per host than a
    short one, which buys the headroom to drop the service filter entirely. A curated
    service list has already drifted out of sync with the real service names once, so
    collecting everything and filtering in the dashboard is the more durable option.

    Gotchas handled here:
      * include_matching_entities is mandatory. Without it the integration starts
        cleanly and reports nothing.
      * scrape_interval is the correct key. "interval" is silently ignored for this
        long-running integration.
      * The YAML must be UTF-8 WITHOUT BOM. Out-File and Set-Content add one, and the
        agent's parser then rejects the file without logging a useful error.
      * The exporter binds 127.0.0.1:9182, which collides with a standalone
        windows_exporter. The agent is stopped before the port is checked, so an
        already-configured host does not report its own exporter as a collision.

.PARAMETER ScrapeIntervalSeconds
    How often the exporter is scraped. Ingest cost scales inversely with this value.

.PARAMETER ServiceNameRegex
    Which services to report. ".*" means every service on the host.

.EXAMPLE
    .\Enable-NriWinservices.ps1

.EXAMPLE
    # Only the IPS services, sampled frequently
    .\Enable-NriWinservices.ps1 -ScrapeIntervalSeconds 30 -ServiceNameRegex '^ips.*'

.EXAMPLE
    # Roll out across the fleet (requires WinRM)
    Invoke-Command -ComputerName $hosts -FilePath .\Enable-NriWinservices.ps1 -ErrorAction Continue
#>
[CmdletBinding()]
param(
    [ValidateRange(15, 3600)]
    [int]    $ScrapeIntervalSeconds = 400,

    [string] $ServiceNameRegex      = '.*',

    [int]    $ExporterPort          = 9182
)

$ErrorActionPreference = 'Stop'

$agentRoot  = 'C:\Program Files\New Relic\newrelic-infra'
$agentExe   = Join-Path $agentRoot 'newrelic-infra.exe'
$configDir  = Join-Path $agentRoot 'integrations.d'
$configPath = Join-Path $configDir 'winservices-config.yml'
$minVersion = [version]'1.12.1'

function Write-Step { param($Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok   { param($Message) Write-Host "    OK: $Message"      -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "    WARNING: $Message" -ForegroundColor Yellow }

Write-Step "Host: $env:COMPUTERNAME"

# --- 1. The infrastructure agent must be installed -------------------------------
Write-Step 'Checking the infrastructure agent'

if (-not (Get-Service -Name 'newrelic-infra' -ErrorAction SilentlyContinue)) {
    throw "The 'newrelic-infra' service is not installed on $env:COMPUTERNAME. Install the infrastructure agent first."
}
if (-not (Test-Path $agentExe)) {
    throw "Agent binary not found at $agentExe."
}

$versionOutput = & $agentExe -version 2>&1 | Out-String
if ($versionOutput -match '(\d+\.\d+\.\d+)') {
    $agentVersion = [version]$Matches[1]
    if ($agentVersion -lt $minVersion) {
        throw "Agent version $agentVersion is older than the required $minVersion. Upgrade the agent first."
    }
    Write-Ok "Agent version $agentVersion (>= $minVersion)"
} else {
    Write-Warn "Could not parse the agent version from: $($versionOutput.Trim()). Continuing anyway."
}

# --- 2. Stop the agent before touching the port or the config --------------------
# Stopping first releases port 9182 if this host already runs the integration, so the
# collision check below only fires on a genuinely foreign listener.
Write-Step 'Stopping the newrelic-infra service'
Stop-Service -Name 'newrelic-infra' -Force
(Get-Service -Name 'newrelic-infra').WaitForStatus('Stopped', '00:01:00')
Write-Ok 'Service stopped'

$listener = Get-NetTCPConnection -LocalPort $ExporterPort -State Listen -ErrorAction SilentlyContinue |
            Select-Object -First 1
if ($listener) {
    $owner     = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    $ownerName = if ($owner) { "$($owner.ProcessName) (PID $($owner.Id))" } else { "PID $($listener.OwningProcess)" }
    throw "Port $ExporterPort is still in use by $ownerName after stopping the agent (likely a standalone windows_exporter). Stop it, or re-run with -ExporterPort <other port>."
}
Write-Ok "Port $ExporterPort is free"

# --- 3. Write the configuration --------------------------------------------------
if (-not (Test-Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    Write-Ok "Created $configDir"
}

if (Test-Path $configPath) {
    $backupPath = "$configPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $configPath -Destination $backupPath -Force
    Write-Ok "Backed up the previous config to $backupPath"
}

Write-Step "Writing $configPath"

# Built as an array of literal lines rather than a here-string: the YAML indentation is
# semantic, and this form survives being pasted into a console that auto-indents.
$yaml = @(
    'integrations:'
    '  - name: nri-winservices'
    '    config:'
    '      exporter_bind_address: 127.0.0.1'
    "      exporter_bind_port: $ExporterPort"
    "      scrape_interval: ${ScrapeIntervalSeconds}s"
    '      include_matching_entities:'
    '        windowsService.name:'
    "          - regex `"$ServiceNameRegex`""
) -join "`r`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($configPath, $yaml + "`r`n", $utf8NoBom)

# Prove there is no BOM rather than trusting the encoding argument.
$firstBytes = [System.IO.File]::ReadAllBytes($configPath) | Select-Object -First 3
if ($firstBytes.Count -ge 3 -and $firstBytes[0] -eq 0xEF -and $firstBytes[1] -eq 0xBB -and $firstBytes[2] -eq 0xBF) {
    throw 'The config file was written with a BOM. The agent will not parse it.'
}
Write-Ok 'Config written as UTF-8 without BOM'
Write-Host ''
Write-Host $yaml -ForegroundColor DarkGray
Write-Host ''

# --- 4. Start the agent back up --------------------------------------------------
Write-Step 'Starting the newrelic-infra service'
Start-Service -Name 'newrelic-infra'
(Get-Service -Name 'newrelic-infra').WaitForStatus('Running', '00:01:00')
Write-Ok 'Service is running'

# --- 5. Verify the exporter came up ----------------------------------------------
Write-Step "Waiting for the exporter to bind 127.0.0.1:$ExporterPort"

$deadline = (Get-Date).AddSeconds(90)
$bound    = $false
while ((Get-Date) -lt $deadline) {
    if (Get-NetTCPConnection -LocalPort $ExporterPort -State Listen -ErrorAction SilentlyContinue) {
        $bound = $true
        break
    }
    Start-Sleep -Seconds 5
}

if ($bound) {
    Write-Ok "Exporter is listening on 127.0.0.1:$ExporterPort"
    try {
        $metrics      = Invoke-WebRequest -Uri "http://127.0.0.1:$ExporterPort/metrics" -UseBasicParsing -TimeoutSec 15
        $serviceCount = ([regex]::Matches($metrics.Content, '(?m)^windows_service_state\{')).Count
        if ($serviceCount -eq 0) {
            Write-Warn 'The exporter returned no windows_service_state series. Check include_matching_entities.'
        } else {
            Write-Ok "The exporter is returning $serviceCount windows_service_state series"
        }
    } catch {
        Write-Warn "Could not scrape the exporter: $($_.Exception.Message)"
    }
} else {
    Write-Warn "The exporter did not bind port $ExporterPort within 90s. Check the agent log."
}

# --- 6. Surface any integration errors from the log ------------------------------
$logPath = Join-Path $agentRoot 'newrelic-infra.log'
if (Test-Path $logPath) {
    $issues = Get-Content -Path $logPath -Tail 200 |
              Where-Object { $_ -match 'winservices' -and $_ -match 'error|fatal|warn' }
    if ($issues) {
        Write-Step 'Recent winservices messages in the agent log'
        $issues | Select-Object -Last 15 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    }
}

Write-Host ''
Write-Step 'Done'
Write-Host @"
    Data takes up to $ScrapeIntervalSeconds seconds to reach New Relic, plus ingest lag.
    Verify with:

      FROM Metric SELECT uniqueCount(service_name)
      WHERE metricName = 'windows_service_state' AND hostname = '$env:COMPUTERNAME'
      SINCE 30 minutes ago
"@ -ForegroundColor Gray
