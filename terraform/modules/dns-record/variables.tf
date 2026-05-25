# Inputs for a single record in a Technitium primary zone.
#
# Two modes — exactly one of `ip` or `cname` must be set:
#   - ip:    creates an A record at <hostname>.<zone> pointing at the IP.
#            Use when the target IP is pinned (DHCP reservation, static
#            assignment, or external service).
#   - cname: creates a CNAME at <hostname>.<zone> pointing at another name.
#            Use when you want a friendly alias that follows an underlying
#            auto-registered hostname (e.g. dashboard.lan → dashboard-vm.lan).
#            Resilient to DHCP IP changes — the CNAME doesn't move, only
#            the target's A record does.
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
  description = "A-record target (IPv4). Mutually exclusive with var.cname. Set this when the IP is pinned."
  type        = string
  default     = null
}

variable "cname" {
  description = "CNAME target (FQDN of the canonical name to alias). Mutually exclusive with var.ip. Set this for a friendly alias that follows another record."
  type        = string
  default     = null
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
