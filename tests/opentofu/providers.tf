provider "vmmanager6" {
  pm_email    = var.pm_email
  pm_password = var.pm_password
  pm_api_url  = trimsuffix(var.pm_api_url, "/")
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
