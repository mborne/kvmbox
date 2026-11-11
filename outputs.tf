output "vm_name" {
  description = "Nom du domaine libvirt"
  value       = libvirt_domain.kvmbox.name
}
