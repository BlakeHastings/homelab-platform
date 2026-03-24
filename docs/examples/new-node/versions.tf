terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.99.0"
    }
  }
}

# Proxmox provider — all credentials loaded from environment variables.
# Set these before running terraform apply (or let GitHub Actions inject them):
#   PROXMOX_VE_ENDPOINT      — https://<proxmox-ip>:8006
#   PROXMOX_VE_API_TOKEN     — terraform@pam!ci-token=<uuid>
#   PROXMOX_VE_SSH_USERNAME  — root  (needed for cloud-init snippet upload)
#   PROXMOX_VE_SSH_PASSWORD  — <proxmox root ssh password>
provider "proxmox" {
  insecure = true   # homelab self-signed TLS certificate
}
