variable "vm_name" {
  description = "VM hostname and Proxmox VM name"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VMID. Must be unique across the cluster."
  type        = number
}

variable "target_node" {
  description = "Proxmox node name where the VM will be created (e.g., pve)"
  type        = string
}

variable "template_id" {
  description = "VMID of the Ubuntu 24.04 cloud-init template to clone from (default: 9000)"
  type        = number
  default     = 9000
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_gb" {
  description = "Root disk size in GB"
  type        = number
  default     = 20
}

variable "datastore_id" {
  description = "Proxmox datastore for the VM disk (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "mac_address" {
  description = "Fixed MAC address for the VM NIC (e.g., BC:24:11:AA:BB:01). Set a DHCP reservation in your router for this MAC to get a stable IP."
  type        = string
}

variable "dns_servers" {
  description = "List of DNS server IPs"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ssh_public_key" {
  description = "SSH public key to inject via cloud-init (contents of homelab-deploy.pub)"
  type        = string
  sensitive   = true
}
