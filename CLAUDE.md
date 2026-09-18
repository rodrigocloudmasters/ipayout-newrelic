# CLAUDE.md

Project context and conventions. This file mirrors the working memory of the project; keep it updated when anything below changes.

## Language convention

Conversation with the user is in Spanish (Argentine), but everything that lives in code or in New Relic must be in English: Terraform files and comments, dashboard names, page names, widget titles, NRQL aliases, alert policy/condition names, notification channels, this file, commit messages, README.

## Project

Terraform project managing New Relic for International Payout Systems Inc (account ID `1468011`, US region). Credentials live in a gitignored `.env` (User API key `NRAK-...`) read by the provider via `NEW_RELIC_API_KEY` / `NEW_RELIC_ACCOUNT_ID` / `NEW_RELIC_REGION` env vars — no credentials in `.tf` files. `terraform.tfstate` is committed to the repo (decision of 2026-09-11 — no remote backend available yet; the state was verified to contain no credentials, and the provider never writes the API key into it). Because the state travels in git: `git pull` before any plan/apply, commit and push `terraform.tfstate` right after every apply, and never run apply from two machines at once — git provides no state locking. Re-check the state for secrets before pushing whenever a new resource type is added (e.g. notification destinations can hold webhook URLs).

All changes go through code: edit `.tf`, `terraform plan`, `terraform apply` (`set -a; source .env; set +a` first). UI edits to managed resources are drift and get reverted on the next apply.

**Commit and push after every change, without being asked.** Rodrigo works from more than one laptop, so anything left uncommitted is invisible from the other one — and an uncommitted `terraform.tfstate` is worse than invisible: the other machine plans against a stale state and re-creates resources that already exist. That is exactly how a duplicate "Test Environment - Health Overview" dashboard appeared on 2026-09-16 and had to be deleted by hand. The loop is: `git pull` → change → `terraform apply` → `git add` (including `terraform.tfstate`) → `git commit` → `git push`, finished in the same turn the change was made. Do not hand these commands back to the user to run.

Pushing needs an explicit SSH identity. This machine holds keys for two GitHub accounts and has no `~/.ssh/config`, so git defaults to `id_ed25519`, which authenticates as `rembeita` — read access only on this repo. Fetch works and push fails with a confusing "Permission denied" that looks like a repo problem. Prefix git commands that reach the remote:

```sh
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes' git push origin main
```

`id_ed25519_github` authenticates as `rodrigocloudmasters`, who owns the repo. A `~/.ssh/config` entry for github.com would make the prefix unnecessary, but it would also pin every github.com repo on the machine to that identity, so it has been left to the user to decide.

## Current state

- The 10 pre-existing dashboards were imported into state (`dashboards.tf`, generated with `terraform plan -generate-config-out`).
- `dashboard_hosts.tf`: "Infrastructure - Hosts (CPU, Memory, Disk)" — Windows hosts monitored via the Infrastructure agent. **27 hosts report SystemSample as of 2026-09-10** (was 17 when first documented): 20 production (BCA-VM-*, UE2-*) and 7 in the Test dashboard's scope (UE1-TEST-*, MIAT-VM-*). The dashboard is unscoped, so new hosts appear automatically.
- `synthetics.tf`: 135 SIMPLE ping monitors ("Web - <domain>", every 10 min, US_EAST_1 + US_WEST_1, SSL verification) covering every domain with ≥ 20 pageviews/7d that responds. 134 hit the platform-wide healthcheck endpoint `/public/healthcheck.ashx`; `supernova.i-payout.com` lacks it and uses its homepage. SIMPLE ping monitors are not billable as synthetic checks; their ingest is ~1 GB/month vs ~540 GB/month the account already ingests.
- `dashboard_synthetics.tf`: "Web Availability (Synthetics)".
- `dashboard_mssql.tf`: "SQL Server" — the nri-mssql integration reports only from UE2-SQL-A01 and MIAT-VM-SQL-001. Three SQL hosts still need it installed to appear: UE2-SQL-A02, UE2-SQL-B02 and BCA-VM-SQL-001 (all three send SystemSample, none has ever sent MssqlInstanceSample). In `MssqlDatabaseSample` the database name attribute is `displayName`.
- `dashboard_apm.tf`: "APM - Application Health" — ~20 .NET apps; IPS New does ~1M transactions/day.
- `dashboard_errors.tf`: "Errors & Exceptions" — CommissionNetworks.com had a ~58% error rate when first checked (2026-08-31).
- `dashboard_processes.tf`: "Host Processes" (ProcessSample, host variable).
- `dashboard_windows_test.tf`: "Windows Services - Test Environment" — mirror of the production Windows Services dashboard scoped to UE1-TEST-* / MIAT-VM-* hosts. Has a "Critical services" section driven by `local.windows_test_critical`, which matches by pattern (`service_name LIKE 'ips%'` etc.) instead of the hardcoded list, so a newly deployed IPS service is covered the day it ships. Its windows are tuned for the 400s scrape: variables use `SINCE 1 day ago` (3+ day windows on Metric read rollups that lag hours behind, so a freshly onboarded host returns nothing and every widget filtering on `IN ('*')` renders 0) and the state-transition widgets use 15 minutes (5 is shorter than the sampling interval and would almost always be empty).
- `scripts/Enable-NriWinservices.ps1`: enables nri-winservices on a Windows host — writes the config and restarts the agent, idempotently. Defaults to every service every 400s. `scripts/README.md` has the fleet rollout, the cost rationale and the verification queries.

## Known issues / findings

- **The Windows Services integration (nri-winservices) reports from only 1 of the 27 hosts in the account: BCA-VM-SRV-001.** This is not just a Test gap — 19 of the 20 production hosts lack it too. Missing in production: BCA-VM-API-001/002/003, BCA-VM-WEB-001/002/003, BCA-VM-SQL-001, UE2-ADC-A02/B02, UE2-API-A01/A02/B01, UE2-SQL-A01/A02/B02, UE2-SRV-A01, UE2-WEB-A01/A02/B01. Missing in test: all 7 (UE1-TEST-API-A1/B1, UE1-TEST-SMT-A1, UE1-TEST-SRV-A1, UE1-TEST-WEB-A1, MIAT-VM-SRV-001, MIAT-VM-SQL-001). Consequences: the Test dashboard stays empty and the alert "IPS Finwinservice Test is down" (MIAT-VM-SRV-001) can never fire. Enable instructions were delivered to the team on 2026-09-05; still not enabled as of 2026-09-10. `scripts/Enable-NriWinservices.ps1` automates the enablement, including the fleet rollout via `Invoke-Command`.
- **The production "Windows Services - Dashboard" has no host scope.** All 16 of its queries filter only on the `{{hostname}}` variable, so it displays whatever host happens to report. It looks healthy only because the single reporting host is the one running the IPS services. Unlike it, `dashboard_windows_test.tf` pins its scope with `hostname LIKE 'UE1-TEST%' OR hostname LIKE 'MIAT-VM%'`.
- **The hardcoded IPS service list does not match the real service names.** `local.windows_test_services` came from the alert condition and drifts from what the hosts actually report: production has `ipsripplepaymentsservice` (the list says `ripplepaymentsservice`), plus `ips_emailreceiverwindowsservice` and `ips_bai2reportsservice`, neither of which is in the list. The "IPS services not running" billboard therefore undercounts. Verify with `Get-Service | Where-Object { $_.Name -match '^ips|ripple' }` on each host before trusting that widget. The Test dashboard now works around this with the pattern-based `local.windows_test_critical`; the production dashboard and `local.windows_test_services` still carry the stale list.
- **`ips_bai2reportsservice` ("IPS BAI2 Reports Processing Service") is stopped on BCA-VM-SRV-001** with `start_mode: auto`, continuously for at least 24 h as of 2026-09-10 — and invisible on the dashboards because the name is absent from the hardcoded list. Likely means BAI2 bank reconciliation reports are not being generated.
- The production winservices filter is broader than intended: it collects `iphlpsvc` (the Windows IP Helper service), which implies a `regex "ip.*"` rather than `ips`. Anchoring as `regex "^ips.*"` covers every IPS service (`ips_*`, `ipsonboardingservice`, `ipsportalcoreschedulerservice`, `ipsripplepaymentsservice`) without pulling in OS services.
- Alert coverage is thin: only 4 of 8 policies do anything; "Alert on Failure of Corp Website" is empty (no conditions, no workflow); APM error-percentage and Apdex conditions exist but are disabled; 15 of 17 hosts have no host-down alert; the 135 synthetic monitors have no alert conditions.
- A Slack destination "i-payout" with channel `#newrelic-errors` already exists in the account (used only by the two Finwin policies); the user leans toward Slack for new alerts.
- Two pre-existing synthetic monitors ("Corp website", "Demo globalewallet") are not yet managed by Terraform.

## Pending / next

- Roll out `scripts/Enable-NriWinservices.ps1` to the 26 hosts without the integration (test one first, then production). Until then the Test dashboard stays empty.
- Alert policies + NRQL conditions notifying Slack: host down (all 27 hosts), synthetic failures/slowness, disk > 90%, memory > 90%, high error rate. When first measured, UE2-SQL-A01 (disk P: 96%, memory 94%) and BCA-VM-SQL-001 would already trigger.

## Operational notes

- Creating >100 resources in one apply hits the New Relic API `RATE_LIMITED`; retry the remainder with `terraform apply -parallelism=1`.
- `terraform plan` output pipes through grep poorly because of ANSI codes — use `-no-color`.
- **nri-winservices is bundled with the Windows infrastructure agent** — nothing to install, unlike nri-mssql. Enabling it means dropping `C:\Program Files\New Relic\newrelic-infra\integrations.d\winservices-config.yml` on the host and running `Restart-Service newrelic-infra`. Requires agent >= 1.12.1 (all 27 hosts qualify, though MIAT-VM-SQL-001 is on 1.20.7 and MIAT-VM-SRV-001 on 1.62.0 and both are worth upgrading). Gotchas: `include_matching_entities` is mandatory (without it the integration runs and reports nothing); use `scrape_interval`, not `interval`, which is ignored for this long-running integration; write the file as UTF-8 **without BOM** (`[System.IO.File]::WriteAllText`, not `Out-File`) or the agent's YAML parser rejects it silently; the exporter binds `127.0.0.1:9182`, which collides with an existing `windows_exporter` if one is present.
- **Winservices ingest scales as `services x hosts / scrape_interval`.** Reporting every service at the default 30s across the 27 hosts would add roughly 240 GB/month to an account already ingesting ~540 GB/month; at 400s the same coverage costs on the order of 20 GB/month. The decision is to collect **every** service at **400s** rather than curate a service list, because the curated list is exactly what has already drifted (see the known issue above) — filtering in NRQL removes that class of bug. The cost is detection latency: a stopped service is noticed up to ~7 minutes later, which changes no decision for services nobody restarts automatically. If a tier needs faster detection, add a second integration block with a tighter `scrape_interval` and a narrow regex; the agent supports several instances. Measure before widening with `SELECT rate(bytecountestimate(), 1 day) / 1e9 FROM Metric WHERE metricName = 'windows_service_state' FACET hostname SINCE 1 day ago`, and if ingest runs away it can be cut from one place with a drop filter instead of touching 27 hosts.
- Proxy configuration does not affect nri-winservices: the agent scrapes the exporter over loopback, and Go never proxies localhost. Egress is already proven working on all 27 hosts, since every one of them sends SystemSample.
