# Synthetic monitors (SIMPLE ping).
#
# Scope cut to three sites on 2026-09-30 at the request of the company owner: the
# previous 135 monitors covered every tenant domain with traffic, which was far more
# than anyone read. The three kept are the highest-traffic sites among the payment
# properties, measured over the 7 days to 2026-09-30:
#
#   admin.i-payout.com          116,745 pageviews   platform back office
#   us.plexus-pay.com            17,228 pageviews   Plexus
#   vitalpay.globalewallet.com   10,357 pageviews   Vital
#
# The full domain list is recoverable from git history if the scope is ever widened
# again; do not rebuild it by hand.

locals {
  # Domains exposing /public/healthcheck.ashx (verified 200 OK)
  healthcheck_domains = [
    "admin.i-payout.com",
    "us.plexus-pay.com",
    "vitalpay.globalewallet.com",
  ]

  # Sites without the healthcheck endpoint: monitor the homepage instead
  homepage_domains = []

  synthetic_urls = merge(
    { for d in local.healthcheck_domains : d => "https://${d}/public/healthcheck.ashx" },
    { for d in local.homepage_domains : d => "https://${d}/" },
  )
}

resource "newrelic_synthetics_monitor" "web" {
  for_each = local.synthetic_urls

  account_id = 1468011
  name       = "Web - ${each.key}"
  type       = "SIMPLE"
  status     = "ENABLED"
  period     = "EVERY_10_MINUTES"
  uri        = each.value

  locations_public = ["US_EAST_1", "US_WEST_1"]

  verify_ssl          = true
  bypass_head_request = true
}

# ---------------------------------------------------------------------------
# Pre-existing monitors, created in the UI before this project and imported on
# 2026-09-30 so they stop being invisible to Terraform. They are kept, not cut:
# the owner's reduction applied to the 135 generated tenant monitors above.
#
# Their settings are deliberately left as they were found rather than normalised
# to match the block above -- different periods, more locations, and a validation
# string on the demo site. Changing them was not asked for.
# ---------------------------------------------------------------------------

resource "newrelic_synthetics_monitor" "corp_website" {
  account_id = 1468011
  name       = "Corp website"
  type       = "SIMPLE"
  status     = "ENABLED"
  period     = "EVERY_15_MINUTES"
  uri        = "https://www.i-payout.com"

  locations_public = ["AP_SOUTHEAST_1", "AP_SOUTHEAST_2", "EU_WEST_2", "US_EAST_1"]

  verify_ssl = true
}

resource "newrelic_synthetics_monitor" "demo_globalewallet" {
  account_id = 1468011
  name       = "Demo globalewallet"
  type       = "SIMPLE"
  status     = "ENABLED"
  period     = "EVERY_10_MINUTES"
  uri        = "https://demo.globalewallet.com/public/healthcheck.ashx"

  locations_public = ["AP_SOUTHEAST_2", "AP_SOUTH_1", "CA_CENTRAL_1", "EU_WEST_2", "SA_EAST_1", "US_EAST_1"]

  # The demo site answers 200 even when unhealthy; the body is what tells them apart.
  validation_string = "\"code\": 1"
}
