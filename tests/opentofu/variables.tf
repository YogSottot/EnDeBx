variable "pm_email" {
  type      = string
  sensitive = true
}

variable "pm_password" {
  type      = string
  sensitive = true
}

variable "pm_api_url" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_zone_name" {
  type    = string
  default = "0fr.ru"
}

variable "cloudflare_record_suffix" {
  type    = string
  default = "endebx"
}

variable "cloudflare_ttl" {
  type    = number
  default = 60
}

variable "distro" {
  type    = string
  default = "debian12"

  validation {
    condition     = contains(["debian12", "debian13", "ubuntu2404", "astra18"], var.distro)
    error_message = "distro must be one of: debian12, debian13, ubuntu2404, astra18."
  }
}

variable "run_id" {
  type    = string
  default = "manual"
}

variable "node" {
  type    = number
  default = 1
}

variable "cluster" {
  type    = number
  default = 1
}

variable "account" {
  type    = number
  default = 30
}

variable "ipv4_pool_id" {
  type    = number
  default = 2
}

variable "public_bridge" {
  type    = string
  default = "vmbr0"
}

variable "private_ipv4_pool_id" {
  type     = number
  default  = 1
  nullable = true
}

variable "private_bridge" {
  type    = string
  default = "vmbr1"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "disk" {
  type    = number
  default = 20480
}

variable "os_template_ids" {
  type = map(number)
  default = {
    debian12   = 42
    debian13   = 104
    ubuntu2404 = 27
    astra18    = 88
  }
}
