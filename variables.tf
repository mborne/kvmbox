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
  description = "libvirt network the nodes are attached to"
  type        = string
  default     = "default"
}

variable "disable_apparmor" {
  description = "Disable AppArmor confinement of the nodes (requires a host with AppArmor enabled)"
  type        = bool
  default     = false
}

variable "http_proxy" {
  description = "HTTP proxy for APT in the nodes (empty to disable)"
  type        = string
  default     = ""
}

variable "https_proxy" {
  description = "HTTPS proxy for APT in the nodes (empty to disable)"
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "Comma-separated list of hosts/domains bypassing the proxy (set in /etc/environment, not used by APT)"
  type        = string
  default     = "localhost,127.0.0.1"
}

variable "ssh_key_dir" {
  description = "Directory where the generated SSH key pair is written (relative to the module)"
  type        = string
  default     = ".ssh"
}

variable "ubuntu_image_url" {
  description = "URL of the Ubuntu cloud image used as base image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "num_nodes" {
  description = "Number of nodes to create (equivalent of VAGRANTBOX_NUM_NODES)"
  type        = number
  default     = 1

  validation {
    condition     = var.num_nodes >= 1 && var.num_nodes <= 99 && floor(var.num_nodes) == var.num_nodes
    error_message = "num_nodes must be an integer between 1 and 99."
  }
}

variable "vm_name_prefix" {
  description = "Prefix of the node names (libvirt domain and hostname): <prefix>-1, <prefix>-2, ..."
  type        = string
  default     = "kvmbox"
}

variable "vm_memory_mib" {
  description = "Memory allocated to each node (MiB)"
  type        = number
  default     = 2048
}

variable "vm_vcpus" {
  description = "Number of vCPUs of each node"
  type        = number
  default     = 2
}

variable "vm_disk_size_bytes" {
  description = "System disk size of each node (bytes)"
  type        = number
  default     = 21474836480 # 20 GiB
}

locals {
  ubuntu_image_name = basename(var.ubuntu_image_url)

  ssh_private_key_path = "${var.ssh_key_dir}/id_ed25519"

  node_names = [for i in range(1, var.num_nodes + 1) : format("%s-%d", var.vm_name_prefix, i)]

  cloudinit = {
    for name in local.node_names : name => {
      user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
        vm_name        = name
        ssh_public_key = trimspace(tls_private_key.ssh.public_key_openssh)
        http_proxy     = var.http_proxy
        https_proxy    = var.https_proxy
        no_proxy       = var.no_proxy
      })
      meta_data = templatefile("${path.module}/cloud-init/meta-data.yaml.tftpl", {
        vm_name = name
      })
    }
  }

  cloudinit_network_config = file("${path.module}/cloud-init/network-config.yaml")
}
