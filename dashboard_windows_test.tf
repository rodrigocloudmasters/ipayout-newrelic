# Windows Services dashboard for the Test environment.
# Clone of "Windows Services - Dashboard" (production) scoped to the test hosts.
# NOTE: the Windows Services integration (nri-winservices) currently reports only from
# BCA-VM-SRV-001 (production). Widgets stay empty until it is enabled on the test hosts.

locals {
  # Test host scope injected into every query
  windows_test_scope = "(hostname LIKE 'UE1-TEST%' OR hostname LIKE 'MIAT-VM%')"

  # IPS service list taken from the "IPS Finwinservice Test is down" alert condition
  windows_test_services = "'ips_sendunsentachsservice', 'ips_achmanagersrv', 'ips_feecollector', 'ips_svcorderprocessorservice', 'ips_emailreceiverservice', 'ips_recurringtransfersservice', 'ips_emailsenderservice', 'ips_checkprocessingservice', 'ips_loadvirtualaccountsservice', 'ips_fxservice', 'ips_abacollectorservice', 'ips_deploymentservice', 'ips_achreportservice', 'ipsonboardingservice', 'ripplepaymentsservice', 'ipsportalcoreschedulerservice'"
}

resource "newrelic_one_dashboard" "windows_services_test" {
  account_id  = 1468011
  name        = "Windows Services - Test Environment"
  description = "Windows services running on the Test hosts (UE1-TEST-* and MIAT-VM-*). Mirror of the production Windows Services dashboard."
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
      query       = "SELECT uniques(hostname) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_test_scope} SINCE 7 days ago LIMIT MAX"
    }
  }

  variable {
    name                 = "service_name"
    title                = "Service name"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(service_name) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_test_scope} SINCE 7 days ago LIMIT MAX"
    }
  }

  variable {
    name                 = "display_name"
    title                = "Display name"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(display_name) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_test_scope} SINCE 7 days ago LIMIT MAX"
    }
  }

  variable {
    name                 = "state"
    title                = "State"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(state) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_test_scope} SINCE 7 days ago LIMIT MAX"
    }
  }

  variable {
    name                 = "start"
    title                = "Start Mode"
    type                 = "nrql"
    is_multi_selection   = true
    replacement_strategy = "string"
    default_values       = ["*"]

    nrql_query {
      account_ids = [1468011]
      query       = "SELECT uniques(start_mode) FROM Metric WHERE metricName = 'windows_service_state' AND ${local.windows_test_scope} SINCE 7 days ago LIMIT MAX"
    }
  }

  page {
    name        = "Windows Services - Overview"
    description = "Windows Services data of the Test environment by host, state, start_mode, name, and display name"

    widget_markdown {
      title  = ""
      row    = 1
      column = 1
      width  = 4
      height = 3
      text   = "![logo](https://upload.wikimedia.org/wikipedia/commons/5/5f/Windows_logo_-_2012.svg)\n\n## Windows Services - Test Environment\nServices running on the Test hosts (UE1-TEST-* and MIAT-VM-*).\n\nThis dashboard mirrors the production Windows Services dashboard. It requires the Windows services integration (bundled with the infrastructure agent) to be enabled on each test host."
    }

    widget_billboard {
      title  = "Hosts"
      row    = 1
      column = 5
      width  = 2
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(hostname) AS 'Hosts' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} COMPARE WITH 1 hour ago"
      }
    }

    widget_billboard {
      title    = "IPS services not running"
      row      = 1
      column   = 7
      width    = 2
      height   = 3
      critical = 1

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(entity.guid) AS 'Services' WHERE ${local.windows_test_scope} AND service_name IN (${local.windows_test_services}) AND state NOT IN ('running') AND metricName = 'windows_service_state'"
      }
    }

    widget_billboard {
      title  = "Service per state"
      row    = 1
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN (${local.windows_test_services}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET entity.guid LIMIT MAX) FACET state"
      }
    }

    widget_markdown {
      title  = ""
      row    = 4
      column = 1
      width  = 12
      height = 1
      text   = "# Hosts"
    }

    widget_bar {
      title  = "Services running per host"
      row    = 5
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET hostname, entity.guid LIMIT MAX) WHERE state = 'running' FACET hostname"
      }
    }

    widget_line {
      title          = "Services running per host"
      row            = 5
      column         = 4
      width          = 9
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state = 'running' FACET hostname TIMESERIES AUTO LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Services stopped per host"
      row    = 8
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET hostname, entity.guid LIMIT MAX) WHERE state = 'stopped' FACET hostname"
      }
    }

    widget_line {
      title          = "Services stopped per host"
      row            = 8
      column         = 4
      width          = 9
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state = 'stopped' FACET hostname TIMESERIES AUTO LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Services paused per host"
      row    = 11
      column = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = 1468011
        query      = "SELECT count(*) FROM (FROM Metric SELECT latest(state) AS 'state' WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET hostname, entity.guid LIMIT MAX) WHERE state = 'paused' FACET hostname"
      }
    }

    widget_line {
      title          = "Services paused per host"
      row            = 11
      column         = 4
      width          = 9
      height         = 3
      legend_enabled = true

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state = 'paused' FACET hostname TIMESERIES AUTO LIMIT MAX"
      }
    }

    widget_markdown {
      title  = ""
      row    = 14
      column = 1
      width  = 12
      height = 1
      text   = "# Services"
    }

    widget_table {
      title  = "Services"
      row    = 15
      column = 1
      width  = 7
      height = 8

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(substring(display_name, 0, 40)) AS 'Display Name', latest(state), latest(start_mode) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET hostname AS 'Host Name', service_name LIMIT MAX"
      }
    }

    widget_table {
      title  = "Stopped last 5 minutes"
      row    = 15
      column = 8
      width  = 5
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state = 'stopped' AND entity.guid IN (SELECT uniques(entity.guid, 10000) FROM Metric WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND state IN ('running', 'paused') SINCE 1 hour ago UNTIL 5 minutes ago LIMIT MAX) FACET hostname, service_name SINCE 5 minutes ago LIMIT MAX"
      }
    }

    widget_table {
      title  = "Started last 5 minutes"
      row    = 19
      column = 8
      width  = 5
      height = 4

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state = 'running' AND entity.guid IN (SELECT uniques(entity.guid, 10000) FROM Metric WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND state IN ('stopped', 'paused') SINCE 1 hour ago UNTIL 5 minutes ago LIMIT MAX) FACET hostname, service_name SINCE 5 minutes ago LIMIT MAX"
      }
    }

    widget_bar {
      title  = "Per service account"
      row    = 23
      column = 1
      width  = 3
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(entity.guid) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND run_as IS NOT NULL FACET run_as AS 'Service Account' LIMIT MAX"
      }
    }

    widget_pie {
      title  = "Start Mode"
      row    = 23
      column = 4
      width  = 4
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT uniqueCount(service_name) WHERE hostname IN ({{hostname}}) AND service_name IN ({{service_name}}) AND display_name IN ({{display_name}}) AND state IN ({{state}}) AND start_mode IN ({{start}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} FACET start_mode LIMIT MAX"
      }
    }

    widget_table {
      title  = "State different from running, stopped or paused"
      row    = 23
      column = 8
      width  = 5
      height = 5

      nrql_query {
        account_id = 1468011
        query      = "FROM Metric SELECT latest(display_name), latest(state) WHERE hostname IN ({{hostname}}) AND metricName = 'windows_service_state' AND ${local.windows_test_scope} AND state NOT IN ('running', 'stopped', 'paused') FACET hostname, service_name LIMIT MAX"
      }
    }
  }
}
