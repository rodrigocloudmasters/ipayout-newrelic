# APM dashboard for the Test environment.
# Scoped to the UE1-TEST-* hosts, the counterpart of "APM - Application Health"
# (dashboard_apm.tf), which is account-wide and therefore dominated by production traffic.
#
# Coverage note: only UE1-TEST-API-A1 and UE1-TEST-API-B1 send Transaction events today.
# UE1-TEST-WEB-A1 runs IIS but has no .NET agent, and UE1-TEST-WEB-B1 has no agent at all,
# so the "Hosts reporting APM" billboard doubles as the rollout tracker: it reads 2 until
# the agent is installed on the two web hosts.

locals {
  # Test host scope injected into every query on this dashboard
  apm_test_scope = "host LIKE 'UE1-TEST%'"
}

resource "newrelic_one_dashboard" "apm_test" {
  account_id  = 1468011
  name        = "APM - Test Environment"
  description = "Throughput, response time and errors for the applications running on the Test hosts (UE1-TEST-*)."
  permissions = "public_read_write"

  variable {
    name                 = "app"
    title                = "Application"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(appName) FROM Transaction WHERE ${local.apm_test_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  variable {
    name                 = "host"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(host) FROM Transaction WHERE ${local.apm_test_scope} SINCE 1 day ago LIMIT MAX"
    }
  }

  page {
    name        = "Overview"
    description = "Golden signals for the Test applications, faceted by host and by application."

    # ---- KPI strip -------------------------------------------------------

    widget_billboard {
      title  = "Throughput (tx/min)"
      row    = 1
      column = 1
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
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
        query      = "SELECT average(duration * 1000) AS 'ms' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
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
        query      = "SELECT percentile(duration * 1000, 95) AS 'ms' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
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
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
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
        query      = "SELECT uniqueCount(appName) AS 'Apps' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}})"
      }
    }

    # Rollout tracker: reads 2 until the .NET agent reaches the two web hosts.
    widget_billboard {
      title  = "Hosts reporting APM (of 4)"
      row    = 1
      column = 11
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.apm_test_scope}"
      }
    }

    # ---- Golden signals over time ---------------------------------------

    widget_markdown {
      title  = ""
      row    = 4
      column = 1
      width  = 12
      height = 1
      text   = "# Trends"
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
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET host TIMESERIES AUTO"
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
        query      = "SELECT average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET host TIMESERIES AUTO"
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
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
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
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
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
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min', average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', percentage(count(*), WHERE error IS true) AS 'Error %', uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT MAX"
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
        query      = "SELECT percentile(duration * 1000, 95) AS 'p95 ms' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT 15"
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
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName LIMIT 15"
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
        query      = "SELECT average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', count(*) AS 'Calls' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, name LIMIT 20"
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
        query      = "SELECT count(*) AS 'Calls', average(duration * 1000) AS 'Avg ms' FROM Transaction WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, name LIMIT 20"
      }
    }

    widget_table {
      title  = "Top errors"
      row    = 24
      column = 1
      width  = 12
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors', latest(error.message) AS 'Last message' FROM TransactionError WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName, error.class LIMIT 25"
      }
    }

    widget_line {
      title          = "Errors over time by application"
      row            = 28
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors' FROM TransactionError WHERE ${local.apm_test_scope} AND appName IN ({{app}}) AND host IN ({{host}}) FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }
  }
}
