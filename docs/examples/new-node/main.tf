# my-vm — Example VM using the proxmox-vm module
#
# REPLACE: vm_name, vm_id, mac_address with values for your VM.
#
# MAC address is fixed so your router assigns a stable IP via DHCP reservation.
# After first apply, set the DHCP reservation in your router for this MAC.

module "vm" {
  # Reference the module from homelab-platform via git source
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm?ref=main"

  vm_name        = "my-vm"           # REPLACE: VM hostname
  vm_id          = 202               # REPLACE: unique Proxmox VMID
  target_node    = var.proxmox_node
  template_id    = var.template_id
  cpu_cores      = var.cpu_cores
  memory_mb      = var.memory_mb
  disk_gb        = var.disk_gb
  mac_address    = "BC:24:11:00:02:02"  # REPLACE: unique MAC for DHCP reservation
  dns_servers    = [var.gateway]        # use router as DNS resolver
  ssh_public_key = var.ssh_public_key
}

output "vm_ip" {
  description = "VM IP — used by Ansible and referenced in network topology docs"
  value       = module.vm.vm_ip
}

output "vm_id" {
  value = module.vm.vm_id
}

output "vm_name" {
  value = module.vm.vm_name
}
