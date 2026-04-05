variable "proxmox_node" {
  description = "Proxmox node name (e.g., pve)"
  type        = string
}

variable "template_id" {
  description = "VMID of the Ubuntu 24.04 cloud-init template"
  type        = number
  default     = 9000
}

variable "gateway" {
  description = "Network gateway IP (e.g., 192.168.1.1)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 4096
}

variable "disk_gb" {
  type    = number
  default = 30
}
