variable "libvirt_uri" {
  description = "URI de connexion à libvirt"
  type        = string
  default     = "qemu:///system"
}

variable "storage_pool_name" {
  description = "Pool de stockage libvirt utilisé pour les volumes"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Réseau libvirt auquel est rattachée la VM"
  type        = string
  default     = "default"
}

variable "disable_apparmor" {
  description = "Désactive le confinement AppArmor de la VM (nécessite un hôte avec AppArmor actif)"
  type        = bool
  default     = false
}

variable "ubuntu_image_url" {
  description = "URL de l'image cloud Ubuntu servant d'image de base"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_name" {
  description = "Nom de la VM (domaine libvirt et hostname)"
  type        = string
  default     = "kvmbox"
}

variable "vm_memory_mib" {
  description = "Mémoire allouée à la VM (MiB)"
  type        = number
  default     = 2048
}

variable "vm_vcpus" {
  description = "Nombre de vCPU"
  type        = number
  default     = 2
}

variable "vm_disk_size_bytes" {
  description = "Taille du disque système (octets)"
  type        = number
  default     = 21474836480 # 20 GiB
}

variable "ubuntu_password_hash" {
  description = "Hash SHA-512 du mot de passe de l'utilisateur ubuntu (echo \"ChangeIt\" | mkpasswd -m sha-512 -s)"
  type        = string
  default     = "$6$jG2acVK0aWkg1Nkz$0wuK5ZTYT3rtwru.LMnsgC2mKmoDMVijMoeCVkk8eOlW8j7Nz6PGlaxX2spMwon1FH.EvQBO1tlmZIJxMzrJm1"
}

locals {
  ubuntu_image_name = basename(var.ubuntu_image_url)

  cloudinit_user_data = templatefile("${path.module}/templates/cloud-init-user-data.yaml.tftpl", {
    vm_name              = var.vm_name
    ubuntu_password_hash = var.ubuntu_password_hash
  })

  cloudinit_meta_data = templatefile("${path.module}/templates/cloud-init-meta-data.yaml.tftpl", {
    vm_name = var.vm_name
  })

  cloudinit_network_config = file("${path.module}/templates/cloud-init-network-config.yaml")
}
