# Web availability dashboard fed by the synthetic monitors (SyntheticCheck events).

resource "newrelic_one_dashboard" "web_availability" {
  account_id  = 1468011
  name        = "Web Availability (Synthetics)"
  description = "Uptime and response time for every monitored site. Fed by synthetic ping checks."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title  = "Sites monitored"
      row    = 1
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(monitorName) AS 'Sites' FROM SyntheticCheck SINCE 1 day ago"
      }
    }

    widget_billboard {
      title    = "Sites failing (last 30 min)"
      row      = 1
      column   = 4
      width    = 3
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(monitorName) AS 'Failing' FROM SyntheticCheck WHERE result != 'SUCCESS' SINCE 30 minutes ago"
      }
    }

    widget_billboard {
      title  = "Overall uptime % (24 h)"
      row    = 1
      column = 7
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE result = 'SUCCESS') AS 'Uptime %' FROM SyntheticCheck SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "Avg response time ms (24 h)"
      row    = 1
      column = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration) AS 'ms' FROM SyntheticCheck SINCE 1 day ago"
      }
    }

    widget_table {
      title  = "Uptime and response time by site (24 h)"
      row    = 4
      column = 1
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE result = 'SUCCESS') AS 'Uptime %', average(duration) AS 'Avg ms', max(duration) AS 'Max ms' FROM SyntheticCheck FACET monitorName SINCE 1 day ago LIMIT MAX"
      }
    }

    widget_table {
      title  = "Failures by site (24 h)"
      row    = 4
      column = 7
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Failed checks', latest(error) AS 'Last error' FROM SyntheticCheck WHERE result != 'SUCCESS' FACET monitorName SINCE 1 day ago LIMIT MAX"
      }
    }

    widget_line {
      title          = "Response time - trend (20 slowest sites)"
      row            = 9
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration) AS 'ms' FROM SyntheticCheck FACET monitorName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Failed checks - trend"
      row            = 12
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT filter(count(*), WHERE result != 'SUCCESS') AS 'Failed checks' FROM SyntheticCheck TIMESERIES AUTO"
      }
    }
  }
}
