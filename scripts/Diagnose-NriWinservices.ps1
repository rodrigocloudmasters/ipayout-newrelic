<#
.SYNOPSIS
    Diagnoses why the Windows services integration (nri-winservices) is not reporting.

.DESCRIPTION
    Read-only: changes nothing on the host. Run as Administrator and send the full
    output back. Checks, in order: agent service and version, config file presence,
    encoding (BOM) and structure, integration/exporter process, exporter port and
    HTTP response, and the agent log entries that mention winservices.

.EXAMPLE
    .\Diagnose-NriWinservices.ps1
#>

$ErrorActionPreference = 'Continue'
$agentDir   = 'C:\Program Files\New Relic\newrelic-infra'
$configPath = Join-Path $agentDir 'integrations.d\winservices-config.yml'

Write-Host "`n===== nri-winservices DIAGNOSTIC | $env:COMPUTERNAME | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =====`n"

Write-Host "=== 1. Agent service and version ==="
Get-Service newrelic-infra -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
$exe = Join-Path $agentDir 'newrelic-infra.exe'
if (Test-Path $exe) { Write-Host "Agent version: $((Get-Item $exe).VersionInfo.ProductVersion)" }
else { Write-Host "PROBLEM: agent binary not found at $exe" }

Write-Host "`n=== 2. Config file ==="
if (Test-Path $configPath) {
    Write-Host "FOUND: $configPath"

    $bytes = [System.IO.File]::ReadAllBytes($configPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "PROBLEM: the file has a UTF-8 BOM. The agent rejects it silently."
        Write-Host "  Fix: rewrite it with [System.IO.File]::WriteAllText(path, yaml, UTF8Encoding(`$false))"
    } else {
        Write-Host "OK: no BOM"
    }

    $raw = Get-Content $configPath -Raw
    if ($raw -match '(?m)^\s{5,}timeout:') {
        Write-Host "PROBLEM: 'timeout:' is nested inside the config: block."
        Write-Host "  It belongs at the integration level (same indent as 'name:' and 'labels:')."
    }
    if ($raw -notmatch 'include_matching_entities') {
        Write-Host "PROBLEM: no include_matching_entities filter. Without it the integration reports nothing."
    }
    if ($raw -match '(?m)^\s+interval:') {
        Write-Host "PROBLEM: 'interval:' is ignored by this long-running integration. Use 'scrape_interval:'."
    }

    Write-Host "--- file content ---"
    Get-Content $configPath
    Write-Host "--------------------"
} else {
    Write-Host "PROBLEM: config file NOT FOUND at $configPath"
    Write-Host "  The integration was never configured on this host. Run Enable-NriWinservices.ps1."
}

Write-Host "`n=== 3. Integration / exporter processes ==="
$procs = Get-Process -Name 'nri-winservices', 'windows_exporter' -ErrorAction SilentlyContinue
if ($procs) { $procs | Format-Table Name, Id, StartTime -AutoSize }
else { Write-Host "PROBLEM: no nri-winservices or windows_exporter process is running." }

Write-Host "=== 4. Exporter port 9182 ==="
$conns = Get-NetTCPConnection -LocalPort 9182 -ErrorAction SilentlyContinue | Select-Object -Unique OwningProcess
if ($conns) {
    foreach ($c in $conns) {
        $owner = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        Write-Host "Port 9182 is bound by PID $($c.OwningProcess) ($($owner.ProcessName))"
        if ($owner -and $owner.ProcessName -notmatch 'windows_exporter|nri-winservices') {
            Write-Host "PROBLEM: the port is held by an unrelated process. Change exporter_bind_port to 9183 in the yml and restart the agent."
        }
    }
} else {
    Write-Host "Port 9182 is not bound. If the config exists, the exporter failed to start (see the log below)."
}

Write-Host "`n=== 5. Exporter HTTP response ==="
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:9182/metrics' -UseBasicParsing -TimeoutSec 5
    Write-Host "OK: exporter answered ($([math]::Round($r.RawContentLength/1kb)) KB of metrics)"
} catch {
    Write-Host "No answer from http://127.0.0.1:9182/metrics -> $($_.Exception.Message)"
}

Write-Host "`n=== 6. Agent log, winservices mentions ==="
$logCandidates = @(
    (Join-Path $agentDir 'newrelic-infra.log'),
    'C:\ProgramData\New Relic\newrelic-infra\newrelic-infra.log'
)
$log = $logCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($log) {
    Write-Host "Log: $log (last matches)"
    Get-Content $log -Tail 500 | Select-String -Pattern 'winservice' | Select-Object -Last 25
    if (-not (Get-Content $log -Tail 500 | Select-String -Pattern 'winservice' -Quiet)) {
        Write-Host "No winservices mentions in the last 500 lines - the agent is not even trying to load the integration (config missing, unreadable, or agent not restarted since it was written)."
    }
} else {
    Write-Host "PROBLEM: agent log not found in either standard location."
}

Write-Host "`n===== DONE - copy ALL of the output above and send it back ====="
