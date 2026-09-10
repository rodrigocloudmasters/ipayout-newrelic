# CLAUDE.md

Project context and conventions. This file mirrors the working memory of the project; keep it updated when anything below changes.

## Language convention

Conversation with the user is in Spanish (Argentine), but everything that lives in code or in New Relic must be in English: Terraform files and comments, dashboard names, page names, widget titles, NRQL aliases, alert policy/condition names, notification channels, this file, commit messages, README.

## Project

Terraform project managing New Relic for International Payout Systems Inc (account ID `1468011`, US region). Credentials live in a gitignored `.env` (User API key `NRAK-...`) read by the provider via `NEW_RELIC_API_KEY` / `NEW_RELIC_ACCOUNT_ID` / `NEW_RELIC_REGION` env vars — no credentials in `.tf` files. State is local and gitignored.

All changes go through code: edit `.tf`, `terraform plan`, `terraform apply` (`set -a; source .env; set +a` first). UI edits to managed resources are drift and get reverted on the next apply.

## Current state

- The 10 pre-existing dashboards were imported into state (`dashboards.tf`, generated with `terraform plan -generate-config-out`).
- `dashboard_hosts.tf`: "Infrastructure - Hosts (CPU, Memory, Disk)" — 17 Windows hosts monitored via the Infrastructure agent.
- `synthetics.tf`: 135 SIMPLE ping monitors ("Web - <domain>", every 10 min, US_EAST_1 + US_WEST_1, SSL verification) covering every domain with ≥ 20 pageviews/7d that responds. 134 hit the platform-wide healthcheck endpoint `/public/healthcheck.ashx`; `supernova.i-payout.com` lacks it and uses its homepage. SIMPLE ping monitors are not billable as synthetic checks; their ingest is ~1 GB/month vs ~540 GB/month the account already ingests.
- `dashboard_synthetics.tf`: "Web Availability (Synthetics)".
- `dashboard_mssql.tf`: "SQL Server" — the nri-mssql integration reports only from UE2-SQL-A01 and MIAT-VM-SQL-001; UE2-SQL-A02 and BCA-VM-SQL-001 need it installed to appear. In `MssqlDatabaseSample` the database name attribute is `displayName`.
- `dashboard_apm.tf`: "APM - Application Health" — ~20 .NET apps; IPS New does ~1M transactions/day.
- `dashboard_errors.tf`: "Errors & Exceptions" — CommissionNetworks.com had a ~58% error rate when first checked (2026-08-31).
- `dashboard_processes.tf`: "Host Processes" (ProcessSample, host variable).
- `dashboard_windows_test.tf`: "Windows Services - Test Environment" — mirror of the production Windows Services dashboard scoped to UE1-TEST-* / MIAT-VM-* hosts; IPS service list taken from the "IPS Finwinservice Test is down" alert condition.

## Known issues / findings

- **The Windows Services integration (nri-winservices) reports only from BCA-VM-SRV-001 (production).** The test hosts send no `windows_service_state` data, so the Test dashboard stays empty and the existing alert "IPS Finwinservice Test is down" (MIAT-VM-SRV-001) can never fire. Enable instructions (winservices-config.yml with `regex "ips.*"` + `ripplepaymentsservice`, then `Restart-Service newrelic-infra`) were delivered to the team on 2026-09-05; still not enabled as of 2026-09-10.
- Alert coverage is thin: only 4 of 8 policies do anything; "Alert on Failure of Corp Website" is empty (no conditions, no workflow); APM error-percentage and Apdex conditions exist but are disabled; 15 of 17 hosts have no host-down alert; the 135 synthetic monitors have no alert conditions.
- A Slack destination "i-payout" with channel `#newrelic-errors` already exists in the account (used only by the two Finwin policies); the user leans toward Slack for new alerts.
- Two pre-existing synthetic monitors ("Corp website", "Demo globalewallet") are not yet managed by Terraform.

## Pending / next

- Alert policies + NRQL conditions notifying Slack: host down (all 17 hosts), synthetic failures/slowness, disk > 90%, memory > 90%, high error rate. When first measured, UE2-SQL-A01 (disk P: 96%, memory 94%) and BCA-VM-SQL-001 would already trigger.

## Operational notes

- Creating >100 resources in one apply hits the New Relic API `RATE_LIMITED`; retry the remainder with `terraform apply -parallelism=1`.
- `terraform plan` output pipes through grep poorly because of ANSI codes — use `-no-color`.
