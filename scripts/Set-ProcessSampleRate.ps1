#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sets the infrastructure agent's process-metric sample rate on a Windows host.

.DESCRIPTION
    ProcessSample is the heaviest event this account produces -- 859 GB/month across the
    fleet as of 2026-09-18, roughly 72% of total ingest. Each host reports about 240
    processes every 20 seconds by default, which is ~40 GB/month per host just for
    per-process detail.

    Raising the interval to 60s cuts that to a third. Across the ten Test hosts it saves
    on the order of 269 GB/month, about 22% of the account's total ingest.

    What it costs: resolution in the "Host Processes" dashboard. Which process is using
    CPU and memory is still visible; a spike shorter than a minute may not be. That
    changes no decision in Test. Evaluate before applying it to production hosts where
    someone does fine-grained performance work.

.PARAMETER Seconds
    Sample interval. The agent's minimum is 20 (the default); -1 disables ProcessSample
    entirely, which empties the Host Processes dashboard.

.EXAMPLE
    .\Set-ProcessSampleRate.ps1

.EXAMPLE
    # Whole Test fleet at once (requires WinRM)
    $hosts = 'UE1-TEST-ADC-A2','UE1-TEST-ADC-B2','UE1-TEST-API-A1','UE1-TEST-API-B1',
             'UE1-TEST-SMT-A1','UE1-TEST-SQL-A2','UE1-TEST-SQL-B2','UE1-TEST-SRV-A1',
             'UE1-TEST-WEB-A1','UE1-TEST-WEB-B1'
    Invoke-Command -ComputerName $hosts -FilePath .\Set-ProcessSampleRate.ps1 -ErrorAction Continue
#>
[CmdletBinding()]
param(
    [ValidateScript({ $_ -eq -1 -or $_ -ge 20 })]
    [int] $Seconds = 60
)

$ErrorActionPreference = 'Stop'
$cfg = 'C:\Program Files\New Relic\newrelic-infra\newrelic-infra.yml'

if (-not (Test-Path $cfg)) {
    throw "$cfg not found -- the infrastructure agent is not installed on $env:COMPUTERNAME."
}

Copy-Item $cfg "$cfg.bak" -Force

# Drop any existing value before appending. Two copies of the key parse to one silently,
# and which one wins is not obvious from reading the file.
$lines = @(Get-Content -LiteralPath $cfg |
           Where-Object { $_ -notmatch '^\s*metrics_process_sample_rate\s*:' })
$lines += "metrics_process_sample_rate: $Seconds"

# UTF-8 without BOM: the agent's YAML parser rejects a BOM and logs nothing useful.
[System.IO.File]::WriteAllLines($cfg, $lines, (New-Object System.Text.UTF8Encoding($false)))

Restart-Service newrelic-infra
Start-Sleep -Seconds 3

$svc = Get-Service newrelic-infra
Write-Host ""
Write-Host ("  {0}" -f $env:COMPUTERNAME) -ForegroundColor White
Write-Host ("    sample rate : {0}s" -f $Seconds) -ForegroundColor Green
Write-Host ("    service     : {0}" -f $svc.Status) -ForegroundColor Green
Write-Host ("    backup      : {0}.bak" -f $cfg) -ForegroundColor Gray
Write-Host @"

  Verify in about 15 minutes -- the result divided into 600 gives the interval:

    SELECT count(*) / uniqueCount(processId) FROM ProcessSample
    WHERE hostname LIKE 'UE1-TEST%' FACET hostname SINCE 10 minutes ago

"@ -ForegroundColor Gray
