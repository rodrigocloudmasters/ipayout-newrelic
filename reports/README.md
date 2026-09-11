# Reports

Point-in-time snapshots exported for the client. They are **not** kept in sync with
New Relic — each file records the state at the moment it was generated, so read the
date below before quoting any number from them.

| File | Language | Generated |
|---|---|---|
| `IPAYOUT - New Relic agent status (TEST).xlsx` | English | 2026-09-11 |
| `IPAYOUT - Estado agente New Relic (TEST).xlsx` | Spanish | 2026-09-11 |

## What they cover

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
