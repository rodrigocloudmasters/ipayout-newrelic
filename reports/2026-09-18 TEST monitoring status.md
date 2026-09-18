# New Relic — TEST environment monitoring status

**18 September 2026**

The infrastructure agent is now on 10 of the 11 TEST hosts, including the four that
were blocked behind the proxy. Three things still need attention.

---

## 1. Disk space is critical on three hosts

| Host | Volume | Used | Free |
|---|---|---|---|
| UE1-TEST-SQL-A2 | E: | **94.6%** | **3.5 GB** |
| UE1-TEST-SQL-B2 | E: | **94.6%** | **3.5 GB** |
| UE1-TEST-ADC-A2 | C: | **85.1%** | **4.7 GB** |

Both SQL hosts show the identical figure on E:, so this looks like how the volume was
sized rather than a runaway file. If E: holds transaction logs or tempdb, SQL Server
stops accepting writes when it fills, and 3.5 GB is hours of headroom, not days.

The C: drive on the domain controller is tight for the same reason — 4.7 GB leaves no
room for a Windows update or a log burst.

**Please confirm what E: is used for on the SQL hosts and whether it can be extended.**

## 2. The Windows Services integration is missing on all four new hosts

`UE1-TEST-ADC-A2`, `UE1-TEST-ADC-B2`, `UE1-TEST-SQL-A2` and `UE1-TEST-SQL-B2` send
host metrics (CPU, memory, disk) but no Windows service data.

Until it is enabled, we cannot see whether a service is running on those hosts, and we
cannot alert when one stops. This matters most on the domain controllers: if Active
Directory or DNS stops, nothing in New Relic will report it today.

This one is quick. The integration is bundled with the agent already installed, so
nothing needs downloading — the proxy is not involved. It is a config file plus an
agent restart, about five minutes per host.

## 3. SQL Server database monitoring is not installed

The two SQL hosts run **SQL Server 2025** (engine version 17). Without the `nri-mssql`
integration we have no database metrics at all: no connections, deadlocks, buffer pool,
wait statistics or per-database I/O.

There has been a concern that SQL Server 2025 is not supported. That is worth revisiting:

- The integration requires SQL Server 2016 or later, so 2025 is well above the minimum.
- A hardcoded upper-bound check that rejected engine 17.x **was removed in version
  2.31.0** (June 2026). An attempt with an older build would have hit exactly that.
- The current release is 2.38.0 (September 2026).

New Relic does not yet state SQL Server 2025 support explicitly, so we should treat this
as likely to work rather than certain, and validate it on one host before rolling out.
The core metrics come from DMVs that are stable across versions; if anything fails it
will be Query Performance Monitoring, which can be switched off while keeping everything
else.

Installing it also needs a dedicated read-only `newrelic` login on each instance.

---

## Where we stand

| Host | Infra agent | Windows services | APM | Database |
|---|---|---|---|---|
| UE1-TEST-ADC-A2 | Yes | **No** | n/a | n/a |
| UE1-TEST-ADC-B2 | Yes | **No** | n/a | n/a |
| UE1-TEST-API-A1 | Yes | Yes | Yes | n/a |
| UE1-TEST-API-B1 | Yes | Yes | Yes | n/a |
| UE1-TEST-SMTP-A1 | Yes | Yes | No | n/a |
| UE1-TEST-SQL-A2 | Yes | **No** | n/a | **No** |
| UE1-TEST-SQL-B2 | Yes | **No** | n/a | **No** |
| UE1-TEST-SRV-A1 | Yes | Yes | **No** | n/a |
| UE1-TEST-WEB-A1 | Yes | Yes | Yes | n/a |
| UE1-TEST-WEB-B1 | Yes | Yes | Yes | n/a |
| UE1-TEST-REDIS-A1 | **No** | n/a | n/a | n/a |

`UE1-TEST-REDIS-A1` runs Ubuntu and needs the Linux agent, which is a separate installer.

Two smaller items for the record: `UE1-TEST-SMTP-A1` reports to New Relic as
`UE1-TEST-SMT-A1` — most likely the 15-character NetBIOS limit truncating the name, and
worth knowing because dashboards and alerts match on the New Relic name. And
`UE1-TEST-SRV-A1` currently has 8 IPS services stopped, which may be expected in TEST but
is worth a look.

## Suggested order

1. Disk space on the two SQL hosts and the domain controller — the only item with a clock on it
2. Windows Services on the four new hosts — quick, and it covers the AD blind spot
3. `nri-mssql` on the SQL hosts — validate on one first
