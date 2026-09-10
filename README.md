# iPayout New Relic Infrastructure as Code

Terraform project managing the New Relic account of International Payout Systems Inc (account `1468011`): dashboards and synthetic monitoring, with alerts on the roadmap.

## Contents

| File | Resources |
|---|---|
| `provider.tf` | Terraform + New Relic provider configuration |
| `dashboards.tf` | The 10 pre-existing dashboards, imported from the account |
| `dashboard_hosts.tf` | Infrastructure - Hosts (CPU, Memory, Disk) |
| `dashboard_synthetics.tf` | Web Availability (Synthetics) |
| `dashboard_mssql.tf` | SQL Server health |
| `dashboard_apm.tf` | APM - Application Health |
| `dashboard_errors.tf` | Errors & Exceptions |
| `dashboard_processes.tf` | Host Processes (top CPU/memory per host) |
| `synthetics.tf` | 135 SIMPLE ping monitors (one per live site, via `for_each`) |
| `dashboard_windows_test.tf` | Windows Services - Test Environment |
| `scripts/` | Host-side PowerShell (New Relic agent configuration) |

## Host-side setup

Some dashboards need an integration enabled on the Windows hosts themselves, which
Terraform cannot do. `scripts/Enable-NriWinservices.ps1` configures the Windows Services
integration (`nri-winservices`) and restarts the agent; see `scripts/README.md` for the
fleet rollout and the ingest-cost rationale behind its defaults.

## Setup

1. Create a `.env` file in the repo root (never committed — see `.gitignore`):

   ```
   NEW_RELIC_API_KEY=NRAK-...   # "User" API key
   NEW_RELIC_ACCOUNT_ID=1468011
   NEW_RELIC_REGION=US
   ```

2. Initialize and plan:

   ```sh
   terraform init
   set -a; source .env; set +a
   terraform plan
   ```

## Workflow

All changes go through code: edit the `.tf` files, `terraform plan`, `terraform apply`. Editing these resources from the New Relic UI causes drift that the next `apply` reverts.

To add or remove a monitored site, edit the domain lists in `synthetics.tf`. Monitors are SIMPLE ping checks (not billable as synthetic checks) hitting `/public/healthcheck.ashx` every 10 minutes from 2 US locations, with SSL verification.

## Notes

- The Terraform state is local and gitignored (it contains resource details). Consider a remote backend if more people join.
- The MSSQL integration reports only from `UE2-SQL-A01` and `MIAT-VM-SQL-001`; the other SQL hosts need `nri-mssql` installed to appear in the SQL Server dashboard.
- The Windows Services integration reports from only 1 of the 27 hosts (`BCA-VM-SRV-001`). The Windows Services dashboards stay empty for every other host until `scripts/Enable-NriWinservices.ps1` is rolled out.
- Two pre-existing synthetic monitors ("Corp website", "Demo globalewallet") are not yet managed by Terraform.
