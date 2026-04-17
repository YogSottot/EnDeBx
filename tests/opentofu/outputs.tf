output "public_ipv4" {
  value = local.public_ipv4
}

output "private_ipv4" {
  value = local.private_ipv4
}

output "vm_fqdn" {
  value = local.vm_fqdn
}

output "vm_name" {
  value = local.vm_name
}

output "vm_id" {
  value = vmmanager6_vm_qemu.test_vm.id
}

output "generated_root_password" {
  value     = random_password.vm_root.result
  sensitive = true
}
