# Ingest reduction -- analysis and the rule that is ready to apply once the account
# is entitled to Pipeline Control.
#
# NOT ACTIVE. The resource below is commented out because creating it is currently
# refused:
#
#   Access denied (subjectType='USER', subjectId='1008410702', action='can_create',
#   resourceType='PIPELINE_CLOUD_RULE')
#
# Pipeline Control cloud rules require the account to be on New Relic Compute
# usage-based pricing. Attempted 2026-09-18 as rodrigo@cloudmastersit.com. Ask the New
# Relic account team either to move the account to Compute pricing or to grant the
# capability, then uncomment and apply -- the rule itself is written and the NRQL was
# validated against real data.
#
# Leaving it commented rather than deleted keeps the measurement with the decision, and
# keeps `terraform apply` from failing on every run in the meantime.
#
# ---------------------------------------------------------------------------
# WHY THIS RULE
#
# ProcessSample is by far the heaviest event this account produces: 859 GB/month across
# the fleet as of 2026-09-18, roughly 72% of total ingest. Each host reports about 240
# processes every 20 seconds, the infrastructure agent's default.
#
# Measured over an hour on the Test hosts, those samples break down as:
#
#   88.0%  idle and small   (< 0.1% CPU and < 50 MB resident)
#    7.2%  low consumption
#    4.8%  actually relevant (>= 1% CPU or >= 100 MB resident)
#
# The rule drops the idle 88% -- about 355 GB/month -- and keeps everything that could
# explain a performance problem. The important property is that it drops idle *samples*,
# not idle *processes*: a process sitting at zero is dropped while it sits there, and
# the moment it starts consuming, its samples cross the threshold and are kept. Nothing
# that could be the cause of an incident is discarded.
#
# The "Host Processes" dashboard keeps working: its widgets rank top CPU and memory
# consumers, which is exactly the data that survives. Whether a given service is running
# at all is better answered by nri-winservices, now enabled on the Test hosts.
#
# Scoped to Test. Production carries the other ~456 GB/month of ProcessSample and is
# deliberately untouched.
#
# Dropped data is not stored and not billed, which is the point -- but it is dropped
# permanently, and the rule applies only to data arriving after it is created.
#
# ---------------------------------------------------------------------------
# THE ALTERNATIVE, IF THE ENTITLEMENT DOES NOT ARRIVE
#
# scripts/Set-ProcessSampleRate.ps1 raises the sample interval from 20s to 60s on the
# host itself. It saves less (about 269 GB/month against 355) and costs time resolution
# on every process rather than dropping only the idle ones -- but it needs no
# entitlement. It does need access to each host, which a central rule would avoid.
#
# ---------------------------------------------------------------------------

# resource "newrelic_pipeline_cloud_rule" "drop_idle_process_samples_test" {
#   account_id  = 1468011
#   name        = "Drop idle ProcessSample on Test hosts"
#   description = "Discards process samples from UE1-TEST hosts using under 0.1% CPU and under 50 MB of memory. About 88% of process samples on those hosts, roughly 355 GB/month, none of it capable of explaining a performance problem."
#
#   nrql = "DELETE FROM ProcessSample WHERE hostname LIKE 'UE1-TEST%' AND cpuPercent < 0.1 AND memoryResidentSizeBytes < 50000000"
# }
