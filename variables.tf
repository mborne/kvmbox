variable "libvirt_uri" {
  description = "libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

variable "storage_pool_name" {
  description = "Name of the dedicated libvirt storage pool created for the volumes"
  type        = string
  default     = "kvmbox"
}

variable "storage_pool_path" {
  description = "Directory of the storage pool on the host (created by libvirtd)"
  type        = string
  default     = "/var/lib/libvirt/images/kvmbox"
}

variable "network_name" {
  description = "libvirt network the VM is attached to"
  type        = string
  default     = "default"
}

variable "disable_apparmor" {
  description = "Disable AppArmor confinement of the VM (requires a host with AppArmor enabled)"
  type        = bool
  default     = false
}

variable "http_proxy" {
  description = "HTTP proxy for APT in the VM (empty to disable)"
  type        = string
  default     = ""
}

variable "https_proxy" {
  description = "HTTPS proxy for APT in the VM (empty to disable)"
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "Comma-separated list of hosts/domains bypassing the proxy (set in /etc/environment, not used by APT)"
  type        = string
  default     = "localhost,127.0.0.1"
}

variable "ubuntu_image_url" {
  description = "URL of the Ubuntu cloud image used as base image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_name" {
  description = "VM name (libvirt domain and hostname)"
  type        = string
  default     = "kvmbox"
}

variable "vm_memory_mib" {
  description = "Memory allocated to the VM (MiB)"
  type        = number
  default     = 2048
}

variable "vm_vcpus" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "vm_disk_size_bytes" {
  description = "System disk size (bytes)"
  type        = number
  default     = 21474836480 # 20 GiB
}

variable "ubuntu_password_hash" {
  description = "SHA-512 hash of the ubuntu user password (echo \"ChangeIt\" | mkpasswd -m sha-512 -s)"
  type        = string
  default     = "$6$jG2acVK0aWkg1Nkz$0wuK5ZTYT3rtwru.LMnsgC2mKmoDMVijMoeCVkk8eOlW8j7Nz6PGlaxX2spMwon1FH.EvQBO1tlmZIJxMzrJm1"
}

locals {
  ubuntu_image_name = basename(var.ubuntu_image_url)

  cloudinit_user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    vm_name              = var.vm_name
    ubuntu_password_hash = var.ubuntu_password_hash
    http_proxy           = var.http_proxy
    https_proxy          = var.https_proxy
    no_proxy             = var.no_proxy
  })

  cloudinit_meta_data = templatefile("${path.module}/cloud-init/meta-data.yaml.tftpl", {
    vm_name = var.vm_name
  })

  cloudinit_network_config = file("${path.module}/cloud-init/network-config.yaml")
}
