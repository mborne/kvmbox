# KVMBOX

> **Work in progress** to replace [mborne/vagrantbox](https://github.com/mborne/vagrantbox) for [cours-devops](https://mborne.github.io/cours-devops/#2)

## Requirements

- Terraform or OpenTofu
- libvirt / KVM
- [Ansible](https://docs.ansible.com/) (optional, to use the generated inventory)

## Structure

| File                       | Content                                                                                 |
| -------------------------- | --------------------------------------------------------------------------------------- |
| `providers.tf`             | Terraform/OpenTofu and libvirt provider versions, provider configuration                |
| `variables.tf`             | Parameters (name, CPU, RAM, disk, image, network...) and locals (cloud-init rendering)  |
| `main.tf`                  | Resources: SSH key, storage pool, network, base image, cloud-init disk, VM disk, domain |
| `ansible.tf`               | Generated Ansible inventory (`inventory/hosts`)                                         |
| `outputs.tf`               | Outputs                                                                                 |
| `cloud-init/`              | cloud-init templates (`user-data`, `meta-data`, `network-config` with the fixed IP)     |
| `ansible/`                 | Ansible inventory template                                                              |
| `ansible.cfg`              | Ansible configuration (uses `inventory/`)                                               |
| `terraform.tfvars.example` | Example of variable overrides                                                           |

## Usage

With Terraform:

```bash
# download dependencies
terraform init
# create VMs
terraform apply
# destroy VM
terraform destroy
```

The number of nodes is set with `num_nodes` (default: 1), nodes are named `kvmbox-1`, `kvmbox-2`, ...:

```bash
terraform apply -var num_nodes=4
```

Nodes are attached to a dedicated NAT network `devbox` (`192.168.50.0/24`) with fixed IPs starting at `192.168.50.201` (same as vagrantbox), and can resolve each other by name (`kvmbox-2`, `kvmbox-2.devbox`). See `network_name`, `network_cidr` and `node_ip_start` variables.

An SSH key pair is generated in `.ssh/` (password authentication is disabled):

```bash
terraform output ssh_commands
ssh -i .ssh/id_ed25519 ubuntu@192.168.50.201
```

An Ansible inventory is generated in `inventory/hosts` (group `kvmbox`), `ansible.cfg` makes it the default inventory:

```bash
ansible all -m ping
```

## Resources

* https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/virsh-commandes/#le-vocabulaire-libvirt
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/terraform-libvirt/
