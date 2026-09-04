# SQL Server health dashboard.
# Source: nri-mssql integration (MssqlInstanceSample / MssqlDatabaseSample / MssqlWaitSample).
# Note: the integration currently reports only from UE2-SQL-A01 and MIAT-VM-SQL-001.

resource "newrelic_one_dashboard" "mssql" {
  account_id  = 1468011
  name        = "SQL Server"
  description = "Health of the SQL Server instances: connections, memory, buffer pool, waits, locks and per-database I/O."
  permissions = "public_read_write"

  page {
    name = "Overview"

    widget_billboard {
      title  = "Active connections"
      row    = 1
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(activeConnections) AS 'Connections' FROM MssqlInstanceSample FACET hostname"
      }
    }

    widget_billboard {
      title    = "Blocked processes"
      row      = 1
      column   = 4
      width    = 3
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(instance.blockedProcessesCount) AS 'Blocked' FROM MssqlInstanceSample FACET hostname"
      }
    }

    widget_billboard {
      title    = "Deadlocks / sec"
      row      = 1
      column   = 7
      width    = 3
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(stats.deadlocksPerSecond) AS 'Deadlocks/s' FROM MssqlInstanceSample FACET hostname"
      }
    }

    widget_billboard {
      title  = "Buffer pool hit %"
      row    = 1
      column = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(system.bufferPoolHitPercent) AS 'Hit %' FROM MssqlInstanceSample FACET hostname"
      }
    }

    widget_line {
      title          = "Memory utilization % by instance"
      row            = 4
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(memoryUtilization) AS 'Memory %' FROM MssqlInstanceSample FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Page life expectancy (ms)"
      row            = 4
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(bufferpool.pageLifeExpectancyInMilliseconds) AS 'PLE ms' FROM MssqlInstanceSample FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Transactions / sec"
      row            = 7
      column         = 1
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(instance.transactionsPerSecond) AS 'Tx/s' FROM MssqlInstanceSample FACET hostname TIMESERIES AUTO"
      }
    }

    widget_line {
      title          = "Lock waits / sec"
      row            = 7
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(stats.lockWaitsPerSecond) AS 'Lock waits/s' FROM MssqlInstanceSample FACET hostname TIMESERIES AUTO"
      }
    }

    widget_bar {
      title  = "Top wait types (avg ms waited per second)"
      row    = 10
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(system.waitTimeInMillisecondsPerSecond) FROM MssqlWaitSample FACET waitType LIMIT 15"
      }
    }

    widget_line {
      title          = "Wait time trend by type"
      row            = 10
      column         = 7
      width          = 6
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "SELECT average(system.waitTimeInMillisecondsPerSecond) FROM MssqlWaitSample FACET waitType TIMESERIES AUTO LIMIT 10"
      }
    }

    widget_table {
      title  = "Database I/O stalls (ms)"
      row    = 13
      column = 1
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(io.stallInMilliseconds) AS 'I/O stall ms' FROM MssqlDatabaseSample FACET hostname, displayName LIMIT MAX"
      }
    }

    widget_table {
      title  = "Buffer pool size per database (MB)"
      row    = 13
      column = 7
      width  = 6
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "SELECT latest(bufferpool.sizePerDatabaseInBytes) / 1e6 AS 'Buffer MB' FROM MssqlDatabaseSample FACET hostname, displayName LIMIT MAX"
      }
    }
  }
}
