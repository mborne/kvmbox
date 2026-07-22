terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "~> 0.9.0"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "kvmbox"
}

variable "vm_memory_mib" {
  type    = number
  default = 2048
}

variable "vm_vcpus" {
  type    = number
  default = 2
}

variable "vm_disk_size_bytes" {
  type    = number
  default = 21474836480
}

variable "storage_pool_name" {
  type    = string
  default = "default"
}

variable "ubuntu_password_hash" {
  type    = string
  # echo "ChangeIt" | mkpasswd -m sha-512 -s
  default = "$6$jG2acVK0aWkg1Nkz$0wuK5ZTYT3rtwru.LMnsgC2mKmoDMVijMoeCVkk8eOlW8j7Nz6PGlaxX2spMwon1FH.EvQBO1tlmZIJxMzrJm1"
}

locals {
  ubuntu_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

  ubuntu_image_name = basename(local.ubuntu_image_url)

  cloudinit_user_data = templatefile("${path.module}/cloud-init-user-data.yaml", {
    vm_name                = var.vm_name
    ubuntu_password_hash   = var.ubuntu_password_hash
  })

  cloudinit_meta_data = templatefile("${path.module}/cloud-init-meta-data.yaml", {
    vm_name = var.vm_name
  })

  cloudinit_network_config = templatefile("${path.module}/cloud-init-network-config.yaml", {})
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Image de base téléchargée une seule fois
resource "libvirt_volume" "ubuntu_base" {
  name = local.ubuntu_image_name
  pool = var.storage_pool_name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = local.ubuntu_image_url
    }
  }
}

# Disque de cloud-init généré à partir des données YAML
resource "libvirt_cloudinit_disk" "kvmbox" {
  name           = "${var.vm_name}-seed.iso"
  user_data      = local.cloudinit_user_data
  meta_data      = local.cloudinit_meta_data
  network_config = local.cloudinit_network_config
}

resource "libvirt_volume" "kvmbox_cloudinit" {
  name = "${var.vm_name}-cloudinit.iso"
  pool = var.storage_pool_name

  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.kvmbox.path
    }
  }
}

# Disque de la VM : copie COW de l'image de base
resource "libvirt_volume" "kvmbox_disk" {
  name     = "${var.vm_name}.os.qcow2"
  pool     = var.storage_pool_name
  capacity = var.vm_disk_size_bytes

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "kvmbox" {
  name   = var.vm_name
  type   = "kvm"
  memory = var.vm_memory_mib * 1024 # KiB en provider 0.9.x
  vcpu   = var.vm_vcpus

  sec_label = [
    {
      model = "apparmor"
      type  = "none"
    }
  ]

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
    # Désactive Secure Boot (libvirt 10+ l'active par défaut avec OVMF_CODE_4M.ms.fd)
    # Ordre alphabétique obligatoire (bug provider 0.9.x)
    firmware_info = {
      features = [
        { enabled = "no", name = "enrolled-keys" },
        { enabled = "no", name = "secure-boot" },
      ]
    }
  }

  devices = {
    disks = [
      {
        # Driver explicite obligatoire pour qcow2 en 0.9.x !
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = var.storage_pool_name
            volume = libvirt_volume.kvmbox_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device = "cdrom"
        driver = {
          name = "qemu"
          type = "raw"
        }
        source = {
          volume = {
            pool   = var.storage_pool_name
            volume = libvirt_volume.kvmbox_cloudinit.name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        type  = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
    serials = [{ type = "pty", target = { port = 0, type = "isa-serial" } }]
    graphics = [{ spice = { autoport = "yes" } }]
  }

  running = true
}