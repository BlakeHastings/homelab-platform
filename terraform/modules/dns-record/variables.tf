# Inputs for a single A record in a Technitium primary zone.
#
# The zone itself must already exist — see homelab-services/services/dns
# for the singleton "lan" zone owned by the DNS service.

variable "hostname" {
  description = "Bare hostname (left of the dot). Combined with var.zone to form the FQDN, e.g. \"zoe-vm\" → \"zoe-vm.lan\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.hostname))
    error_message = "hostname must be lowercase letters, digits, and hyphens (no dots, no leading hyphen)."
  }
}

variable "ip" {
  description = "IPv4 address the A record points at — typically module.vm.vm_ip from the proxmox-vm module."
  type        = string
}

variable "zone" {
  description = "Primary zone name this record lives in. Must already exist in Technitium."
  type        = string
  default     = "lan"
}

variable "ttl" {
  description = "Record TTL in seconds."
  type        = number
  default     = 3600
}
