# Reports

Point-in-time snapshots exported for the client. They are **not** kept in sync with
New Relic — each file records the state at the moment it was generated, so read the
date below before quoting any number from them.

| File | Language | Generated |
|---|---|---|
| `IPAYOUT - New Relic agent status (TEST).xlsx` | English | 2026-09-11 |
| `IPAYOUT - Estado agente New Relic (TEST).xlsx` | Spanish | 2026-09-11 |

## What they cover

The 11 AWS TEST hosts, with agent version and whether the Windows Services
integration (nri-winservices) is reporting. As of 2026-09-11, 5 of the 11 report to
New Relic — all on agent 1.80.0 with winservices enabled — and 6 have no agent at
all: UE1-TEST-ADC-A2, UE1-TEST-ADC-B2, UE1-TEST-WEB-B1, UE1-TEST-SQL-A2,
UE1-TEST-SQL-B2 and UE1-TEST-REDIS-A1 (the last is Ubuntu, so winservices does not
apply to it and it needs the Linux agent instead).

Two things the snapshot surfaced:

- `UE1-TEST-SMTP-A1` reports as **`UE1-TEST-SMT-A1`**. The name in New Relic is what
  dashboards and alert conditions match on, so the mismatch matters. Most likely the
  15-character NetBIOS limit truncating a 16-character name.
- `UE1-TEST-SRV-A1` has 8 IPS services stopped, including `ips_bai2reportsservice`
  (also stopped in production) and `ips_deletefilemanagerservice`, a name absent from
  the hardcoded `local.windows_test_services` list — which is why the Critical
  services section matches on the `ips%` pattern instead.

## Refreshing them

The numbers come from these two queries:

```sql
SELECT latest(agentVersion), latest(windowsPlatform), latest(instanceType)
FROM SystemSample WHERE hostname LIKE 'UE1-TEST%' FACET hostname SINCE 1 hour ago LIMIT MAX

SELECT uniqueCount(service_name) FROM Metric
WHERE metricName = 'windows_service_state' AND hostname LIKE 'UE1-TEST%'
FACET hostname SINCE 1 hour ago LIMIT MAX
```
