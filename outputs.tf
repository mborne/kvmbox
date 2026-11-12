# IP addresses from the DHCP leases of the libvirt network
data "libvirt_domain_interface_addresses" "node" {
  for_each = libvirt_domain.node

  domain = each.value.name
  source = "lease"
}

locals {
  node_ips = {
    for name, d in data.libvirt_domain_interface_addresses.node : name => try([
      for a in flatten(d.interfaces[*].addrs) : a.addr if a.type == "ipv4"
    ][0], null)
  }
}

output "node_ips" {
  description = "IPv4 address of each node (null until the DHCP lease is known, run 'tofu refresh')"
  value       = local.node_ips
}

output "ssh_commands" {
  description = "SSH command to connect to each node"
  value = {
    for name, ip in local.node_ips : name => ip == null ? null : "ssh -i ${local.ssh_private_key_path} ubuntu@${ip}"
  }
}
