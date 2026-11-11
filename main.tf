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
      url = var.ubuntu_image_url
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

  # Désactive le confinement AppArmor de la VM (inutile/impossible sans AppArmor, ex. WSL2)
  sec_label = var.disable_apparmor ? [
    {
      model = "apparmor"
      type  = "none"
    }
  ] : null

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
        type = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.network_name
          }
        }
      }
    ]
    serials  = [{ type = "pty", target = { port = 0, type = "isa-serial" } }]
    graphics = [{ spice = { autoport = "yes" } }]
  }

  running = true
}
