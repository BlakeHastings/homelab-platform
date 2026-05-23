# All variables are supplied via TF_VAR_* environment variables from the
# reusable provision-vm workflow. Do not commit a .tfvars file.

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
  description = "Network gateway IP (e.g., 192.168.0.1)"
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
  default = 40
}

# --- Technitium (DNS) credentials ---
# Populated by provision-vm.yml when create_dns_record: true.

variable "technitium_host" {
  description = "Technitium DNS server base URL (e.g. http://192.168.0.250:5380)"
  type        = string
}

variable "technitium_token" {
  description = "API token for the 'terraform' Technitium user"
  type        = string
  sensitive   = true
}
