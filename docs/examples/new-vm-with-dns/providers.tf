# Proxmox provider — credentials from /proxmox/ in Infisical (loaded by the
# reusable provision-vm workflow). See env vars: PROXMOX_VE_ENDPOINT etc.
provider "proxmox" {
  insecure = true   # homelab self-signed TLS certificate
}

# Technitium provider — credentials from /technitium/ in Infisical, loaded
# automatically by provision-vm.yml when create_dns_record: true.
# Variables are populated via TF_VAR_technitium_host / TF_VAR_technitium_token
# set by the workflow.
provider "technitium" {
  host  = var.technitium_host
  token = var.technitium_token
}
