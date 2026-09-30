# Alerting for the DR environment (UE2-*), notifying Slack.
#
# Mirror of alerts.tf, which does the same for Test. DR had no alerting of any kind
# until 2026-09-30, and the cost of that was visible the day these were written:
# UE2-WEB-A01's agent had been dead since 12:18 UTC and UE2-WEB-A02's C: drive had been
# at 100% with 0.0 GB free for over six hours, and neither had reached anyone.
#
# Thresholds are the same figures as Test, deliberately. They were set there from what
# the fleet runs at, and DR's volumes sit in the same range, so re-deriving them would
# produce the same numbers with more words. What both files share is the rule that the
# percentage is what can be alerted on consistently across differently sized volumes
# while the free-space figure decides urgency -- see the condition descriptions.
#
# Expected on first apply: one critical on UE2-WEB-A02 C: (100%, genuinely full), one
# host-down on UE2-WEB-A01 (agent stopped, host otherwise healthy), and one warning on
# UE2-SQL-A02 D: (85.7% of 1.3 TB, which still leaves 184 GB -- the noise case the
# descriptions warn about). The first two are correct and want acting on.
#
# The critical-services condition has no targets yet: of the thirteen DR hosts only
# UE2-SMTP-A01 reports windows_service_state, and it runs none of these services. It is
# created now so it works the day the nri-winservices rollout reaches DR, rather than
# being remembered afterwards.

locals {
  # Every condition in this file is pinned to the DR hosts.
  #
  # UE2-REDIS-A02 is named explicitly because it reports under its EC2 private DNS name
  # instead of its hostname -- the agent was installed without `display_name`. Remove
  # this second clause once that line is added to /etc/newrelic-infra.yml on the host
  # and it starts reporting as UE2-REDIS-A02; a hardcoded instance name is exactly the
  # kind of thing that rots silently.
  dr_alert_scope = "(hostname LIKE 'UE2%' OR hostname = 'ip-10-20-128-202')"
}

# ---------------------------------------------------------------- notification

# One channel per workflow: the API rejects a channel that is already attached to
# another workflow with INVALID_PARAMETER. All three point at the same Slack room.

resource "newrelic_notification_channel" "slack_dr_disk" {
  account_id     = 1468011
  name           = "newrelic-errors (DR disk space)"
  type           = "SLACK"
  product        = "IINT"
  destination_id = local.slack_destination_id

  property {
    key   = "channelId"
    value = local.slack_channel_id
  }
}

resource "newrelic_notification_channel" "slack_dr_host_down" {
  account_id     = 1468011
  name           = "newrelic-errors (DR host down)"
  type           = "SLACK"
  product        = "IINT"
  destination_id = local.slack_destination_id

  property {
    key   = "channelId"
    value = local.slack_channel_id
  }
}

resource "newrelic_notification_channel" "slack_dr_critical_services" {
  account_id     = 1468011
  name           = "newrelic-errors (DR critical services)"
  type           = "SLACK"
  product        = "IINT"
  destination_id = local.slack_destination_id

  property {
    key   = "channelId"
    value = local.slack_channel_id
  }
}

# ---------------------------------------------------------------- disk space

resource "newrelic_alert_policy" "dr_disk_space" {
  account_id = 1468011
  name       = "DR - Disk space"

  # One incident per volume, so a full C: on one host does not suppress a full D: on
  # another.
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "dr_disk_space" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.dr_disk_space.id
  name       = "DR host disk usage is high"
  type       = "static"
  enabled    = true

  description = <<-EOT
    A volume on a DR host is running out of space. Read the free-space figure alongside
    the percentage: 86% of a 1.3 TB data volume still leaves 184 GB, while 85% of a
    64 GB system drive leaves under 10 GB. The percentage is what can be alerted on
    consistently across differently sized volumes; the absolute figure decides urgency.

    DR being idle does not make a full disk harmless. A Windows host with no free space
    on C: cannot write logs or page, and IIS starts failing requests -- which is
    discovered at the worst possible moment, when DR is actually needed.
  EOT

  nrql {
    query = "SELECT latest(diskUsedPercent) FROM StorageSample WHERE ${local.dr_alert_scope} FACET hostname, mountPoint"
  }

  # The default title names only the host, which is ambiguous the moment a host has two
  # volumes over threshold. The facet values are exposed as tags.
  title_template = "Disk {{tags.mountPoint}} on {{tags.hostname}} is above threshold"

  # StorageSample arrives about every 20s; a 5-minute window smooths a single late
  # sample without delaying a real signal noticeably.
  aggregation_method = "event_flow"
  aggregation_window = 300
  aggregation_delay  = 120

  critical {
    operator              = "above"
    threshold             = 90
    threshold_duration    = 1800 # a spike that clears itself is not worth waking anyone
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

resource "newrelic_alert_policy" "dr_host_down" {
  account_id          = 1468011
  name                = "DR - Host down"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "dr_host_down" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.dr_host_down.id
  name       = "DR host stopped reporting"
  type       = "static"
  enabled    = true

  description = <<-EOT
    A DR host has stopped sending data to New Relic. Either the machine is down, the
    infrastructure agent has stopped, or it lost its route out -- the alert cannot tell
    which, so check the host itself first.

    Worth checking before assuming the machine is gone: on 2026-09-30 UE2-WEB-A01 went
    silent here while its .NET agent kept reporting 600+ transactions every 15 minutes.
    The host was fine; only the infrastructure agent had stopped. If APM still reports
    for the host, it is a service problem, not a dead VM.

    This is a loss-of-signal condition: a dead host sends nothing, so there is no value
    to compare against a threshold. The signal expiring is the alert.

    It only covers hosts that have reported at least once. A host that never had the
    agent installed has no signal to lose and will never appear here -- the "Hosts
    reporting (of 13)" tile on the DR Environment dashboard is what catches those.
  EOT

  nrql {
    query = "SELECT uniqueCount(hostname) FROM SystemSample WHERE ${local.dr_alert_scope} FACET hostname"
  }

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

# ---------------------------------------------------------------- critical services

resource "newrelic_alert_policy" "dr_critical_services" {
  account_id          = 1468011
  name                = "DR - Critical services"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "dr_critical_services" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.dr_critical_services.id
  name       = "Critical service is not running on a DR host"
  type       = "static"
  enabled    = true

  description = <<-EOT
    One of the services the business requires at 100% uptime is not in the "running"
    state on a DR host.

    The value per host/service pair is 1 while running and 0 while stopped/paused.
    Signal loss is also an alert (open_violation_on_expiration): a service that stops
    reporting was uninstalled, renamed, or the winservices integration on the host
    broke -- each of those also violates the uptime requirement.

    No targets exist yet. Of the thirteen DR hosts only UE2-SMTP-A01 reports
    windows_service_state, and it runs none of these services, so a facet forms for
    nothing today. That is not a fault: facets appear on their own as
    scripts/Enable-NriWinservices.ps1 reaches the rest of DR.
  EOT

  nrql {
    query = "SELECT filter(uniqueCount(entity.guid), WHERE state = 'running') FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_dr} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name"
  }

  title_template = "Critical service {{tags.service_name}} is not running on {{tags.hostname}}"

  aggregation_method = "event_flow"
  aggregation_window = 600 # must exceed the 400s scrape so every window holds a sample
  aggregation_delay  = 120

  critical {
    operator              = "below"
    threshold             = 1
    threshold_duration    = 600
    threshold_occurrences = "all"
  }

  expiration_duration            = 1800
  open_violation_on_expiration   = true
  close_violations_on_expiration = false
}

# ---------------------------------------------------------------- workflows

# One workflow per policy rather than a single catch-all, so each can be muted or
# re-routed on its own -- disk noise during a cleanup should not silence host-down.

resource "newrelic_workflow" "dr_disk_space" {
  account_id            = 1468011
  name                  = "DR - Disk space -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "dr-disk-space"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.dr_disk_space.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_dr_disk.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}

resource "newrelic_workflow" "dr_host_down" {
  account_id            = 1468011
  name                  = "DR - Host down -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "dr-host-down"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.dr_host_down.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_dr_host_down.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}

resource "newrelic_workflow" "dr_critical_services" {
  account_id            = 1468011
  name                  = "DR - Critical services -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "dr-critical-services"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.dr_critical_services.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_dr_critical_services.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}
