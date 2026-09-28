# Reports

Point-in-time snapshots exported for the client. They are **not** kept in sync with
New Relic — each file records the state at the moment it was generated, so read the
date below before quoting any number from them.

| File | Language | Generated |
|---|---|---|
| `IPAYOUT - New Relic agent status (TEST).xlsx` | English | 2026-09-11 |
| `IPAYOUT - Estado agente New Relic (TEST).xlsx` | Spanish | 2026-09-11 |
| `2026-09-25 New Relic dashboards guide.pdf` | English | 2026-09-25 |
| `2026-09-25 Guia de dashboards New Relic.pdf` | Spanish | 2026-09-25 |
| `2026-09-28 New Relic agent status (all environments).xlsx` | English | 2026-09-28 |

## The agent status sheet

`2026-09-28 New Relic agent status (all environments).xlsx` lists every host across
AWS DR, AWS TEST, production (on-premise) and MIAT, with its infrastructure agent
version, whether it is still reporting, and which integrations reach it
(nri-winservices, APM, nri-mssql). Rows are coloured: green reporting and up to date,
amber agent below 1.80, red not reporting or no agent, grey managed AWS service.

Environment, OS and Role come from the client's own host inventory; everything else
comes from New Relic. Where the two disagree on a name, the inventory name is in the
Host column and the New Relic name in "Reported as" -- `UE1-TEST-SMTP-A1` reports
truncated as `UE1-TEST-SMT-A1`, and `UE1-TEST-REDIS-A1` reports as its EC2 private DNS
name `ip-10-24-132-223`.

What it surfaced on 2026-09-28:

- **Five UE2 hosts stopped reporting within the same minute**, 2026-09-17 16:34 UTC:
  `UE2-ADC-A02`, `UE2-ADC-B02`, `UE2-SQL-A02`, `UE2-SQL-B02` and `UE2-SQL-A01`. One
  change - network, firewall or the environment shut down - not five failures. It takes
  out both DR domain controllers and both DR databases.
- **`UE2-SMTP-A01` and `UE2-REDIS-A02` have never had an agent.** The Redis host is
  Ubuntu, so it needs the Linux agent, not `Install-NewRelicInfraAgent.ps1`.
- **`AWS RDS` and the load balancer are invisible.** They cannot take an agent and the
  AWS integration is not configured in the account - no `AwsRdsDbInstanceSample`, no
  `aws.*` metrics at all.
- **No DR host runs an agent below 1.80.** The old agents are all in production
  on-premise: six BCA hosts on 1.11.45, `BCA-VM-SRV-001` on 1.62.0, and the two MIAT
  hosts on 1.20.7 and 1.62.0.
- `UE2-SQL-A01` reports but is in neither inventory; `MIAT-VM-SMT-001` has not reported
  since 2026-08-12.

## The dashboard guide

The dashboard guide is a different kind of document from the snapshots below: it explains
what each of the 11 dashboards we built shows, what it is for, which data source feeds it
and what it does not cover yet. It exists in two languages with identical content; in the
Spanish one, dashboard, page and widget names stay in English because that is how they
live in New Relic.

Both are written as HTML and rendered with headless Chrome, sharing the same stylesheet.
Each `.pdf` has its `.html` source next to it — edit the source, then regenerate:

```sh
for f in "2026-09-25 New Relic dashboards guide" "2026-09-25 Guia de dashboards New Relic"; do
  google-chrome --headless --no-pdf-header-footer \
    --print-to-pdf="$f.pdf" "$f.html"
done
```

Edits that change wording have to be made in both files; there is no shared source.
The coverage figures (Appendix B) are point-in-time like everything else here.

## What the TEST snapshots cover

The 11 AWS TEST hosts across all three layers of instrumentation: infrastructure agent,
the Windows Services integration, and the .NET agent (APM).

As of 2026-09-11, 6 of the 11 report infrastructure data and all 6 have Windows Services
enabled. APM reaches 3 of them. Five hosts have no agent at all: both domain controllers,
both SQL 2025 hosts, and the Ubuntu Redis host, which needs the Linux agent and can use
neither the Windows Services integration nor the .NET agent.

Three things the snapshot surfaces, in the order they are worth acting on:

- **`UE1-TEST-WEB-B1` reports its application as `My Application`.** That is the
  placeholder shipped in `newrelic.config`, and it wins over IIS auto-naming, so every
  application on the host collapses into one generic entity — and it will collide with
  the next host installed the same way. Removing the `<name>` element makes each app
  report under its app pool name. The API hosts are already correct: they report 7 and 8
  applications under real names.
- **`UE1-TEST-SRV-A1` has 8 IPS services stopped** and no .NET agent. Those services do
  not run under IIS, so instrumenting them needs the CORECLR environment variables on
  top of the MSI.
- **`UE1-TEST-SMTP-A1` reports as `UE1-TEST-SMT-A1`.** Dashboards and alert conditions
  match on the New Relic name, so the mismatch is load-bearing. Most likely the
  15-character NetBIOS limit truncating a 16-character name.

## Refreshing them

The numbers come from these queries:

```sql
SELECT latest(agentVersion) FROM SystemSample
WHERE hostname LIKE 'UE1-TEST%' FACET hostname SINCE 1 hour ago LIMIT MAX

SELECT uniqueCount(service_name) FROM Metric
WHERE metricName = 'windows_service_state' AND hostname LIKE 'UE1-TEST%'
FACET hostname SINCE 1 hour ago LIMIT MAX

SELECT uniqueCount(appName), count(*) FROM Transaction
WHERE host LIKE 'UE1-TEST%' FACET host SINCE 1 hour ago LIMIT MAX
```

The agent status sheet is built from one query plus three membership checks. The 90-day
window matters: it catches hosts that have stopped reporting, which a 1-day window hides.

```sql
SELECT latest(timestamp), latest(agentVersion), latest(operatingSystem),
       latest(linuxDistribution), latest(awsRegion)
FROM SystemSample FACET hostname SINCE 90 days ago LIMIT MAX

SELECT uniques(hostname, 500) FROM Metric
WHERE metricName = 'windows_service_state' SINCE 1 day ago
SELECT uniques(host, 500) FROM Transaction SINCE 1 day ago
SELECT uniques(hostname) FROM MssqlInstanceSample SINCE 1 day ago
```
