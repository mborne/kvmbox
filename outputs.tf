output "vm_name" {
  description = "Name of the libvirt domain"
  value       = libvirt_domain.kvmbox.name
}
