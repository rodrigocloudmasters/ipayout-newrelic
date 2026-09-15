# Single-pane health overview for the Test environment.
#
# The other two Test dashboards each answer one question well -- "Windows Services -
# Test Environment" covers services, "APM - Test Environment" covers applications --
# but neither answers "is Test healthy right now?", which needs all three data sources
# at once. This one leads with that: the top row is the only part you read when nothing
# is wrong, and every tile below it is the detail behind one of those numbers.
#
# It also tracks its own blind spot. Five of the eleven Test hosts send nothing at all
# (both domain controllers, both SQL 2025 hosts, and the Ubuntu Redis host), so a
# dashboard that only showed the six that report would look complete while missing
# almost half the environment. The "Hosts reporting" tile reads 6 of 11 until that
# changes, and the Coverage section names what is missing.

locals {
  # Test host scope. SystemSample, StorageSample and Metric use `hostname`;
  # Transaction and TransactionError use `host`.
  test_ov_host = "hostname LIKE 'UE1-TEST%'"
  test_ov_apm  = "host LIKE 'UE1-TEST%'"

  # Thresholds that mark a host as needing attention. Set from what the fleet actually
  # runs at: the six reporting hosts sit between 62% and 91% memory, so 85 flags the
  # genuinely tight ones without lighting up on normal Windows behaviour.
  test_ov_mem_pct  = 85
  test_ov_disk_pct = 85
}

resource "newrelic_one_dashboard" "test_overview" {
  account_id  = 1468011
  name        = "Test Environment - Health Overview"
  description = "One screen for the Test environment: host resources, IPS services and application health, plus the instrumentation gaps."
  permissions = "public_read_write"

  variable {
    name                 = "hostname"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(hostname) FROM SystemSample WHERE ${local.test_ov_host} SINCE 1 day ago LIMIT MAX"
    }
  }

  page {
    name        = "Overview"
    description = "Read the top row first. Everything below it is the detail behind one of those numbers."

    # ---- Row 1: is anything wrong right now? -----------------------------

    widget_billboard {
      title  = "Hosts reporting (of 11)"
      row    = 1
      column = 1
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM SystemSample WHERE ${local.test_ov_host}"
      }
    }

    widget_billboard {
      title    = "Hosts over ${local.test_ov_mem_pct}% memory"
      row      = 1
      column   = 3
      width    = 2
      height   = 3
      warning  = 1
      critical = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Hosts' FROM (FROM SystemSample SELECT latest(memoryUsedBytes) * 100 / latest(memoryTotalBytes) AS m WHERE ${local.test_ov_host} FACET hostname LIMIT MAX) WHERE m > ${local.test_ov_mem_pct}"
      }
    }

    widget_billboard {
      title    = "Hosts over ${local.test_ov_disk_pct}% disk"
      row      = 1
      column   = 5
      width    = 2
      height   = 3
      warning  = 1
      critical = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM (FROM StorageSample SELECT latest(diskUsedPercent) AS d, latest(hostname) AS hostname WHERE ${local.test_ov_host} FACET hostname, mountPoint LIMIT MAX) WHERE d > ${local.test_ov_disk_pct}"
      }
    }

    # Matched by pattern, not by a fixed list: the hardcoded IPS service list in
    # dashboard_windows_test.tf has already drifted from the real service names.
    widget_billboard {
      title    = "IPS services stopped"
      row      = 1
      column   = 7
      width    = 2
      height   = 3
      warning  = 1
      critical = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS st WHERE metricName = 'windows_service_state' AND ${local.test_ov_host} AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
      }
    }

    widget_billboard {
      title    = "Application error rate"
      row      = 1
      column   = 9
      width    = 2
      height   = 3
      warning  = 1
      critical = 5

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.test_ov_apm}"
      }
    }

    widget_billboard {
      title  = "Throughput (tx/min)"
      row    = 1
      column = 11
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.test_ov_apm}"
      }
    }

    # ---- Host resources --------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 4
      column = 1
      width  = 12
      height = 1
      text   = "# Host resources"
    }

    widget_table {
      title  = "Host health"
      row    = 5
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(cpuPercent) AS 'CPU %', latest(memoryUsedBytes) * 100 / latest(memoryTotalBytes) AS 'Memory %', latest(uptime) / 86400 AS 'Uptime days', latest(agentVersion) AS 'Agent' FROM SystemSample WHERE ${local.test_ov_host} AND hostname IN ({{hostname}}) FACET hostname LIMIT MAX"
      }
    }

    widget_table {
      title  = "Disk by volume"
      row    = 5
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(diskUsedPercent) AS 'Used %', latest(diskFreeBytes) / 1e9 AS 'Free GB', latest(diskTotalBytes) / 1e9 AS 'Total GB' FROM StorageSample WHERE ${local.test_ov_host} AND hostname IN ({{hostname}}) FACET hostname, mountPoint LIMIT MAX"
      }
    }

    widget_line {
      title          = "Memory % - trend"
      row            = 9
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryUsedBytes) * 100 / average(memoryTotalBytes) AS 'Memory %' FROM SystemSample WHERE ${local.test_ov_host} AND hostname IN ({{hostname}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "CPU % - trend"
      row            = 9
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(cpuPercent) AS 'CPU %' FROM SystemSample WHERE ${local.test_ov_host} AND hostname IN ({{hostname}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Disk % - trend by volume"
      row            = 12
      column         = 1
      width          = 12
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(diskUsedPercent) AS 'Disk %' FROM StorageSample WHERE ${local.test_ov_host} AND hostname IN ({{hostname}}) FACET hostname, mountPoint TIMESERIES AUTO LIMIT MAX"
      }
    }

    # ---- IPS services ----------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 15
      column = 1
      width  = 12
      height = 1
      text   = "# IPS services"
    }

    widget_table {
      title  = "Which IPS services are stopped"
      row    = 16
      column = 1
      width  = 8
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(disp) AS 'Service', latest(sm) AS 'Start mode' FROM (FROM Metric SELECT latest(state) AS st, latest(start_mode) AS sm, latest(display_name) AS disp WHERE metricName = 'windows_service_state' AND ${local.test_ov_host} AND hostname IN ({{hostname}}) AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running' FACET hostname AS 'Host', service_name AS 'Service name' LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Stopped IPS services per host"
      row    = 16
      column = 9
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS st WHERE metricName = 'windows_service_state' AND ${local.test_ov_host} AND hostname IN ({{hostname}}) AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running' FACET hostname"
      }
    }

    # ---- Applications ----------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 20
      column = 1
      width  = 12
      height = 1
      text   = "# Applications"
    }

    widget_table {
      title  = "Application health"
      row    = 21
      column = 1
      width  = 12
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min', average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', percentage(count(*), WHERE error IS true) AS 'Error %', uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.test_ov_apm} FACET appName LIMIT MAX"
      }
    }

    widget_line {
      title          = "Error rate % by application"
      row            = 25
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.test_ov_apm} FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Response time by application (ms)"
      row            = 25
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'Avg ms' FROM Transaction WHERE ${local.test_ov_apm} FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    # ---- Coverage --------------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 28
      column = 1
      width  = 12
      height = 1
      text   = "# Instrumentation coverage"
    }

    widget_markdown {
      title  = ""
      row    = 29
      column = 1
      width  = 5
      height = 4
      text   = <<-EOT
        ### Not reporting

        Five of the eleven Test hosts send no data at all. They could not reach
        `download.newrelic.com` and need the proxy at `10.24.70.241:3128`:

        - `UE1-TEST-ADC-A2` — domain controller
        - `UE1-TEST-ADC-B2` — domain controller
        - `UE1-TEST-SQL-A2` — SQL Server 2025
        - `UE1-TEST-SQL-B2` — SQL Server 2025
        - `UE1-TEST-REDIS-A1` — Ubuntu, needs the Linux agent instead

        The two SQL hosts will also need the `nri-mssql` integration once the
        infrastructure agent is on them.
      EOT
    }

    widget_table {
      title  = "Windows services monitored per host"
      row    = 29
      column = 6
      width  = 3
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(service_name) AS 'Services' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.test_ov_host} FACET hostname LIMIT MAX"
      }
    }

    widget_table {
      title  = "Applications per host (APM)"
      row    = 29
      column = 9
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(appName) AS 'Apps', rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.test_ov_apm} FACET host LIMIT MAX"
      }
    }
  }
}
