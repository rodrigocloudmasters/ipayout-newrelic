# Per-process resource usage dashboard: which process consumes CPU/memory on each host.
# Source: Infrastructure agent (ProcessSample).

resource "newrelic_one_dashboard" "host_processes" {
  account_id  = 1468011
  name        = "Host Processes"
  description = "Top CPU and memory consuming processes per host. Complements the Infrastructure - Hosts dashboard."
  permissions = "public_read_write"

  variable {
    name                 = "host"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(hostname) FROM ProcessSample SINCE 1 week ago LIMIT MAX"
    }
  }

  page {
    name = "Overview"

    widget_table {
      title  = "Top CPU processes"
      row    = 1
      column = 1
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(cpuPercent) AS 'CPU %' FROM ProcessSample WHERE hostname IN ({{host}}) FACET hostname, processDisplayName LIMIT 25"
      }
    }

    widget_table {
      title  = "Top memory processes (MB)"
      row    = 1
      column = 7
      width  = 6
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryResidentSizeBytes) / 1e6 AS 'Memory MB' FROM ProcessSample WHERE hostname IN ({{host}}) FACET hostname, processDisplayName LIMIT 25"
      }
    }

    widget_line {
      title          = "CPU by process - trend"
      row            = 6
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(cpuPercent) FROM ProcessSample WHERE hostname IN ({{host}}) FACET processDisplayName TIMESERIES AUTO LIMIT 10"
      }
    }

    widget_line {
      title          = "Memory by process - trend (MB)"
      row            = 6
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryResidentSizeBytes) / 1e6 FROM ProcessSample WHERE hostname IN ({{host}}) FACET processDisplayName TIMESERIES AUTO LIMIT 10"
      }
    }
  }
}
