terraform {
  required_version = ">= 1.5"

  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.0"
    }
  }
}

# Credentials via environment variables (see .env, not versioned):
#   NEW_RELIC_API_KEY, NEW_RELIC_ACCOUNT_ID, NEW_RELIC_REGION
provider "newrelic" {}
