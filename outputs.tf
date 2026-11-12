output "node_ips" {
  description = "IPv4 address of each node"
  value       = local.node_ips
}

output "ssh_commands" {
  description = "SSH command to connect to each node"
  value = {
    for name, ip in local.node_ips : name => "ssh -i ${local.ssh_private_key_path} ubuntu@${ip}"
  }
}

output "ansible_inventory" {
  description = "Path of the generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
