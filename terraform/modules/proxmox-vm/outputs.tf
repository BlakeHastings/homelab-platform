output "vm_ip" {
  description = "IPv4 address assigned to the VM by DHCP. Reported by qemu-guest-agent after boot. Used as Ansible inventory target."
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses[index(proxmox_virtual_environment_vm.vm.network_interface_names, "eth0")][0]
}

output "vm_id" {
  description = "Proxmox VMID"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "vm_name" {
  description = "VM hostname"
  value       = proxmox_virtual_environment_vm.vm.name
}
