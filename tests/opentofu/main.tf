locals {
  distro_short = {
    debian12   = "d12"
    debian13   = "d13"
    ubuntu2404 = "u2404"
    astra18    = "astra18"
  }

  vm_name           = "${local.distro_short[var.distro]}-${var.run_id}"
  dns_record_name   = "${local.vm_name}.${var.cloudflare_record_suffix}"
  dns_wildcard_name = "*.${local.dns_record_name}"
  vm_fqdn           = "${local.dns_record_name}.${var.cloudflare_zone_name}"

  ipv4s = [
    for ip in vmmanager6_vm_qemu.test_vm.ip_addresses : ip.addr
    if length(regexall("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip.addr)) > 0
  ]

  public_ipv4s = [
    for ip in vmmanager6_vm_qemu.test_vm.ip_addresses : ip.addr
    if length(regexall("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip.addr)) > 0 &&
    length(regexall("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.)", ip.addr)) == 0
  ]

  private_ipv4s = var.private_ipv4_pool_id == null ? [] : [
    for ip in vmmanager6_vm_qemu.test_vm.ip_addresses : ip.addr
    if length(regexall("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip.addr)) > 0 &&
    length(regexall("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.)", ip.addr)) > 0
  ]

  public_ipv4  = try(local.public_ipv4s[0], local.ipv4s[0])
  private_ipv4 = var.private_ipv4_pool_id == null ? null : try(local.private_ipv4s[0], try(local.ipv4s[1], null))

  vm_interfaces = concat(
    [
      {
        bridge   = var.public_bridge
        ippool   = var.ipv4_pool_id
        ip_count = 1
      }
    ],
    var.private_ipv4_pool_id == null ? [] : [
      {
        bridge   = var.private_bridge
        ippool   = var.private_ipv4_pool_id
        ip_count = 1
      }
    ]
  )
}

resource "random_password" "vm_root" {
  length           = 24
  special          = true
  override_special = "!@#%^*()-_=+[]{}"
}

resource "vmmanager6_vm_qemu" "test_vm" {
  name     = local.vm_name
  desc     = "EnDeBx ${var.distro} test ${var.run_id}"
  node     = var.node
  cores    = var.cores
  memory   = var.memory
  disk     = var.disk
  os       = var.os_template_ids[var.distro]
  password = random_password.vm_root.result
  cluster  = var.cluster
  account  = var.account
  domain   = local.vm_fqdn

  dynamic "custom_interfaces" {
    for_each = local.vm_interfaces

    content {
      bridge   = custom_interfaces.value.bridge
      ippool   = custom_interfaces.value.ippool
      ip_count = custom_interfaces.value.ip_count
    }
  }
}

resource "cloudflare_dns_record" "test_vm" {
  zone_id = var.cloudflare_zone_id
  name    = local.dns_record_name
  content = local.public_ipv4
  type    = "A"
  ttl     = var.cloudflare_ttl
  proxied = false
  comment = "EnDeBx ${var.distro} test ${var.run_id}"
}

resource "cloudflare_dns_record" "test_vm_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = local.dns_wildcard_name
  content = local.public_ipv4
  type    = "A"
  ttl     = var.cloudflare_ttl
  proxied = false
  comment = "EnDeBx wildcard ${var.distro} test ${var.run_id}"
}
