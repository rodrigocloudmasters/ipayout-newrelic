# APM dashboard for the DR environment.
# Scoped to the UE2-* hosts, the counterpart of "APM - Application Health"
# (dashboard_apm.tf), which is account-wide and therefore dominated by production.
#
# Coverage note: all six application hosts report -- UE2-API-A01/A02/B01 and
# UE2-WEB-A01/A02/B01. The other DR hosts (domain controllers, SQL, SMTP, Redis) run
# no instrumented application, so the tile counts against six rather than thirteen.
#
# The application list mixes two kinds of name. Some are the production applications
# running in DR under their own names (SuperNova, CommissionNetworks.com,
# ManagementConsole); others are prefixed drtest* and exist only here. Both are kept:
# filtering the drtest* ones out would hide whether the DR rehearsal traffic works.

locals {
  # DR host scope injected into every query on this dashboard
  apm_dr_scope = "host LIKE 'UE2%'"

  # Application hosts in the DR inventory: 3 WEB + 3 API.
  apm_dr_host_count = 6
}

resource "newrelic_one_dashboard" "apm_dr" {
  account_id  = 1468011
  name        = "APM - DR Environment"
  description = "Throughput, response time and errors for the applications running on the DR hosts (UE2-*)."
  permissions = "public_read_write"

  variable {
    name                 = "app"
    title                = "Application"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(appName) FROM Transaction WHERE ${local.apm_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "host"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(host) FROM Transaction WHERE ${local.apm_dr_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  page {
    name        = "Overview"
    description = "Golden signals for the DR applications, faceted by host and by application."

    # ---- KPI strip -------------------------------------------------------

    widget_billboard {
      title  = "Throughput (tx/min)"
      row    = 1
      column = 1
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    widget_billboard {
      title  = "Avg response time (ms)"
      row    = 1
      column = 3
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'ms' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    widget_billboard {
      title  = "p95 response time (ms)"
      row    = 1
      column = 5
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentile(duration * 1000, 95) AS 'ms' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    widget_billboard {
      title    = "Error rate %"
      row      = 1
      column   = 7
      width    = 2
      height   = 3
      warning  = 1
      critical = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    widget_billboard {
      title  = "Applications"
      row    = 1
      column = 9
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(appName) AS 'Apps' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    # Unfiltered on purpose: this tile answers "is every application host
    # instrumented", which a host filter would hide.
    widget_billboard {
      title    = "Hosts reporting APM (of ${local.apm_dr_host_count})"
      row      = 1
      column   = 11
      width    = 2
      height   = 3
      warning  = 5
      critical = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.apm_dr_scope}"
      }
    }

    # ---- Golden signals over time ---------------------------------------

    widget_markdown {
      title  = ""
      row    = 4
      column = 1
      width  = 12
      height = 1
      text   = "# Golden signals"
    }

    widget_line {
      title          = "Throughput by host (tx/min)"
      row            = 5
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET host TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Response time by host (ms)"
      row            = 5
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET host TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Throughput by application (tx/min)"
      row            = 8
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Error rate % by application"
      row            = 8
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    # ---- Per-application detail -----------------------------------------

    widget_markdown {
      title  = ""
      row    = 11
      column = 1
      width  = 12
      height = 1
      text   = "# Applications"
    }

    widget_table {
      title  = "Applications overview"
      row    = 12
      column = 1
      width  = 12
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min', average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', percentage(count(*), WHERE error IS true) AS 'Error %', uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Slowest applications (p95 ms)"
      row    = 16
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentile(duration * 1000, 95) AS 'p95 ms' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT 15"
      }
    }

    widget_bar {
      title  = "Highest error rate (%)"
      row    = 16
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT 15"
      }
    }

    # ---- Transactions and errors ----------------------------------------

    widget_markdown {
      title  = ""
      row    = 19
      column = 1
      width  = 12
      height = 1
      text   = "# Transactions and errors"
    }

    widget_table {
      title  = "Slowest transactions (avg)"
      row    = 20
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', count(*) AS 'Calls' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, name LIMIT 20"
      }
    }

    widget_table {
      title  = "Most called transactions"
      row    = 20
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Calls', average(duration * 1000) AS 'Avg ms' FROM Transaction WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, name LIMIT 20"
      }
    }

    widget_table {
      title  = "Top errors"
      row    = 24
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors', latest(error.message) AS 'Last message' FROM TransactionError WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, error.class LIMIT 25"
      }
    }

    widget_line {
      title          = "Errors over time by application"
      row            = 24
      column         = 7
      width          = 6
      height         = 4
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors' FROM TransactionError WHERE ${local.apm_dr_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }
  }
}
