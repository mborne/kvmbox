# KVMBOX

> **Work in progress** to replace [mborne/vagrantbox](https://github.com/mborne/vagrantbox) for [cours-devops](https://mborne.github.io/cours-devops/#2)

## Requirements

- Terraform or OpenTofu
- libvirt / KVM
- [Ansible](https://docs.ansible.com/) (optional, to use the generated inventory)

## Structure

| File                       | Content                                                                                |
| -------------------------- | -------------------------------------------------------------------------------------- |
| `providers.tf`             | Terraform/OpenTofu and libvirt provider versions, provider configuration               |
| `variables.tf`             | Parameters (name, CPU, RAM, disk, image, network...) and locals (cloud-init rendering) |
| `main.tf`                  | Resources: base image, cloud-init disk, VM disk, domain                                |
| `ansible.tf`               | Generated Ansible inventory (`inventory/hosts`)                                        |
| `outputs.tf`               | Outputs                                                                                |
| `cloud-init/`              | cloud-init templates (`user-data`, `meta-data`, `network-config`)                      |
| `ansible/`                 | Ansible inventory template                                                             |
| `ansible.cfg`              | Ansible configuration (uses `inventory/`)                                              |
| `terraform.tfvars.example` | Example of variable overrides                                                          |

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

The number of nodes is set with `num_nodes` (default: 1), nodes are named `kvmbox-01`, `kvmbox-02`, ...:

```bash
terraform apply -var num_nodes=3
```

An SSH key pair is generated in `.ssh/` (password authentication is disabled):

```bash
terraform output ssh_commands
ssh -i .ssh/id_ed25519 ubuntu@$(terraform output -json node_ips | jq -r '."kvmbox-01"')
```

An Ansible inventory is generated in `inventory/hosts` (group `kvmbox`), `ansible.cfg` makes it the default inventory:

```bash
ansible all -m ping
```

## Resources

* https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/virsh-commandes/#le-vocabulaire-libvirt
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/terraform-libvirt/
