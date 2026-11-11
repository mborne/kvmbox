# KVMBOX

> **Work in progress** to replace [mborne/vagrantbox](https://github.com/mborne/vagrantbox) for [cours-devops](https://mborne.github.io/cours-devops/#2)

## Requirements

- Terraform or OpenTofu
- libvirt / KVM

## Structure

| Fichier | Contenu |
|---|---|
| `providers.tf` | Versions de Terraform/OpenTofu, provider libvirt et sa configuration |
| `variables.tf` | Paramètres (nom, CPU, RAM, disque, image, réseau...) et locals (rendu cloud-init) |
| `main.tf` | Ressources : image de base, disque cloud-init, disque VM, domaine |
| `outputs.tf` | Sorties |
| `templates/` | Templates cloud-init (`user-data`, `meta-data`, `network-config`) |
| `terraform.tfvars.example` | Exemple de surcharge des variables |

## Usage

With Terraform :

```bash
# download dependencies
terraform init
# create VMs
terraform apply
# destroy VM
terraform destroy
```

## Resources

* https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/virsh-commandes/#le-vocabulaire-libvirt
* https://blog.stephane-robert.info/docs/virtualiser/type1/kvm/terraform-libvirt/
