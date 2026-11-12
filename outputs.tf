# IP addresses from the DHCP leases of the libvirt network
data "libvirt_domain_interface_addresses" "kvmbox" {
  domain = libvirt_domain.kvmbox.name
  source = "lease"
}

locals {
  vm_ip = try([
    for a in flatten(data.libvirt_domain_interface_addresses.kvmbox.interfaces[*].addrs) : a.addr
    if a.type == "ipv4"
  ][0], null)
}

output "vm_name" {
  description = "Name of the libvirt domain"
  value       = libvirt_domain.kvmbox.name
}

output "vm_ip" {
  description = "IPv4 address of the VM (null until the DHCP lease is known, run 'tofu refresh')"
  value       = local.vm_ip
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = local.vm_ip == null ? null : "ssh -i ${local.ssh_private_key_path} ubuntu@${local.vm_ip}"
}
