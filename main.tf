# SSH key pair used to connect to the VM (ssh -i .ssh/id_ed25519 ubuntu@<node-ip>)
resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  filename             = "${path.module}/${local.ssh_private_key_path}"
  content              = tls_private_key.ssh.private_key_openssh
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "ssh_public_key" {
  filename             = "${path.module}/${local.ssh_private_key_path}.pub"
  content              = tls_private_key.ssh.public_key_openssh
  file_permission      = "0644"
  directory_permission = "0700"
}

# Dedicated storage pool for the project volumes
resource "libvirt_pool" "kvmbox" {
  name = var.storage_pool_name
  type = "dir"

  target = {
    path = var.storage_pool_path
  }

  create = {
    build     = true
    start     = true
    autostart = true
  }

  destroy = {
    delete = true
  }
}

# Base image, downloaded only once
resource "libvirt_volume" "ubuntu_base" {
  name = local.ubuntu_image_name
  pool = libvirt_pool.kvmbox.name

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

# cloud-init disk generated from the YAML templates (one per node)
resource "libvirt_cloudinit_disk" "node" {
  for_each = local.cloudinit

  name           = "${each.key}-seed.iso"
  user_data      = each.value.user_data
  meta_data      = each.value.meta_data
  network_config = local.cloudinit_network_config
}

resource "libvirt_volume" "node_cloudinit" {
  for_each = libvirt_cloudinit_disk.node

  name = "${each.key}-cloudinit.iso"
  pool = libvirt_pool.kvmbox.name

  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = each.value.path
    }
  }
}

# Node disk: copy-on-write overlay of the base image
resource "libvirt_volume" "node_disk" {
  for_each = toset(local.node_names)

  name     = "${each.key}.os.qcow2"
  pool     = libvirt_pool.kvmbox.name
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

resource "libvirt_domain" "node" {
  for_each = toset(local.node_names)

  name   = each.key
  type   = "kvm"
  memory = var.vm_memory_mib * 1024 # KiB with provider 0.9.x
  vcpu   = var.vm_vcpus

  # Disable AppArmor confinement of the VM (not possible on hosts without AppArmor, e.g. WSL2)
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
    # Disable Secure Boot (enabled by default since libvirt 10 with OVMF_CODE_4M.ms.fd)
    # Alphabetical order required (provider 0.9.x bug)
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
        # Explicit driver required for qcow2 with provider 0.9.x!
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = libvirt_pool.kvmbox.name
            volume = libvirt_volume.node_disk[each.key].name
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
            pool   = libvirt_pool.kvmbox.name
            volume = libvirt_volume.node_cloudinit[each.key].name
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
