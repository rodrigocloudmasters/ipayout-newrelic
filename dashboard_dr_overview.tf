# Single-pane health overview for the DR environment (AWS us-east-2, UE2-*).
#
# Twin of dashboard_test_overview.tf, same shape and same reading order: the top row
# is the only part you read when nothing is wrong, and every tile below it is the
# detail behind one of those numbers.
#
# DR is not Test with different hostnames, so two things are deliberately different.
#
# The memory threshold is 90, not 85. Test sits between 50% and 91% memory and 85
# separates the tight hosts there; DR sits between 62% and 96%, where 85 would flag
# six of eleven hosts and mean nothing. 90 flags the four that are genuinely tight.
#
# The coverage section matters more here than in Test. DR is the environment nobody
# looks at until they need it, which is exactly when discovering a gap is worst: as
# of 2026-09-30 only one of thirteen DR hosts reports Windows services at all.

locals {
  # DR host scope. SystemSample, StorageSample and Metric use `hostname`;
  # Transaction and TransactionError use `host`.
  dr_ov_host = "hostname LIKE 'UE2%'"
  dr_ov_apm  = "host LIKE 'UE2%'"

  # Size of the environment, from the client host inventory: 12 Windows hosts plus
  # UE2-REDIS-A02 (Ubuntu). AWS RDS and the load balancer are excluded -- they cannot
  # run an agent, so counting them here would make the tile permanently wrong.
  dr_ov_host_count = 13

  # Thresholds set from what this fleet actually runs at, not round numbers.
  # Memory: see the header. Disk stays at 85, but read the "Free GB" column beside it:
  # 86% of a 1.3 TB volume leaves 184 GB and is fine, while 85% of a 64 GB system drive
  # leaves under 10 GB and is not.
  dr_ov_mem_pct  = 90
  dr_ov_disk_pct = 85
}

resource "newrelic_one_dashboard" "dr_overview" {
  account_id  = 1468011
  name        = "DR Environment - Health Overview"
  description = "One screen for the DR environment (UE2-*): host resources, IPS services and application health, plus the instrumentation gaps."
  permissions = "public_read_write"

  variable {
    name                 = "hostname"
    title                = "Host"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(hostname) FROM SystemSample WHERE ${local.dr_ov_host} SINCE 1 day ago LIMIT MAX"
    }
  }

  page {
    name        = "Overview"
    description = "Read the top row first. Everything below it is the detail behind one of those numbers."

    # ---- Row 1: is anything wrong right now? -----------------------------

    widget_billboard {
      title    = "Hosts reporting (of ${local.dr_ov_host_count})"
      row      = 1
      column   = 1
      width    = 2
      height   = 3
      warning  = 12
      critical = 11

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM SystemSample WHERE ${local.dr_ov_host}"
      }
    }

    widget_billboard {
      title    = "Hosts over ${local.dr_ov_mem_pct}% memory"
      row      = 1
      column   = 3
      width    = 2
      height   = 3
      warning  = 1
      critical = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Hosts' FROM (FROM SystemSample SELECT latest(memoryUsedBytes) * 100 / latest(memoryTotalBytes) AS m WHERE ${local.dr_ov_host} FACET hostname LIMIT MAX) WHERE m > ${local.dr_ov_mem_pct}"
      }
    }

    widget_billboard {
      title    = "Hosts over ${local.dr_ov_disk_pct}% disk"
      row      = 1
      column   = 5
      width    = 2
      height   = 3
      warning  = 1
      critical = 2

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(hostname) AS 'Hosts' FROM (FROM StorageSample SELECT latest(diskUsedPercent) AS d, latest(hostname) AS hostname WHERE ${local.dr_ov_host} FACET hostname, mountPoint LIMIT MAX) WHERE d > ${local.dr_ov_disk_pct}"
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
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS st WHERE metricName = 'windows_service_state' AND ${local.dr_ov_host} AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running'"
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
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.dr_ov_apm}"
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
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.dr_ov_apm}"
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
        query      = "SELECT latest(cpuPercent) AS 'CPU %', latest(memoryUsedBytes) * 100 / latest(memoryTotalBytes) AS 'Memory %', latest(uptime) / 86400 AS 'Uptime days', latest(agentVersion) AS 'Agent' FROM SystemSample WHERE ${local.dr_ov_host} AND hostname IN ({{hostname}}) FACET hostname LIMIT MAX"
      }
    }

    # Free GB sits next to Used % on purpose: the percentage alone cannot tell a
    # 1.3 TB data volume at 86% from a 64 GB system drive at the same figure.
    widget_table {
      title  = "Disk by volume"
      row    = 5
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(diskUsedPercent) AS 'Used %', latest(diskFreeBytes) / 1e9 AS 'Free GB', latest(diskTotalBytes) / 1e9 AS 'Total GB' FROM StorageSample WHERE ${local.dr_ov_host} AND hostname IN ({{hostname}}) FACET hostname, mountPoint LIMIT MAX"
      }
    }

    widget_line {
      title          = "Memory % - trend"
      row            = 9
      column         = 1
      width          = 4
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryUsedBytes) * 100 / average(memoryTotalBytes) AS 'Memory %' FROM SystemSample WHERE ${local.dr_ov_host} AND hostname IN ({{hostname}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "CPU % - trend"
      row            = 9
      column         = 5
      width          = 4
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(cpuPercent) AS 'CPU %' FROM SystemSample WHERE ${local.dr_ov_host} AND hostname IN ({{hostname}}) FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Disk % - trend by volume"
      row            = 9
      column         = 9
      width          = 4
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(diskUsedPercent) AS 'Disk %' FROM StorageSample WHERE ${local.dr_ov_host} AND hostname IN ({{hostname}}) FACET hostname, mountPoint TIMESERIES AUTO LIMIT MAX"
      }
    }

    # ---- IPS services ----------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 12
      column = 1
      width  = 12
      height = 1
      text   = "# IPS services"
    }

    widget_table {
      title  = "Which IPS services are stopped"
      row    = 13
      column = 1
      width  = 8
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(disp) AS 'Service', latest(sm) AS 'Start mode' FROM (FROM Metric SELECT latest(state) AS st, latest(start_mode) AS sm, latest(display_name) AS disp WHERE metricName = 'windows_service_state' AND ${local.dr_ov_host} AND hostname IN ({{hostname}}) AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running' FACET hostname AS 'Host', service_name AS 'Service name' LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Stopped IPS services per host"
      row    = 13
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) AS 'Stopped' FROM (FROM Metric SELECT latest(state) AS st WHERE metricName = 'windows_service_state' AND ${local.dr_ov_host} AND hostname IN ({{hostname}}) AND service_name LIKE 'ips%' FACET hostname, service_name LIMIT MAX) WHERE st != 'running' FACET hostname"
      }
    }

    # ---- Applications ----------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 16
      column = 1
      width  = 12
      height = 1
      text   = "# Applications"
    }

    widget_table {
      title  = "Application health"
      row    = 17
      column = 1
      width  = 12
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT rate(count(*), 1 minute) AS 'Tx/min', average(duration * 1000) AS 'Avg ms', percentile(duration * 1000, 95) AS 'p95 ms', percentage(count(*), WHERE error IS true) AS 'Error %', uniqueCount(host) AS 'Hosts' FROM Transaction WHERE ${local.dr_ov_apm} FACET appName LIMIT MAX"
      }
    }

    widget_line {
      title          = "Error rate % by application"
      row            = 21
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Error %' FROM Transaction WHERE ${local.dr_ov_apm} FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    widget_line {
      title          = "Response time by application (ms)"
      row            = 21
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(duration * 1000) AS 'Avg ms' FROM Transaction WHERE ${local.dr_ov_apm} FACET appName TIMESERIES AUTO LIMIT 20"
      }
    }

    # ---- Coverage --------------------------------------------------------

    widget_markdown {
      title  = ""
      row    = 24
      column = 1
      width  = 12
      height = 1
      text   = "# Instrumentation coverage"
    }

    # Says what to do, not what the numbers are. The Test version of this widget once
    # listed the hosts that were not reporting; four came back the next day and the
    # text sat there wrong for days. Counts belong in the tiles, which read the data.
    widget_markdown {
      title  = ""
      row    = 25
      column = 1
      width  = 5
      height = 4
      text   = <<-EOT
        ### Reading the coverage tiles

        DR is the environment nobody looks at until they need it, so a gap here is
        found at the worst possible moment. Each tile compares against the known
        size of the environment rather than against whatever happened to report.

        - **Windows services per host** - blank rows are hosts without
          nri-winservices. Without it there is no way to tell whether a service is
          running, which on the domain controllers means no view of DNS or netlogon.
        - **Applications per host (APM)** - a host with IIS and no row here is
          serving traffic uninstrumented.

        A host missing from *both* tables but present in Host health above has only
        the base agent. A host missing from Host health as well is not reporting at
        all: check the agent service before assuming the machine is down.
      EOT
    }

    widget_table {
      title  = "Windows services monitored per host"
      row    = 25
      column = 6
      width  = 3
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(service_name) AS 'Services' FROM Metric WHERE metricName = 'windows_service_state' AND ${local.dr_ov_host} FACET hostname LIMIT MAX"
      }
    }

    widget_table {
      title  = "Applications per host (APM)"
      row    = 25
      column = 9
      width  = 4
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT uniqueCount(appName) AS 'Apps', rate(count(*), 1 minute) AS 'Tx/min' FROM Transaction WHERE ${local.dr_ov_apm} FACET host LIMIT MAX"
      }
    }
  }
}
