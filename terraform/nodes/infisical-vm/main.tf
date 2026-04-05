# infisical-vm — Self-hosted Infisical secrets manager
#
# Platform infrastructure VM. Provides centralized secret storage
# for all provisioning workflows, replacing per-repo GitHub Secrets.
#
# After provisioning:
#   1. Set DHCP reservation in router for MAC BC:24:11:00:01:01
#   2. Open http://<VM_IP> and complete the Infisical setup wizard
#   3. Create a project and add all homelab secrets
#   4. Create a machine identity token for the terraform-runner

module "vm" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm?ref=main"

  vm_name        = "infisical-vm"
  vm_id          = 119
  target_node    = var.proxmox_node
  template_id    = var.template_id
  cpu_cores      = var.cpu_cores
  memory_mb      = var.memory_mb
  disk_gb        = var.disk_gb
  mac_address    = "BC:24:11:00:01:01"
  dns_servers    = [var.gateway]
  ssh_public_key = var.ssh_public_key
}

output "vm_ip" {
  description = "Infisical VM IP — set DHCP reservation for BC:24:11:00:01:01 in your router"
  value       = module.vm.vm_ip
}

output "vm_id" {
  value = module.vm.vm_id
}

output "vm_name" {
  value = module.vm.vm_name
}
