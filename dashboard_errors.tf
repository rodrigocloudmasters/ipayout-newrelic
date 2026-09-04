# Errors and exceptions dashboard.
# Source: APM agents (TransactionError events).

resource "newrelic_one_dashboard" "errors" {
  account_id  = 1468011
  name        = "Errors & Exceptions"
  description = "Application errors by app, exception class and message, with trends."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title  = "Total errors"
      row    = 1
      column = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors' FROM TransactionError"
      }
    }

    widget_billboard {
      title  = "Apps with errors"
      row    = 1
      column = 5
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(appName) AS 'Apps' FROM TransactionError"
      }
    }

    widget_billboard {
      title    = "Overall error rate %"
      row      = 1
      column   = 9
      width    = 4
      height   = 3
      warning  = 1
      critical = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction"
      }
    }

    widget_line {
      title          = "Errors by app - trend"
      row            = 4
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM TransactionError FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_table {
      title  = "Errors by app"
      row    = 7
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Errors', latest(error.message) AS 'Last error' FROM TransactionError FACET appName LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Errors by exception class"
      row    = 7
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM TransactionError FACET error.class LIMIT 20"
      }
    }

    widget_table {
      title  = "Top error messages"
      row    = 11
      column = 1
      width  = 12
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Count' FROM TransactionError FACET appName, error.class, error.message LIMIT 25"
      }
    }
  }
}
