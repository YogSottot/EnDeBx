terraform {
  required_version = ">= 1.8.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    vmmanager6 = {
      source  = "usaafko/vmmanager6"
      version = ">= 0.0.34"
    }
  }
}
