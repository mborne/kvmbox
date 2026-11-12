# Ansible inventory generated from the nodes (ansible all -m ping)
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/inventory/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/ansible/hosts.tftpl", {
    group                = var.vm_name_prefix
    nodes                = local.node_ips
    ssh_private_key_file = abspath("${path.module}/${local.ssh_private_key_path}")
  })
}
