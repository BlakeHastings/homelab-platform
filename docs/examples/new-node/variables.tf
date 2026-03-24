# All variables are supplied via TF_VAR_* environment variables in GitHub Actions.
# No .tfvars files — secrets stay in GitHub Secrets, never on disk.

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
  description = "SSH public key for VM access (contents of ~/.ssh/homelab-deploy.pub)"
  type        = string
  sensitive   = true
}

# Overridable at runtime via workflow inputs → TF_VAR_* env vars
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
