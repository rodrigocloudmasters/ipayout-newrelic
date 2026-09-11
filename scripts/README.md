# Scripts

Host-side tooling. These are not managed by Terraform: they configure the New Relic
agent *on* the Windows hosts, which is the prerequisite for the dashboards to have any
data to show.

## `Install-NewRelicInfraAgent.ps1`

Installs or upgrades the infrastructure agent -- the prerequisite for everything else,
including `Enable-NriWinservices.ps1`, whose integration ships inside this agent.

```powershell
.\Install-NewRelicInfraAgent.ps1 -LicenseKey 'xxxxxxxxNRAL' -Tags @{ env = 'test' }
```

The key is the **ingest license key**, not the `NRAK-` user key Terraform uses. Fetch it
from a shell with `.env` loaded:

```sh
curl -s -X POST https://api.newrelic.com/graphql -H "Api-Key: $NEW_RELIC_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ actor { account(id: 1468011) { licenseKey } } }"}'
```

Running it on a host that already has the agent is an in-place upgrade: the config file
and everything under `integrations.d` survive, so it will not undo a winservices setup.

`-Tags` are passed through the MSI's `CUSTOM_ATTRIBUTES` property rather than written into
the YAML afterwards, so the installer owns the config file end to end. They become facets
you can filter dashboards and alerts by -- `env` is the one worth setting from the start,
since the Test and production dashboards are separated by host-name pattern today, which
is more brittle than a tag.

As of 2026-09-11 six TEST hosts still need this: UE1-TEST-ADC-A2, UE1-TEST-ADC-B2,
UE1-TEST-WEB-B1, UE1-TEST-SQL-A2, UE1-TEST-SQL-B2 and UE1-TEST-REDIS-A1 -- the last runs
Ubuntu, so it needs the Linux agent instead and cannot use this script.

## `Enable-NriWinservices.ps1`

Enables the Windows Services integration (`nri-winservices`) on a Windows host.

The integration is bundled with the Windows infrastructure agent, so there is nothing to
install -- unlike `nri-mssql`. Enabling it means writing
`C:\Program Files\New Relic\newrelic-infra\integrations.d\winservices-config.yml` and
restarting the agent, which is all this script does. It is idempotent: re-running it
backs up the previous config and replaces it.

Run it **as Administrator**:

```powershell
.\Enable-NriWinservices.ps1
```

Defaults report **every** service every **400 seconds**. See "Why every service" below.

To report only the IPS services, sampled frequently:

```powershell
.\Enable-NriWinservices.ps1 -ScrapeIntervalSeconds 30 -ServiceNameRegex '^ips.*'
```

### Fleet rollout

Requires WinRM. `-ErrorAction Continue` keeps the remaining hosts going when one fails.

```powershell
$hosts = @(
    'BCA-VM-API-001','BCA-VM-API-002','BCA-VM-API-003'
    'BCA-VM-WEB-001','BCA-VM-WEB-002','BCA-VM-WEB-003'
    'BCA-VM-SQL-001','BCA-VM-SRV-001'
    'UE2-ADC-A02','UE2-ADC-B02'
    'UE2-API-A01','UE2-API-A02','UE2-API-B01'
    'UE2-SQL-A01','UE2-SQL-A02','UE2-SQL-B02'
    'UE2-SRV-A01'
    'UE2-WEB-A01','UE2-WEB-A02','UE2-WEB-B01'
    'UE1-TEST-API-A1','UE1-TEST-API-B1','UE1-TEST-SMT-A1'
    'UE1-TEST-SRV-A1','UE1-TEST-WEB-A1'
    'MIAT-VM-SRV-001','MIAT-VM-SQL-001'
)

Invoke-Command -ComputerName $hosts -FilePath .\Enable-NriWinservices.ps1 -ErrorAction Continue
```

Test one host first (`UE1-TEST-SRV-A1` is a good candidate) and confirm it reports before
touching production.

`BCA-VM-SRV-001` is the only host that already has the integration. Running the script
there switches it from a 30s scrape with an `ip.*` filter to the defaults below, so its
widgets go from ~15 services to ~250.

### Why every service, and why 400 seconds

Ingest scales as `services x hosts / scrape_interval`. Reporting every service at the
default 30s across 27 hosts would add roughly 240 GB/month to an account that already
ingests ~540 GB/month. At 400s the same coverage costs on the order of 20 GB/month --
noise by comparison.

The long interval is what makes full coverage affordable, and full coverage is worth
having: the hardcoded IPS service list in the dashboards was taken from an alert
condition and has already drifted from the real service names (`ipsripplepaymentsservice`
vs `ripplepaymentsservice`, plus `ips_emailreceiverwindowsservice` and
`ips_bai2reportsservice`, which are absent from it), so the "services not running"
billboards undercount. Collecting everything and filtering in NRQL removes that whole
class of bug.

The trade-off is detection latency: a service that stops is noticed up to ~7 minutes
later. For services nobody restarts automatically that changes no decision. If a tier
ever needs faster detection, add a second integration block with a tighter
`scrape_interval` and a narrow regex -- the agent supports several instances.

### Verifying

```sql
FROM Metric SELECT uniqueCount(service_name)
WHERE metricName = 'windows_service_state'
FACET hostname SINCE 30 minutes ago
```

To measure what it actually costs before rolling out wider:

```sql
SELECT rate(bytecountestimate(), 1 day) / 1e9 AS 'GB/day', uniqueCount(service_name) AS 'Services'
FROM Metric WHERE metricName = 'windows_service_state'
FACET hostname SINCE 1 day ago
```

If ingest does run away, it can be cut from one place without touching any host: add a
drop filter on `metricName = 'windows_service_state'` under Manage data -> Drop filters.

### Known gotchas

These are all silent failures, which is why the script checks for them:

- `include_matching_entities` is **mandatory**. Without it the integration starts
  cleanly and reports nothing.
- The key is `scrape_interval`, not `interval`, which is ignored for this long-running
  integration.
- The YAML must be UTF-8 **without BOM**. `Out-File` and `Set-Content` add one and the
  agent's parser then rejects the file without a useful log line. The script uses
  `[System.IO.File]::WriteAllText` and verifies the first bytes afterwards.
- The exporter binds `127.0.0.1:9182` and collides with a standalone `windows_exporter`.
  The script stops the agent before checking the port, so a host that already runs the
  integration is not misreported as a collision.
- Requires agent >= 1.12.1. All 27 hosts qualify, though `MIAT-VM-SQL-001` (1.20.7) and
  `MIAT-VM-SRV-001` (1.62.0) are worth upgrading.
- Proxy settings are irrelevant: the agent scrapes the exporter over loopback and Go
  never proxies localhost.
