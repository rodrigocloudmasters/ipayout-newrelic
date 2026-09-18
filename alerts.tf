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
