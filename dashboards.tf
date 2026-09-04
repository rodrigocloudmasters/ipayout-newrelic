# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE4MjA"
resource "newrelic_one_dashboard" "database_performance" {
  account_id  = 1468011
  description = null
  name        = "Database Performance"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Database Performance"
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 6
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Accumulated DB Time by Trans."
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(databaseDuration) FROM Transaction FACET name SINCE 1 day ago LIMIT 20"
      }
    }
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 7
      title                    = "Transaction Time (DB inclusive)"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(duration) FROM Transaction FACET name SINCE 1 day ago LIMIT 7"
      }
    }
    widget_heatmap {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 10
      title                    = "Accumulated DB Time by Histogram"
      width                    = 12
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT histogram(databaseDuration) FROM Transaction FACET name SINCE 1 day ago LIMIT 20"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 6
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Worst DB offenders"
      width                    = 8
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(databaseDuration) as 'Time', count(*) as 'Count', percentile(databaseDuration, 99, 80, 50) as 'DB' FROM Transaction FACET name SINCE 1 day ago LIMIT 15"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 7
      title                    = "Worst App offenders"
      width                    = 8
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(duration) as 'App', count(*) as 'Count', percentile(duration, 99, 80, 50) as 'App' FROM Transaction FACET name SINCE 1 day ago LIMIT 5"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE3ODE"
resource "newrelic_one_dashboard" "transactions_analysis" {
  account_id  = 1468011
  description = null
  name        = "Transactions Analysis"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Transactions Analysis"
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "HTTP Response Codes"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction FACET httpResponseCode SINCE 1 day ago"
      }
    }
    widget_billboard {
      column                  = 9
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "% of Transactions w/ 5xx Errors"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE httpResponseCode LIKE '5%') FROM Transaction SINCE 1 day ago"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "5xx Errors over Time"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE httpResponseCode LIKE '5%') FROM Transaction SINCE 1 day ago TIMESERIES AUTO"
      }
    }
    widget_pie {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Trans Names w/ 5xx Errors"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction FACET name WHERE httpResponseCode LIKE '5%' SINCE 1 day ago"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "Recent 5xx Error Transactions"
      width                    = 12
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT appName, host, transactionSubtype, transactionType, name FROM Transaction WHERE httpResponseCode LIKE '5%' SINCE 1 day ago"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE4OTc"
resource "newrelic_one_dashboard" "user_activity" {
  account_id  = 1468011
  description = null
  name        = "User Activity"
  permissions = "public_read_write"
  page {
    description = null
    name        = "User Activity"
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Day of Week Analysis"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) FROM PageView SINCE 7 days ago FACET weekdayOf(timestamp)"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 6
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "Time of Day Analysis"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) FROM PageView SINCE 7 days ago FACET hourOf(timestamp)"
      }
    }
    widget_bar {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 6
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "Top Visited Pages"
      width                    = 8
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM PageView FACET pageUrl SINCE 7 days ago LIMIT 10"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Engagement by Day"
      width                   = 8
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM PageView SINCE 7 days ago TIMESERIES 1 hour"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE5Mzc"
resource "newrelic_one_dashboard" "synthetics_daily_sla" {
  account_id  = 1468011
  description = null
  name        = "Synthetics Daily SLA by Monitor"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Synthetics Daily SLA by Monitor"
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Average Duration"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Uptime %"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE result = 'SUCCESS') FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Apdex"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT apdex(duration, t: 7000) FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Apdex Satisfied"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE duration <= 7000) FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Apdex Tolerated"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE duration > 7000 AND duration <= 28000) FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
    widget_line {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Apdex Frustrated"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(count(*), WHERE duration > 28000) FROM SyntheticCheck SINCE 8 days ago FACET monitorName TIMESERIES 1 day"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk5NTg3Mjg"
resource "newrelic_one_dashboard" "ips_web_api_performance" {
  account_id  = 1468011
  description = null
  name        = "IPS WEB & API performance"
  permissions = "public_read_only"
  page {
    description = null
    name        = "IPS WEB & API performance"
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "WEB Requests per Minute"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-WEB-001' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-WEB-001') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-WEB-002' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-WEB-002') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-WEB-003' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-WEB-003') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "API Requests per Minute"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-API-001' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-API-001') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-API-002' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-API-002') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(count(*), 1 minute) AS 'BCA-VM-API-003' FROM Transaction WHERE (transactionType = 'Web' AND host = 'BCA-VM-API-003') TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
    widget_line {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = ""
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'Response time' FROM Transaction WHERE host = 'BCA-VM-WEB-001' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "WEB Response time"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-WEB-001' FROM Transaction WHERE host = 'BCA-VM-WEB-001' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-WEB-002' FROM Transaction WHERE host = 'BCA-VM-WEB-002' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-WEB-003' FROM Transaction WHERE host = 'BCA-VM-WEB-003' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "API Response time"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-API-001' FROM Transaction WHERE host = 'BCA-VM-API-001' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-API-002' FROM Transaction WHERE host = 'BCA-VM-API-002' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration * 1000) AS 'BCA-VM-API-003' FROM Transaction WHERE host = 'BCA-VM-API-003' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
    widget_line {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "GlobaleWallet user count"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) as eWallet FROM PageView WHERE browserTransactionName = '*.globalewallet.com:443/' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) as MC FROM PageView WHERE browserTransactionName = '*.i-payout.com/managementconsole:443/' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) as SuperNova FROM PageView WHERE browserTransactionName = '*.i-payout.com/SuperNova:443/' TIMESERIES SINCE 1800 seconds ago EXTRAPOLATE"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjMxMDAxNDQ"
resource "newrelic_one_dashboard" "windows_services" {
  account_id  = 1468011
  description = "Get an overview of the windows services running on the monitored hosts"
  name        = "Windows Services - Dashboard"
  permissions = "public_read_write"
  page {
    description = "Windows Services data by host, state, start_mode, name, and display name"
    name        = "Windows Services - Overview"
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 5
      title                    = "Services running per host"
      width                    = 3
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "\n\nSELECT count(*) FROM (FROM Metric select latest(state) AS 'state' where hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})  and metricName = 'windows_service_state'  facet hostname, entity.guid limit max) where state='running' FACET hostname "
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 8
      title                    = "Services stopped per host"
      width                    = 3
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM (FROM Metric select latest(state) AS 'state' where hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})  and metricName = 'windows_service_state'  facet hostname, entity.guid limit max) where state='stopped' FACET hostname "
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 11
      title                    = "Services paused per host"
      width                    = 3
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM (FROM Metric select latest(state) AS 'state' where hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})  and metricName = 'windows_service_state'  facet hostname, entity.guid limit max) where state='paused' FACET hostname "
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 5
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 23
      title                    = "Per service account"
      width                    = 3
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric SELECT uniqueCount(entity.guid)   where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}}) and metricName = 'windows_service_state' and run_as IS NOT NULL FACET cases(\n  WHERE run_as IN ('LocalSystem','localSystem') AS 'LocalSystem', \n  WHERE run_as IN ('NT AUTHORITY\\\\LocalService', 'NT Authority\\\\LocalService') AS 'NT AUTHORITY\\\\LocalService',\n  WHERE run_as IN ('NT AUTHORITY\\\\NetworkService', 'NT Authority\\\\NetworkService') AS 'NT AUTHORITY\\\\NetworkService',\n  WHERE run_as = '' AS 'No account found'\n) OR run_as AS 'Service Account' limit max"
      }
    }
    widget_billboard {
      column                  = 5
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Hosts"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(hostname) AS 'Hosts' where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})   and metricName = 'windows_service_state' compare with 1 hour ago"
      }
    }
    widget_billboard {
      column                  = 7
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Services"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(entity.guid) AS 'Services' where hostname IN ('BCA-VM-SRV-001')  and service_name IN ('ips_sendunsentachsservice', 'ips_achmanagersrv', 'ips_feecollector', 'ips_svcorderprocessorservice', 'ips_emailreceiverservice', 'ips_recurringtransfersservice', 'ips_emailsenderservice', 'ips_checkprocessingservice', 'ips_loadvirtualaccountsservice', 'ips_fxservice', 'ips_abacollectorservice', 'ips_deploymentservice', 'ips_achreportservice') and state NOT IN ('running')  and metricName = 'windows_service_state' "
      }
    }
    widget_billboard {
      column                  = 9
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Service per state"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM (FROM Metric select latest(state) AS 'state' where hostname IN ({{hostname}}) and service_name IN ('ips_sendunsentachsservice', 'ips_achmanagersrv', 'ips_feecollector', 'ips_svcorderprocessorservice', 'ips_emailreceiverservice', 'ips_recurringtransfersservice', 'ips_emailsenderservice', 'ips_checkprocessingservice', 'ips_loadvirtualaccountsservice', 'ips_fxservice', 'ips_abacollectorservice', 'ips_deploymentservice', 'ips_achreportservice') and state IN ({{state}})  and start_mode IN ({{start}})  and metricName = 'windows_service_state'  facet entity.guid limit max) FACET state"
      }
    }
    widget_line {
      column                  = 4
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 5
      title                   = "Services running per host"
      width                   = 9
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(service_name)  where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}}) and metricName = 'windows_service_state' and state='running' facet hostname TIMESERIES auto limit max"
      }
    }
    widget_line {
      column                  = 4
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 8
      title                   = "Services stopped per host"
      width                   = 9
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(service_name)  where hostname IN ({{hostname}}) and metricName = 'windows_service_state'  and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}}) and state='stopped' TIMESERIES auto facet hostname limit max"
      }
    }
    widget_line {
      column                  = 4
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 11
      title                   = "Services paused per host"
      width                   = 9
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(service_name)  where hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})  and metricName = 'windows_service_state' and state='paused' TIMESERIES auto FACET hostname limit max"
      }
    }
    widget_markdown {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      text                    = "![logo](https://upload.wikimedia.org/wikipedia/commons/5/5f/Windows_logo_-_2012.svg)\n\n## Windows Services\nNew Relic's Windows services integration collects data about the services running on your Microsoft Windows hosts and sends it to our platform. \n  \nYou can check the state and start mode of each service, find out which hosts are running a service, set up alerts for services, and more.\n\nOur integration is bundled with the Windows infrastructure agent. If you're monitoring Windows hosts on New Relic, you only need to enable the integration to get Windows services data into our platform.\n\nRead more in the [docs](https://docs.newrelic.com/docs/infrastructure/host-integrations/host-integrations-list/windows-services-integration/)"
      title                   = ""
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
    }
    widget_markdown {
      column                  = 1
      facet_show_other_series = false
      height                  = 1
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      text                    = "# Hosts"
      title                   = ""
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
    }
    widget_markdown {
      column                  = 1
      facet_show_other_series = false
      height                  = 1
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 14
      text                    = "# Services"
      title                   = ""
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
    }
    widget_pie {
      column                   = 4
      facet_show_other_series  = true
      filter_current_dashboard = false
      height                   = 5
      ignore_time_range        = false
      legend_enabled           = true
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 23
      title                    = "Start Mode"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric select uniqueCount(service_name) where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}}) and  metricName = 'windows_service_state'  facet start_mode  limit max"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 8
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 15
      title                    = "Services"
      width                    = 7
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric SELECT latest(substring(display_name,0,40)) AS 'Display Name', latest(state), latest(start_mode) WHERE hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and state IN ({{state}})  and start_mode IN ({{start}})  and metricName='windows_service_state'   FACET hostname AS 'Host Name', service_name  limit max"
      }
    }
    widget_table {
      column                   = 8
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 4
      ignore_time_range        = true
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 15
      title                    = "Stopped last 5 minutes"
      width                    = 5
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) and metricName='windows_service_state' and state='stopped' and entity.guid IN (select uniques(entity.guid,10000) from Metric where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}})  and start_mode IN ({{start}}) and  metricName='windows_service_state' and state in ('running','paused') SINCE 1 HOUR AGO UNTIL 5 MINUTES AGO limit max) FACET hostname, service_name  since 5 minutes ago limit max"
      }
    }
    widget_table {
      column                   = 8
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 4
      ignore_time_range        = true
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 19
      title                    = "Started last 5 minutes"
      width                    = 5
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) and metricName='windows_service_state' and state='started' and entity.guid IN (select uniques(entity.guid,10000) from Metric where hostname IN ({{hostname}})  and service_name IN ({{service_name}}) and display_name IN ({{display_name}})   and start_mode IN ({{start}}) and  metricName='windows_service_state' and state != 'started' SINCE 1 HOUR AGO UNTIL 5 MINUTES AGO limit max) FACET hostname, service_name  since 5 minutes ago limit max"
      }
    }
    widget_table {
      column                   = 8
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 5
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 23
      title                    = "State different from  running, stopped or paused"
      width                    = 5
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = " select hostname, display_name, service_name, state   FROM (select latest(state) as 'state' FROM Metric WHERE  hostname IN ({{hostname}}) and service_name IN ({{service_name}}) and display_name IN ({{display_name}}) and start_mode IN ({{start}}) and metricName = 'windows_service_state'  FACET hostname, display_name, service_name limit max)  where  state != 'running' and state !='stopped' and state !='paused' limit max"
      }
    }
  }
  variable {
    default_values       = ["*"]
    is_multi_selection   = true
    name                 = "hostname"
    replacement_strategy = "string"
    title                = "Host"
    type                 = "nrql"
    nrql_query {
      account_ids = []
      query       = "FROM Metric select uniques(hostname)where metricName = 'windows_service_state' since 7 days ago LIMIT MAX"
    }
  }
  variable {
    default_values       = ["*"]
    is_multi_selection   = true
    name                 = "service_name"
    replacement_strategy = "string"
    title                = "Service name"
    type                 = "nrql"
    nrql_query {
      account_ids = []
      query       = "SELECT uniques(service_name) FROM Metric WHERE metricName = 'windows_service_state' since 7 days ago LIMIT MAX"
    }
  }
  variable {
    default_values       = ["*"]
    is_multi_selection   = true
    name                 = "display_name"
    replacement_strategy = "string"
    title                = "Display name"
    type                 = "nrql"
    nrql_query {
      account_ids = []
      query       = "SELECT uniques(display_name) FROM Metric WHERE metricName = 'windows_service_state' since 7 days ago LIMIT MAX"
    }
  }
  variable {
    default_values       = ["*"]
    is_multi_selection   = true
    name                 = "state"
    replacement_strategy = "string"
    title                = "State"
    type                 = "nrql"
    nrql_query {
      account_ids = []
      query       = "SELECT uniques(state) FROM Metric WHERE metricName = 'windows_service_state' since 7 days ago LIMIT MAX"
    }
  }
  variable {
    default_values       = ["*"]
    is_multi_selection   = true
    name                 = "start"
    replacement_strategy = "string"
    title                = "Start Mode"
    type                 = "nrql"
    nrql_query {
      account_ids = []
      query       = "SELECT uniques(start_mode) FROM Metric WHERE metricName = 'windows_service_state' since 7 days ago LIMIT MAX"
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE3NDE"
resource "newrelic_one_dashboard" "insights_home" {
  account_id  = 1468011
  description = null
  name        = "Insights Home"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Insights Home"
    widget_area {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Pageviews per App"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM PageView FACET appName SINCE 1 day ago TIMESERIES AUTO"
      }
    }
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["Nzc4ODg2fFZJWnxEQVNIQk9BUkR8MjY4OTE"]
      refresh_rate             = null
      row                      = 4
      title                    = "Sessions by Country"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) FROM PageView FACET countryCode SINCE 1 day ago"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Transactions Over Time"
      width                   = 8
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction SINCE 12 hours ago COMPARE WITH 12 hours ago TIMESERIES AUTO"
      }
    }
    widget_line {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Transactions by Host"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 24 hours ago FACET host TIMESERIES"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["Nzc4ODg2fFZJWnxEQVNIQk9BUkR8MjY4ODY"]
      refresh_rate             = null
      row                      = 4
      title                    = "App Website Activity"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) AS 'Sessions', count(*) AS 'Pageviews', count(*)/uniqueCount(session) AS 'Views/Session' FROM PageView FACET appName SINCE 1 day ago"
      }
    }
    widget_table {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["Nzc4ODg2fFZJWnxEQVNIQk9BUkR8MjY4ODk"]
      refresh_rate             = null
      row                      = 4
      title                    = "Top Transactions"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*), average(duration) FROM Transaction SINCE 1 day ago FACET name"
      }
    }
    widget_table {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["Nzc4ODg2fFZJWnxEQVNIQk9BUkR8MjY4ODc"]
      refresh_rate             = null
      row                      = 7
      title                    = "Browser Usage %"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(uniqueCount(session), WHERE userAgentName = 'IE') AS 'IE', percentage(uniqueCount(session), WHERE userAgentName = 'Chrome') AS 'Chrome', percentage(uniqueCount(session), WHERE userAgentName = 'Firefox') AS 'Firefox', percentage(uniqueCount(session), WHERE userAgentName = 'Safari') AS 'Safari' FROM PageView SINCE 1 day ago FACET appName"
      }
    }
    widget_table {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["Nzc4ODg2fFZJWnxEQVNIQk9BUkR8MjY4ODg"]
      refresh_rate             = null
      row                      = 7
      title                    = "Browser OS Usage %"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentage(uniqueCount(session), WHERE userAgentOS = 'Windows') AS 'Windows', percentage(uniqueCount(session), WHERE userAgentOS = 'Mac') AS 'Mac', percentage(uniqueCount(session), WHERE userAgentOS LIKE 'Linux') AS 'Linux', percentage(uniqueCount(session), WHERE userAgentOS NOT IN ('Windows', 'Mac','Linux%')) AS 'Other' FROM PageView FACET appName SINCE 1 day ago"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjk0MDE4NTk"
resource "newrelic_one_dashboard" "app_servers" {
  account_id  = 1468011
  description = null
  name        = "Tell Me About My Application Servers"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Tell Me About My Application Servers"
    widget_area {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Performance by Host"
      width                   = 8
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) FROM Transaction since 1 day ago  TIMESERIES AUTO FACET host"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NzY1ODA4fFZJWnxEQVNIQk9BUkR8MzI2MDU"]
      refresh_rate             = null
      row                      = 1
      title                    = "Which Apps Are Busiest?"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 1 day ago FACET  appName"
      }
    }
    widget_bar {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NzY1ODA4fFZJWnxEQVNIQk9BUkR8MzI2MDU"]
      refresh_rate             = null
      row                      = 1
      title                    = "Which Transactions Are Busiest?"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 1 day ago  facet name"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "What Days Are Busiest?"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 7 day ago FACET  weekdayOf(timestamp)"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NzY1ODA4fFZJWnxEQVNIQk9BUkR8MzI2MDU"]
      refresh_rate             = null
      row                      = 7
      title                    = "Are we Balancing the load?"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 1 day ago FACET  host"
      }
    }
    widget_billboard {
      column                  = 5
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Can I see a percentile breakdown of response times?"
      warning                 = null
      width                   = 8
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT percentile(duration,99,95,75,50) FROM PageView SINCE 1 day ago"
      }
    }
    widget_histogram {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Application Server Response Time - Histogram"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT histogram(backendDuration) FROM PageView SINCE 1 day ago"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Average Response Times"
      width                   = 8
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) FROM Transaction since 1 day ago  TIMESERIES AUTO"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 13
      title                   = "How does the front end and back end performance compare right now?"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) as ' Avg Frontend Duration', average(backendDuration)  FROM PageView SINCE 2 minutes ago UNTIL 10 seconds ago TIMESERIES"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 16
      title                   = "How does the front end and back end performance compare over the past day?"
      width                   = 12
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = false
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) as 'Avg Frontend Duration', average(backendDuration)  FROM PageView SINCE 1 day ago TIMESERIES"
      }
    }
    widget_pie {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NzY1ODA4fFZJWnxEQVNIQk9BUkR8MzI2MDU"]
      refresh_rate             = null
      row                      = 1
      title                    = "What Response Codes are we seeing?"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction since 1 day ago FACET  httpResponseCode"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjkzOTg0NzQ"
resource "newrelic_one_dashboard" "business_outcomes" {
  account_id  = 1468011
  description = null
  name        = "Business Outcomes"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Business Outcomes"
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "UX of Purchase Page"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) AS 'Duration' FROM PageView facet buckets(duration, width: 10, buckets: 10) SINCE 1 day ago WHERE pageUrl like '%/purchase-confirmed.jsp'"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 10
      title                    = "Top Cities"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM PageView SINCE 1 hour ago facet city"
      }
    }
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NTQxNDk3fFZJWnxEQVNIQk9BUkR8MTIwNTYw"]
      refresh_rate             = null
      row                      = 10
      title                    = "Browser Type"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM PageView SINCE 1 day ago FACET userAgentName"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 13
      title                    = "By City"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) from PageView facet city"
      }
    }
    widget_billboard {
      column                  = 1
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Users Day Over Day"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) AS 'Site Visitors' FROM PageView SINCE 1 day ago COMPARE WITH 1 day ago"
      }
    }
    widget_billboard {
      column                  = 5
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Revenue Day Over Day"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(`itemPrice`) As 'Revenue' FROM Transaction WHERE name = 'WebTransaction/web/orders (POST)' since 1 day ago COMPARE WITH 1 day ago"
      }
    }
    widget_billboard {
      column                  = 9
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Average Cart Value, Number of Errors"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(`itemPrice`) AS 'Average Price',count(*) AS 'Errors' from Transaction where errorCode IS NOT NULL AND `itemPrice` IS NOT NULL since 1 day ago"
      }
    }
    widget_billboard {
      column                  = 1
      critical                = "75000"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Total Revenue At Risk"
      warning                 = "45000"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(`itemPrice`) AS 'Total Revenue' from Transaction where errorCode IS NOT NULL since 1 day ago"
      }
    }
    widget_billboard {
      column                  = 9
      critical                = "2000"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Home Duration > 3s"
      warning                 = "1000"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) as 'Page Views' FROM PageView where pageUrl LIKE '%/index.html' and duration >= 3 since 1 day ago"
      }
    }
    widget_billboard {
      column                  = 5
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 10
      title                   = "Live Users"
      warning                 = null
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT uniqueCount(session) AS 'Site Visitors' FROM PageView SINCE 1 minute ago COMPARE WITH 1 day ago"
      }
    }
    widget_funnel {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Conversion Funnel"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT funnel(session, WHERE pageUrl like '%/index.html' AS 'Home', where pageUrl like '%/login.html' AS 'Login', WHERE pageUrl LIKE '%/browse/category/%' AS 'Browse Items',  WHERE pageUrl LIKE '%/purchase-confirmed.jsp' AS 'Purchased') FROM PageView SINCE 1 day ago"
      }
    }
    widget_histogram {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Page Durations"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT histogram(duration, width: 10) FROM PageView since 1 day ago"
      }
    }
    widget_pie {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 13
      title                    = "Purchase Response Codes"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction WHERE name LIKE 'WebTransaction/web/purchase' FACET httpResponseCode SINCE 1 week ago"
      }
    }
    widget_table {
      column                   = 5
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = ["NTQxNDk3fFZJWnxEQVNIQk9BUkR8MTA4ODM1"]
      refresh_rate             = null
      row                      = 4
      title                    = "Transactions And Error Codes"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*),count(errorCode) from Transaction since 1 day ago FACET appName"
      }
    }
  }
}

# __generated__ by Terraform from "MTQ2ODAxMXxWSVp8REFTSEJPQVJEfGRhOjY4NTU0OTY"
resource "newrelic_one_dashboard" "dotnet" {
  account_id  = 1468011
  description = null
  name        = ".NET"
  permissions = "public_read_write"
  page {
    description = null
    name        = "Overview"
    widget_area {
      column                  = 7
      facet_show_other_series = false
      height                  = 4
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 1
      title                   = "Memory Allocation/Working Set (MB)"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS 'Memory Working Set' FROM Metric WHERE (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA') and metricTimesliceName LIKE '%Memory/WorkingSet%' TIMESERIES AUTO "
      }
    }
    widget_area {
      column                  = 3
      facet_show_other_series = false
      height                  = 4
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 5
      title                   = "Slowest Query Time"
      width                   = 5
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(apm.service.datastore.operation.duration * 1000) FROM Metric WHERE (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA')  FACET  `table`, `operation` LIMIT 5 TIMESERIES "
      }
    }
    widget_area {
      column                  = 8
      facet_show_other_series = false
      height                  = 4
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 5
      title                   = "Most Time Consuming"
      width                   = 5
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT sum(apm.service.datastore.operation.duration * 1000) FROM Metric  FACET  `table`, `operation` LIMIT 5 TIMESERIES WHERE (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA') and datastoreType = 'MSSQL' AND `table` != '' AND `table` != '(subquery)'"
      }
    }
    widget_area {
      column                  = 3
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 9
      title                   = "Memory Used by Large Object Heap"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/LOH/Size(MB)` FROM Metric WHERE metricTimesliceName LIKE 'GC/LOH/Size%' TIMESERIES"
      }
    }
    widget_bar {
      column                   = 3
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 4
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Total Transactions by Application (click on the app name to filter)"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Transaction SELECT count(*)  where appName = 'drtestmerchantapi' FACET request.uri"
      }
    }
    widget_billboard {
      column                  = 11
      critical                = null
      facet_show_other_series = false
      height                  = 4
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "HTTP Status Code"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT apdex(newrelic.timeslice.value) FROM Metric WHERE (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA') and metricTimesliceName LIKE 'Apdex/StatusCode/%' FACET metricTimesliceName"
      }
    }
    widget_billboard {
      column                  = 1
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 6
      title                   = "CPU Utilization"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1000 FROM Metric WHERE (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA') and metricTimesliceName LIKE '%CPU/%' FACET metricTimesliceName"
      }
    }
    widget_billboard {
      column                  = 1
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 9
      title                   = "Apdex Score"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT apdex(apm.service.apdex) as 'App server', apdex(apm.service.apdex.user) as 'End user' FROM Metric  where (entity.guid = 'MTQ2ODAxMXxBUE18QVBQTElDQVRJT058MTc0MzkwODIwMA') LIMIT MAX"
      }
    }
    widget_line {
      column                  = 7
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 9
      title                   = "Number of References to Objects"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+3 AS `GC/Handles` FROM Metric WHERE metricTimesliceName LIKE 'GC/Handles%' TIMESERIES "
      }
    }
    widget_line {
      column                  = 10
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 9
      title                   = "Network Traffic"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT latest(transmitBytesPerSecond) AS `Transmit Bytes per Second`, latest(receiveBytesPerSecond) AS `Receive Bytes per Second` FROM NetworkSample TIMESERIES AUTO"
      }
    }
    widget_markdown {
      column                  = 1
      facet_show_other_series = false
      height                  = 2
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      text                    = "![logo](https://raw.githubusercontent.com/newrelic/newrelic-quickstarts/265e46a84e966c07302d570e77fc9561d3abe636/quickstarts/dotnet/dotnet/logo.svg)"
      title                   = ""
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
    }
    widget_markdown {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 3
      text                    = "**About**\n\nInstrument your application with New Relic - [Add Data](https://one.newrelic.com/catalog-pack-details?state=fbb63ea7-12ed-4703-31d7-544ca12b03b3).\n\nUnable to find data in your dashboard? - [Troubleshoot here](\nhttps://docs.newrelic.com/docs/apm/agents/net-agent/troubleshooting/no-data-appears-net/)\n\n[Please rate this dashboard](https://docs.google.com/forms/d/e/1FAIpQLSclR38J8WbbB2J1tHnllKUkzWZkJhf4SrJGyavpMd4t82NjnQ/viewform?usp=pp_url&entry.1615922415=.Net&entry.358368110=https://onenr.io/0ERzlZYPvQr) here and let us know how we can improve it for you.\n"
      title                   = ""
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
    }
  }
  page {
    description = null
    name        = "Thread Pool"
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Throughput"
      width                    = 5
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName LIKE '%Threadpool/Throughput/%' FACET metricTimesliceName"
      }
    }
    widget_bar {
      column                   = 6
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Completion Threads"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1000 FROM Metric WHERE metricTimesliceName LIKE '%Threadpool/Completion/%' FACET metricTimesliceName"
      }
    }
    widget_billboard {
      column                  = 10
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Worker Threads"
      warning                 = null
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1000 FROM Metric WHERE metricTimesliceName LIKE '%Threadpool/Worker/%' FACET metricTimesliceName"
      }
    }
  }
  page {
    description = null
    name        = "Garbage Collection"
    widget_area {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 1
      title                   = "Active References Promoted From Generation 0 to Generation 1"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen0/Promoted(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen0/Promoted' TIMESERIES"
      }
    }
    widget_area {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 4
      title                   = "Active References Promoted From Generation 1 to Generation 2"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen1/Promoted(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen1/Promoted' TIMESERIES"
      }
    }
    widget_area {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 7
      title                   = "Unpromoted Active References"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen2/Survived(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen2/Survived' TIMESERIES"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Generation 0 Heap"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName LIKE 'GC/Gen0/%' FACET metricTimesliceName"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "Generation 1 Heap"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName LIKE 'GC/Gen1/%' FACET metricTimesliceName"
      }
    }
    widget_bar {
      column                   = 1
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 7
      title                    = "Generation 2 Heap"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName LIKE 'GC/Gen2/%' FACET metricTimesliceName"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 1
      title                   = "Available Memory to be Allocated"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen0/Size(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen0/Size' TIMESERIES"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 4
      title                   = "Memory Used in Generation 1 Heap"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen1/Size(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen1/Size' TIMESERIES"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 7
      title                   = "Memory Used in Generation 2 Heap"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 AS `GC/Gen2/Size(MB)` FROM Metric WHERE metricTimesliceName = 'GC/Gen2/Size' TIMESERIES"
      }
    }
  }
  page {
    description = null
    name        = "Transactions"
    widget_area {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 4
      title                   = "Web Transactions Time"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT filter(average(apm.service.overview.web * 1000), WHERE segmentName like '.NET') as '.NET', filter(average(apm.service.overview.web * 1000), WHERE segmentName like 'MSSQL') as 'MSSQL' FROM Metric LIMIT MAX TIMESERIES AUTO"
      }
    }
    widget_area {
      column                  = 6
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 7
      title                   = "Middleware Pipeline"
      width                   = 5
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1000 AS `DotNet/OrderController/Detail` FROM Metric WHERE metricTimesliceName LIKE 'DotNet/%' FACET metricTimesliceName TIMESERIES"
      }
    }
    widget_bar {
      column                   = 9
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = false
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 4
      title                    = "Top 5 Slowest Transactions"
      width                    = 4
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT max(duration) FROM Transaction WHERE appName = 'drtestmerchantapi' and (transactionType = 'Web') SINCE 1 week ago LIMIT 5 EXTRAPOLATE FACET name"
      }
    }
    widget_billboard {
      column                  = 11
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 7
      title                   = "Transactions Overview"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Transaction SELECT count(*) as 'Total transactions', average(duration) as 'Avg duration (s)', percentile(duration, 90) as 'Slowest 10% (s)', percentage(count(*), WHERE error is false) AS 'Success rate'"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 1
      title                   = "Transaction Errors"
      width                   = 5
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM TransactionError WHERE `error.expected` IS FALSE OR `error.expected` IS NULL FACET `error.class`, `transactionUiName`, `error.message` TIMESERIES"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 4
      title                   = "Slowest Average Response Time"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT filter(rate(sum(apm.service.transaction.duration), 1 second), WHERE transactionName IN ('WebTransaction/ASP/ROOT')) as 'ROOT', filter(rate(sum(apm.service.transaction.duration), 1 second), WHERE transactionName IN ('WebTransaction/StatusCode/302')) as '302', filter(rate(sum(apm.service.transaction.duration), 1 second), WHERE transactionName IN ('WebTransaction/ASP/Basket/Checkout')) as 'Basket/Checkout', filter(rate(sum(apm.service.transaction.duration), 1 second), WHERE transactionName IN ('WebTransaction/ASP/Basket')) as 'Basket', filter(rate(sum(apm.service.transaction.duration), 1 second), WHERE transactionName IN ('WebTransaction/ASP/images/products/1.png')) as 'images/products/1.png' FROM Metric WHERE (transactionType = 'Web') LIMIT 5 TIMESERIES"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 7
      title                   = "Throughput Today Compared With 1 Week Ago"
      width                   = 5
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) from Transaction TIMESERIES 1 hour since today COMPARE WITH 1 week ago"
      }
    }
    widget_line {
      column                  = 5
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 10
      title                   = "Average Transaction Duration Today Compared With 1 Week Ago"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(duration) FROM Transaction TIMESERIES SINCE today COMPARE WITH 1 week ago"
      }
    }
    widget_line {
      column                  = 9
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 10
      title                   = "Adpex Score Today Compared With 1 Week Ago"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT apdex(duration, t: 0.4) FROM Transaction TIMESERIES SINCE today COMPARE WITH 1 week ago"
      }
    }
    widget_pie {
      column                   = 6
      facet_show_other_series  = false
      filter_current_dashboard = false
      height                   = 3
      ignore_time_range        = false
      legend_enabled           = true
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Most Popular Incoming HTTP Requests"
      width                    = 7
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) FROM Transaction WHERE appName = 'drtestmerchantapi' and  (transactionType = 'Web') SINCE last week EXTRAPOLATE FACET name"
      }
    }
    widget_stacked_bar {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 10
      title                   = "Transactions Day By Day "
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Transaction SELECT count(*), percentage(count(*), WHERE error IS false) FACET dateOf(timestamp) TIMESERIES AUTO "
      }
    }
  }
  page {
    description = null
    name        = "Errors"
    widget_billboard {
      column                  = 9
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 3
      title                   = "Errors Overview"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM Transaction SELECT count(*) as 'Total Transactions', percentage(count(*), WHERE error IS true) as 'Failed Transactions (%)', count(*) * percentage(count(*), WHERE error IS true) / 100 as 'Failed Transactions'"
      }
    }
    widget_billboard {
      column                  = 11
      critical                = null
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 3
      title                   = "Latest Error"
      warning                 = null
      width                   = 2
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "FROM TransactionError SELECT latest(timestamp) as 'Latest Error' SINCE last week"
      }
    }
    widget_line {
      column                  = 1
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      is_label_visible        = false
      legend_enabled          = true
      refresh_rate            = null
      row                     = 3
      title                   = "Transactions Errors Today Compared With 1 Week Ago"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      y_axis_left_zero        = true
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(*) from Transaction where response.status = '404' and transactionType = 'Web' TIMESERIES 10 minutes since today COMPARE WITH 1 week ago"
      }
    }
    widget_pie {
      column                   = 1
      facet_show_other_series  = true
      filter_current_dashboard = false
      height                   = 2
      ignore_time_range        = false
      legend_enabled           = true
      linked_entity_guids      = []
      refresh_rate             = null
      row                      = 1
      title                    = "Top 10 Failed Transactions"
      width                    = 12
      y_axis_left_max          = 0
      y_axis_left_min          = 0
      nrql_query {
        account_id = "1468011"
        query      = "Select percentage(count(*), WHERE error IS true) from Transaction WHERE transactionType = 'Web' facet name SINCE last week"
      }
    }
  }
  page {
    description = null
    name        = "Alerts"
    widget_billboard {
      column                  = 1
      critical                = "10"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Transaction Errors"
      warning                 = "5"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT count(apm.service.error.count) / count(apm.service.transaction.duration) * 100 as 'Web Errors' FROM Metric WHERE transactionType = 'Web'"
      }
    }
    widget_billboard {
      column                  = 4
      critical                = "0"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Apdex Score"
      warning                 = "0.5"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT apdex(duration, t: 0.5) FROM Transaction"
      }
    }
    widget_billboard {
      column                  = 7
      critical                = "90"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "High CPU Utilization"
      warning                 = "85"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT rate(sum(apm.service.cpu.usertime.utilization), 1 second) * 100 FROM Metric"
      }
    }
    widget_billboard {
      column                  = 10
      critical                = "90"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 1
      title                   = "Memory Usage"
      warning                 = "85"
      width                   = 3
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(memoryUsedBytes/memoryTotalBytes) * 100 FROM SystemSample"
      }
    }
    widget_billboard {
      column                  = 1
      critical                = "256000"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Generation 0 Hits"
      warning                 = "250000"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1000 FROM Metric WHERE metricTimesliceName = 'GC/Gen0/Size'"
      }
    }
    widget_billboard {
      column                  = 5
      critical                = "8000000"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Generation 1 Hits"
      warning                 = "2000000"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName = 'GC/Gen1/Size'"
      }
    }
    widget_billboard {
      column                  = 9
      critical                = "10000000"
      facet_show_other_series = false
      height                  = 3
      ignore_time_range       = false
      legend_enabled          = false
      refresh_rate            = null
      row                     = 4
      title                   = "Generation 2 Hits"
      warning                 = "9000000"
      width                   = 4
      y_axis_left_max         = 0
      y_axis_left_min         = 0
      nrql_query {
        account_id = "1468011"
        query      = "SELECT average(newrelic.timeslice.value) * 1e+6 FROM Metric WHERE metricTimesliceName = 'GC/Gen2/Size'"
      }
    }
  }
}
