# Alerting for the Test environment (UE1-TEST-*), notifying Slack.
#
# Scoped to Test on purpose. The account has eight pre-existing policies, but between
# them they cover one Windows service and one synthetic monitor, and only two notify
# Slack -- so nothing here duplicates what exists. Everything is pinned to
# `hostname LIKE 'UE1-TEST%'`; production is deliberately out of scope.
#
# No synthetic condition. All 137 synthetic monitors in the account target production
# sites -- there is not one Test monitor, so a Test-scoped synthetic alert would watch
# nothing. Monitors for the Test sites would have to exist first.
#
# Thresholds come from what the Test hosts actually run at, not round numbers:
#
#   Disk      Three Test volumes are already above 85%: both SQL hosts sit at 94.6% on
#             E: (3.5 GB free, flat for days -- sized tight, not filling) and the domain
#             controller at 85.1% on C: (4.7 GB). Critical at 90% fires on the two SQL
#             volumes immediately, which is correct: 3.5 GB is not enough headroom for a
#             SQL log or an index rebuild.
#   Host down A dead host sends nothing, so there is no value to threshold. This is a
#             loss-of-signal condition -- the silence is the alert.
#
# Both notify #newrelic-errors through the Slack destination that already exists in the
# account (created 2024-12-11). That destination is deliberately NOT managed here: it
# holds an OAuth grant to the Slack workspace that Terraform cannot recreate, so it is
# referenced by id and the channel below hangs off it.

locals {
  # Pre-existing Slack destination "i-payout" -> workspace i-payout.
  slack_destination_id = "bafe2135-89e8-4790-9b73-d1539cf85df1"
  slack_channel_id     = "C084RK2UXPE" # #newrelic-errors

  # Every condition in this file is pinned to the Test hosts.
  test_alert_scope = "hostname LIKE 'UE1-TEST%'"
}

# ---------------------------------------------------------------- notification

resource "newrelic_notification_channel" "slack_test_alerts" {
  account_id     = 1468011
  name           = "newrelic-errors (Test infrastructure)"
  type           = "SLACK"
  product        = "IINT"
  destination_id = local.slack_destination_id

  property {
    key   = "channelId"
    value = local.slack_channel_id
  }
}

# ---------------------------------------------------------------- disk space

resource "newrelic_alert_policy" "test_disk_space" {
  account_id = 1468011
  name       = "Test - Disk space"

  # Per condition and target: one incident per volume, so a full C: on one host does not
  # suppress a full E: on another.
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "test_disk_space" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.test_disk_space.id
  name       = "Test host disk usage is high"
  type       = "static"
  enabled    = true

  description = <<-EOT
    A volume on a Test host is running out of space. Read the free-space figure
    alongside the percentage: 87% of a 267 GB volume still leaves 34 GB, while 85% of a
    32 GB system drive leaves under 5 GB. The percentage is what can be alerted on
    consistently across differently sized volumes; the absolute figure decides urgency.

    On the SQL hosts, E: is the volume to watch -- if it holds transaction logs or
    tempdb, SQL Server stops accepting writes when it fills.
  EOT

  nrql {
    query = "SELECT latest(diskUsedPercent) FROM StorageSample WHERE ${local.test_alert_scope} FACET hostname, mountPoint"
  }

  # The default title names only the host ("UE1-TEST-ADC-A2 query result is > 85.0"),
  # which is ambiguous the moment a host has two volumes over threshold -- two identical
  # Slack messages, neither saying which disk. The facet values are exposed as tags.
  title_template = "Disk {{tags.mountPoint}} on {{tags.hostname}} is above threshold"

  # StorageSample arrives about every 20s; a 5-minute window smooths a single late
  # sample without delaying a real signal noticeably.
  aggregation_method = "event_flow"
  aggregation_window = 300
  aggregation_delay  = 120

  critical {
    operator              = "above"
    threshold             = 90
    threshold_duration    = 1800 # 30 min -- a spike that clears itself is not worth waking anyone
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = 85
    threshold_duration    = 3600
    threshold_occurrences = "all"
  }

  # A volume that stops reporting is a host problem, not a disk problem; the host-down
  # condition owns that case, so close these rather than holding them open.
  expiration_duration            = 3600
  open_violation_on_expiration   = false
  close_violations_on_expiration = true
}

# ---------------------------------------------------------------- host down

resource "newrelic_alert_policy" "test_host_down" {
  account_id          = 1468011
  name                = "Test - Host down"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "test_host_down" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.test_host_down.id
  name       = "Test host stopped reporting"
  type       = "static"
  enabled    = true

  description = <<-EOT
    A Test host has stopped sending data to New Relic. Either the machine is down, the
    infrastructure agent has stopped, or it lost its route out -- the alert cannot tell
    which, so check the host itself first.

    This is a loss-of-signal condition: a dead host sends nothing, so there is no value
    to compare against a threshold. The signal expiring is the alert.

    It only covers hosts that have reported at least once. A host that never had the
    agent installed has no signal to lose and will never appear here -- the "Hosts
    reporting (of 11)" tile on the Test Environment dashboard is what catches those.
  EOT

  nrql {
    query = "SELECT uniqueCount(hostname) FROM SystemSample WHERE ${local.test_alert_scope} FACET hostname"
  }

  # "query result is < 1" reads as a threshold breach rather than what it is.
  title_template = "Host {{tags.hostname}} stopped reporting to New Relic"

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  # Never reached in practice -- a host that reports at all satisfies this. The condition
  # exists so the signal has something to attach to; the expiration below does the work.
  critical {
    operator              = "below"
    threshold             = 1
    threshold_duration    = 300
    threshold_occurrences = "all"
  }

  # 10 minutes of silence. SystemSample arrives every few seconds, so this is well past
  # any plausible network hiccup while still catching a dead host quickly.
  expiration_duration            = 600
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
}

# ---------------------------------------------------------------- workflows

# One workflow per policy rather than a single catch-all, so each can be muted or
# re-routed on its own -- disk noise during a cleanup should not silence host-down.

resource "newrelic_workflow" "test_disk_space" {
  account_id            = 1468011
  name                  = "Test - Disk space -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "test-disk-space"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.test_disk_space.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_test_alerts.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}

resource "newrelic_workflow" "test_host_down" {
  account_id            = 1468011
  name                  = "Test - Host down -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "test-host-down"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.test_host_down.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_test_alerts.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}

# ---------------------------------------------------------------- data ingest

# Account-wide on purpose, unlike everything above. Ingest is billed per account, so
# scoping this to the Test hosts would watch a fraction of the bill and miss the cases
# that actually cost money.
#
# Notifies rodrigo@cloudmastersit.com by email rather than Slack: a cost problem is not
# an on-call problem, and it is addressed to whoever owns the invoice.
#
# Why a daily rate rather than a month-to-date total: NRQL alert conditions evaluate
# rolling windows, so `SINCE this month` is not available to them. The daily rate is the
# projection -- multiply by 30 for the monthly figure, which is what the thresholds below
# are named after.
#
# Measured baseline over the three weeks to 2026-09-18: 37.9 to 46.1 GB/day, sitting
# around 40, which projects to roughly 1,200 GB/month. The largest contributors over 30
# days were InfraProcessBytes (541 GB), MetricsBytes (184 GB) and InfraIntegrationBytes
# (42 GB).
#
# The failure mode this exists to catch is a configuration mistake, not organic growth.
# Reporting every Windows service at the default 30s interval instead of 400s across the
# fleet would add roughly 240 GB/month on its own -- about +8 GB/day, which these
# thresholds catch within hours instead of at the end of the billing period.

locals {
  # Thresholds in GB/day. Change these two numbers to retune the alert.
  #   50 GB/day = ~1,500 GB/month   (25% above the current run rate)
  #   60 GB/day = ~1,800 GB/month   (50% above)
  ingest_warning_gb_per_day  = 50
  ingest_critical_gb_per_day = 60
}

resource "newrelic_notification_destination" "email_billing" {
  account_id = 1468011
  name       = "Billing owner"
  type       = "EMAIL"

  property {
    key   = "email"
    value = "rodrigo@cloudmastersit.com"
  }
}

resource "newrelic_notification_channel" "email_billing" {
  account_id     = 1468011
  name           = "Billing owner (data ingest)"
  type           = "EMAIL"
  product        = "IINT"
  destination_id = newrelic_notification_destination.email_billing.id

  property {
    key   = "subject"
    value = "New Relic data ingest is above the expected rate"
  }
}

resource "newrelic_alert_policy" "data_ingest" {
  account_id = 1468011
  name       = "Data ingest"

  # One incident for the account: there is a single bill, so a second incident would say
  # nothing the first did not.
  incident_preference = "PER_POLICY"
}

resource "newrelic_nrql_alert_condition" "data_ingest" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.data_ingest.id
  name       = "Data ingest rate is above budget"
  type       = "static"
  enabled    = true

  description = <<-EOT
    Data ingest is running above the expected rate. Multiply the value by 30 for the
    monthly projection: 50 GB/day is about 1,500 GB/month, 60 GB/day about 1,800.

    The normal rate for this account is around 40 GB/day (~1,200 GB/month). A sustained
    jump is almost always a configuration change rather than real growth -- an
    integration sampling far more often than intended, a new log source, or a
    scrape_interval that was shortened.

    To find the cause:

      SELECT sum(GigabytesIngested) FROM NrConsumption
      WHERE productLine = 'DataPlatform' FACET usageMetric SINCE 2 days ago

    then drill into whichever bucket grew. For Windows services specifically:

      SELECT rate(bytecountestimate(), 1 day) / 1e9 FROM Metric
      WHERE metricName = 'windows_service_state' FACET hostname SINCE 1 day ago
  EOT

  nrql {
    query = "SELECT rate(sum(GigabytesIngested), 1 day) FROM NrConsumption WHERE productLine = 'DataPlatform'"
  }

  title_template = "Data ingest is running at {{value}} GB/day"

  # NrConsumption is written roughly hourly and can run two or more hours behind, with
  # whole hours missing. An hour-long window with the maximum delay rides over the lag,
  # and the long threshold_duration below means a single late or missing hour cannot
  # move the alert either way.
  aggregation_method = "event_timer"
  aggregation_window = 3600
  aggregation_timer  = 1200
  fill_option        = "none"

  critical {
    operator              = "above"
    threshold             = local.ingest_critical_gb_per_day
    threshold_duration    = 10800 # 3 h
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = local.ingest_warning_gb_per_day
    threshold_duration    = 21600 # 6 h -- this is a billing trend, not an outage
    threshold_occurrences = "all"
  }

  # Gaps in NrConsumption are normal, so silence must never be read as a problem here.
  expiration_duration            = 21600
  open_violation_on_expiration   = false
  close_violations_on_expiration = true
}

resource "newrelic_workflow" "data_ingest" {
  account_id            = 1468011
  name                  = "Data ingest -> billing owner"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "data-ingest"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.data_ingest.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.email_billing.id
    notification_triggers = ["ACTIVATED", "CLOSED"]
  }
}
