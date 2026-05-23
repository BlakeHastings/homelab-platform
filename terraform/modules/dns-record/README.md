# `dns-record` module

Creates a single A record in an existing Technitium primary zone. Thin
wrapper around the [`kenske/technitium`](https://registry.terraform.io/providers/kenske/technitium/latest)
provider's `technitium_dns_zone_record` resource.

The zone itself is **not** created here — that's a singleton owned by
[`homelab-services/services/dns/terraform-config/`](https://github.com/BlakeHastings/homelab-services/tree/main/services/dns/terraform-config).
This module is for records that should live with the thing they describe
(typically a VM provisioned by the `proxmox-vm` module in the same root).

See [`docs/decisions/dns-management.md`](../../../docs/decisions/dns-management.md)
for the design rationale.

## Usage

This is a child module — the caller's root must configure the `technitium`
provider. The full pattern, copy-pasteable, lives in
[`docs/examples/new-vm-with-dns/`](../../../docs/examples/new-vm-with-dns/).
Minimal version:

```hcl
terraform {
  required_providers {
    technitium = {
      source  = "kenske/technitium"
      version = "~> 0.2.2"
    }
  }
}

provider "technitium" {
  host  = var.technitium_host   # e.g. "http://192.168.0.250:5380"
  token = var.technitium_token  # from Infisical /technitium/
}

module "vm" {
  source  = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm?ref=main"
  vm_name = "zoe-vm"
  # ...
}

module "dns" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/dns-record?ref=main"

  hostname = module.vm.vm_name
  ip       = module.vm.vm_ip
  zone     = "lan"
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `hostname` | string | — | Bare hostname; combined with `zone` to form the FQDN. Must match `^[a-z0-9][a-z0-9-]*$`. |
| `ip` | string | — | A-record target. |
| `zone` | string | `"lan"` | Primary zone name. Must already exist in Technitium. |
| `ttl` | number | `3600` | Record TTL in seconds. |

## Outputs

| Name | Description |
|------|-------------|
| `fqdn` | `"${hostname}.${zone}"` — e.g. `"zoe-vm.lan"`. |
| `ip` | Echoes `var.ip`. |

## Required Infisical access

The calling repo's GitHub Actions machine identity needs **read** on the
`/technitium/` path in the homelab Infisical project to pull
`TECHNITIUM_HOST` and `TECHNITIUM_TOKEN` at workflow time. Grant this
once per repo that uses the module.
