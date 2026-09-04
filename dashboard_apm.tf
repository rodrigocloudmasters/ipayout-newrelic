# APM application health dashboard: golden signals per .NET app.
# Source: APM agents (Transaction events).

resource "newrelic_one_dashboard" "apm_health" {
  account_id  = 1468011
  name        = "APM - Application Health"
  description = "Throughput, response time, error rate and slowest transactions for every instrumented application."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title  = "Throughput (tx/min)"
      row    = 1
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction"
      }
    }

    widget_billboard {
      title  = "Avg response time (ms)"
      row    = 1
      column = 4
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'ms' FROM Transaction"
      }
    }

    widget_billboard {
      title  = "p95 response time (ms)"
      row    = 1
      column = 7
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentile(duration * 1000, 95) FROM Transaction"
      }
    }

    widget_billboard {
      title    = "Error rate %"
      row      = 1
      column   = 10
      width    = 3
      height   = 3
      warning  = 1
      critical = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction"
      }
    }

    widget_line {
      title          = "Throughput by app (tx/min)"
      row            = 4
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) FROM Transaction FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Avg response time by app (ms)"
      row            = 4
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) FROM Transaction FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Error rate % by app"
      row            = 7
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) FROM Transaction FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_table {
      title  = "Applications overview"
      row    = 10
      column = 1
      width  = 12
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min', average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction FACET appName LIMIT MAX"
      }
    }

    widget_table {
      title  = "Slowest transactions (avg)"
      row    = 15
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'Avg ms', count(*) AS 'Calls' FROM Transaction FACET appName, name LIMIT 20"
      }
    }

    widget_table {
      title  = "Most called transactions"
      row    = 15
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Calls', average(duration * 1000) AS 'Avg ms' FROM Transaction FACET appName, name LIMIT 20"
      }
    }
  }
}
