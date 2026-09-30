# Windows Services dashboard for the DR environment (UE2-*).
# Twin of dashboard_windows_test.tf, with its host scope pinned the same way.
#
# One deliberate difference: there is no hardcoded service list here. The Test twin
# still carries `windows_test_services`, copied from an old alert condition, and that
# list has drifted from the real service names -- it says `ripplepaymentsservice`
# while production runs `ipsripplepaymentsservice`, and it omits
# `ips_emailreceiverwindowsservice` and `ips_bai2reportsservice` entirely, so its
# "not running" tile undercounts. Every widget below matches by pattern instead, which
# removes that whole class of bug and covers a newly deployed service the day it ships.
#
# Windows are tuned to the 400s scrape, exactly as in Test: variables use 1 day
# (3+ day windows on Metric read rollups that lag hours behind, so a freshly onboarded
# host returns nothing, the variable falls back to "*" and every widget renders 0) and
# the state-transition widgets use 15 minutes (5 is shorter than the sampling interval
# and would almost always be empty).
#
# Coverage as of 2026-09-30: only UE2-SMTP-A01 reports windows_service_state. The other
# twelve DR hosts need scripts/Enable-NriWinservices.ps1, so this dashboard is mostly
# empty until that rollout happens -- which is itself the thing worth seeing.

locals {
  # DR host scope injected into every query
  windows_dr_scope = "hostname LIKE 'UE2%'"

  # Critical services: what must be running for the platform to work. Matched by
  # pattern, never by an explicit list. Extend the IN (...) part as tiers are added.
  windows_dr_critical = "(service_name LIKE 'ips%' OR service_name LIKE '%ripplepayments%' OR service_name IN ('w3svc', 'mssqlserver', 'sqlserveragent', 'newrelic-infra', 'dns', 'netlogon', 'ntds'))"
}

resource "newrelic_one_dashboard" "windows_services_dr" {
  account_id  = 1468011
  name        = "Windows Services - DR Environment"
  description = "Windows services running on the DR hosts (UE2-*). Mirror of the Test Windows Services dashboard."
  permissions = "public_read_write"

  variable {
    name                 = "hostname"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(hostname) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "service_name"
    title                = "Service name"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(service_name) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "display_name"
    title                = "Display name"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(display_name) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "state"
    title                = "State"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(state) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "start"
    title                = "Start Mode"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(start_mode) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  page {
    name        = "Windows Services - Overview"
    description = "Windows Services data of the DR environment by host, state, start_mode, name, and display name"

    widget_markdown {
      title  = ""
      row    = 1
      column = 1
      width  = 12
      height = 1
      text   = "# Summary"
    }

    widget_billboard {
      title  = "Hosts reporting services"
      row    = 2
      column = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(hostname) AS 'Hosts' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} COMPARE WITH 1 hour ago"
      }
    }

    widget_billboard {
      title    = "IPS services not running"
      row      = 2
      column   = 5
      width    = 4
      height   = 3
      warning  = 1
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS st WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
      }
    }

    widget_billboard {
      title  = "Services per state"
      row    = 2
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET hostname, service_name LIMIT MAX) FACET state"
      }
    }

    widget_markdown {
      title  = ""
      row    = 5
      column = 1
      width  = 12
      height = 1
      text   = "# Critical services"
    }

    widget_billboard {
      title    = "Critical services stopped"
      row      = 6
      column   = 1
      width    = 4
      height   = 3
      warning  = 1
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS 'st' WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND ${local.windows_dr_critical} FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
      }
    }

    widget_table {
      title  = "Which critical services are stopped"
      row    = 6
      column = 5
      width  = 8
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(display_name) AS 'Service', latest(st) AS 'State', latest(sm) AS 'Start mode' FROM (FROM Metric SELECT latest(state) AS 'st', latest(start_mode) AS 'sm', latest(display_name) AS 'display_name' WHERE metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND ${local.windows_dr_critical} FACET hostname, service_name LIMIT MAX) WHERE st != 'running' FACET hostname AS 'Host', service_name AS 'Service name' LIMIT MAX"
      }
    }

    widget_markdown {
      title  = ""
      row    = 9
      column = 1
      width  = 12
      height = 1
      text   = "# Per host"
    }

    widget_bar {
      title  = "Services running per host"
      row    = 10
      column = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET hostname, service_name LIMIT MAX) WHERE state = 'running' FACET hostname"
      }
    }

    widget_bar {
      title  = "Services stopped per host"
      row    = 10
      column = 5
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET hostname, service_name LIMIT MAX) WHERE state = 'stopped' FACET hostname"
      }
    }

    widget_bar {
      title  = "Services paused per host"
      row    = 10
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET hostname, service_name LIMIT MAX) WHERE state = 'paused' FACET hostname"
      }
    }

    widget_line {
      title          = "Services running per host - trend"
      row            = 13
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND state = 'running' FACET hostname TIMESERIES AUTO LIMIT MAX"
      }
    }

    widget_line {
      title          = "Services stopped per host - trend"
      row            = 13
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND state = 'stopped' FACET hostname TIMESERIES AUTO LIMIT MAX"
      }
    }

    widget_markdown {
      title  = ""
      row    = 16
      column = 1
      width  = 12
      height = 1
      text   = "# Inventory and transitions"
    }

    widget_table {
      title  = "Services"
      row    = 17
      column = 1
      width  = 12
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(substring(display_name, 0, 40)) AS 'Display Name', latest(state), latest(start_mode) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET hostname AS 'Host Name', service_name LIMIT MAX"
      }
    }

    widget_table {
      title  = "Stopped last 15 minutes"
      row    = 21
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND state = 'stopped' AND entity.guid IN (SELECT uniques(entity.guid, 10000) FROM Metric WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND state IN ('running', 'paused') SINCE 2 hours ago UNTIL 15 minutes ago LIMIT MAX) FACET hostname, service_name SINCE 15 minutes ago LIMIT MAX"
      }
    }

    widget_table {
      title  = "Started last 15 minutes"
      row    = 21
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND state = 'running' AND entity.guid IN (SELECT uniques(entity.guid, 10000) FROM Metric WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND state IN ('stopped', 'paused') SINCE 2 hours ago UNTIL 15 minutes ago LIMIT MAX) FACET hostname, service_name SINCE 15 minutes ago LIMIT MAX"
      }
    }

    widget_markdown {
      title  = ""
      row    = 24
      column = 1
      width  = 12
      height = 1
      text   = "# Breakdown"
    }

    widget_bar {
      title  = "Per service account"
      row    = 25
      column = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND run_as IS NOT NULL FACET run_as AS 'Service Account' LIMIT MAX"
      }
    }

    widget_pie {
      title  = "Start Mode"
      row    = 25
      column = 5
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} FACET start_mode LIMIT MAX"
      }
    }

    widget_table {
      title  = "State different from running, stopped or paused"
      row    = 25
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name), latest(state) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_dr_scope} AND state NOT IN ('running', 'stopped', 'paused') FACET hostname, service_name LIMIT MAX"
      }
    }
  }
}
