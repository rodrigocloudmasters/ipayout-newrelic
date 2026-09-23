# Critical services on the Test hosts: the business requires 100% uptime for these.
# Scoped to every UE1-TEST host: a facet only forms where a service actually reports,
# so hosts that never run one of these services never create alert targets. Today only
# UE1-TEST-SRV-A1 runs them; any Test host that picks one up is covered automatically.
#
# Service names are as reported by nri-winservices (lowercase); Ripple reports as
# "ripplepaymentsservice" on Test and "ipsripplepaymentsservice" in production — both
# names are listed so a renamed deployment stays covered.
#
# Detection resolution follows the 400s scrape: the alert aggregates in 600s windows, so
# a stopped service notifies Slack within ~10-20 minutes. The uptime figure on the
# dashboard is the percentage of samples in "running" state at that same resolution.

locals {
  critical_services_scope      = "hostname LIKE 'UE1-TEST%'"
  critical_services_scope_prod = "(hostname LIKE 'BCA-VM%' OR hostname LIKE 'UE2%')"
  critical_services_srv        = "'ipsportalcoreschedulerservice', 'ips_abacollectorservice', 'ips_emailsenderservice', 'ips_feecollector', 'ips_fxservice', 'ips_healthmonitor', 'ips_loadvirtualaccountsservice', 'ripplepaymentsservice', 'ipsripplepaymentsservice'"
}

resource "newrelic_alert_policy" "test_critical_services" {
  account_id          = 1468011
  name                = "Test - Critical services"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_nrql_alert_condition" "test_critical_services" {
  account_id = 1468011
  policy_id  = newrelic_alert_policy.test_critical_services.id
  name       = "Critical service is not running on a Test host"
  type       = "static"
  enabled    = true

  description = <<-EOT
    One of the services the business requires at 100% uptime is not in the "running"
    state on a Test host.

    The value per host/service pair is 1 while running and 0 while stopped/paused.
    Signal loss is also an alert (open_violation_on_expiration): a service that stops
    reporting was uninstalled, renamed, or the winservices integration on the host
    broke -- each of those also violates the uptime requirement.
  EOT

  nrql {
    query = "SELECT filter(uniqueCount(entity.guid), WHERE state = 'running') FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name"
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
  open_violation_on_expiration   = true # a vanished service also breaks the uptime requirement
  close_violations_on_expiration = false
}

# A workflow cannot share a notification channel with another workflow (the API rejects
# it with INVALID_PARAMETER), so this one gets its own channel to the same Slack room.
resource "newrelic_notification_channel" "slack_critical_services" {
  account_id     = 1468011
  name           = "newrelic-errors (Test critical services)"
  type           = "SLACK"
  product        = "IINT"
  destination_id = local.slack_destination_id

  property {
    key   = "channelId"
    value = local.slack_channel_id
  }
}

resource "newrelic_workflow" "test_critical_services" {
  account_id            = 1468011
  name                  = "Test - Critical services -> Slack"
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "test-critical-services"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.test_critical_services.id]
    }
  }

  destination {
    channel_id            = newrelic_notification_channel.slack_critical_services.id
    notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
  }
}

resource "newrelic_one_dashboard" "test_critical_services" {
  account_id  = 1468011
  name        = "Test - Critical Services Uptime"
  description = "Uptime of the services required at 100% on the Test hosts. Uptime is the percentage of winservices samples (every 400s) in the running state over the selected time range."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title    = "Critical services not running"
      row      = 1
      column   = 1
      width    = 3
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Not running' FROM (FROM Metric SELECT latest(state) AS 'st' WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
      }
    }

    widget_billboard {
      title  = "Hosts with critical services"
      row    = 1
      column = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_billboard {
      title  = "Services reporting"
      row    = 1
      column = 7
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(service_name) AS 'Services' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_billboard {
      title  = "Combined uptime %"
      row    = 1
      column = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_table {
      title  = "Uptime % and current state by host and service"
      row    = 4
      column = 1
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %', latest(state) AS 'Now', latest(display_name) AS 'Display name' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name LIMIT MAX"
      }
    }

    widget_line {
      title          = "Uptime % by host and service - trend"
      row            = 4
      column         = 7
      width          = 6
      height         = 5
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name TIMESERIES AUTO LIMIT MAX"
      }
    }
  }
}

# Production twin of the Test uptime dashboard. Visibility only -- the critical-services
# ALERT covers Test hosts exclusively (extending it to production was declined for now).
# Until the winservices rollout reaches production, the only host with data here is
# BCA-VM-SRV-001 (7 of the services, no ips_healthmonitor).
resource "newrelic_one_dashboard" "prod_critical_services" {
  account_id  = 1468011
  name        = "Production - Critical Services Uptime"
  description = "Uptime of the services required at 100% on the production hosts (BCA-VM-* and UE2-*). Uptime is the percentage of winservices samples in the running state over the selected time range. No alert is wired to this scope."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title    = "Critical services not running"
      row      = 1
      column   = 1
      width    = 3
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Not running' FROM (FROM Metric SELECT latest(state) AS 'st' WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
      }
    }

    widget_billboard {
      title  = "Hosts with critical services"
      row    = 1
      column = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_billboard {
      title  = "Services reporting"
      row    = 1
      column = 7
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(service_name) AS 'Services' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_billboard {
      title  = "Combined uptime %"
      row    = 1
      column = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv})"
      }
    }

    widget_table {
      title  = "Uptime % and current state by host and service"
      row    = 4
      column = 1
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %', latest(state) AS 'Now', latest(display_name) AS 'Display name' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name LIMIT MAX"
      }
    }

    widget_line {
      title          = "Uptime % by host and service - trend"
      row            = 4
      column         = 7
      width          = 6
      height         = 5
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE state = 'running') AS 'Uptime %' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.critical_services_scope_prod} AND service_name IN (${local.critical_services_srv}) FACET hostname, service_name TIMESERIES AUTO LIMIT MAX"
      }
    }
  }
}
