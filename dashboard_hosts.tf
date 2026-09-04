# Infrastructure dashboard: CPU, memory and disk per host.
# Source: Infrastructure agent (SystemSample / StorageSample).

resource "newrelic_one_dashboard" "infra_hosts" {
  account_id  = 1468011
  name        = "Infrastructure - Hosts (CPU, Memory, Disk)"
  description = "CPU, memory and disk usage for every monitored host. Use the Host selector to filter servers."
  permissions = "public_read_write"

  variable {
    name                 = "host"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(hostname) FROM SystemSample SINCE 1 week ago LIMIT MAX"
    }
  }

  page {
    name = "Overview"

    widget_table {
      title  = "Current CPU % by host"
      row    = 1
      column = 1
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(cpuPercent) AS 'CPU %' FROM SystemSample WHERE hostname IN ({{host}}) FACET hostname LIMIT MAX"
      }
    }

    widget_table {
      title  = "Current memory % by host"
      row    = 1
      column = 5
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(memoryUsedBytes) * 100 / latest(memoryTotalBytes) AS 'Memory %' FROM SystemSample WHERE hostname IN ({{host}}) FACET hostname LIMIT MAX"
      }
    }

    widget_table {
      title  = "Current disk usage % by host and drive"
      row    = 1
      column = 9
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(diskUsedPercent) AS 'Disk %' FROM StorageSample WHERE hostname IN ({{host}}) FACET hostname, mountPoint LIMIT MAX"
      }
    }

    widget_line {
      title          = "CPU % - trend"
      row            = 5
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(cpuPercent) AS 'CPU %' FROM SystemSample WHERE hostname IN ({{host}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Memory % - trend"
      row            = 5
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryUsedBytes) * 100 / average(memoryTotalBytes) AS 'Memory %' FROM SystemSample WHERE hostname IN ({{host}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Disk usage % - trend by host and drive"
      row            = 8
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(diskUsedPercent) AS 'Disk %' FROM StorageSample WHERE hostname IN ({{host}}) FACET hostname, mountPoint TIMESERIES AUTO LIMIT MAX"
      }
    }
  }
}
