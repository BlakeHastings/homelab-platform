# Example: new VM that also registers a DNS A record

Mirrors [`new-node/`](../new-node/) but composes the `proxmox-vm` and
`dns-record` modules in one Terraform root so a VM and its
`<name>.lan` A record are created (and destroyed) together.

## Files

| File | Purpose |
|------|---------|
| `versions.tf` | Declares both `bpg/proxmox` and `kenske/technitium` provider requirements |
| `providers.tf` | Configures both providers (technitium reads creds from variables) |
| `variables.tf` | All TF_VAR_* inputs, including `technitium_host` / `technitium_token` |
| `backend.tf` | Local state on terraform-runner |
| `main.tf` | `module "vm"` then `module "dns"` — wires `module.vm.vm_ip` into the DNS record |
| `provision.yml` | Example workflow — sets `create_dns_record: true` on the reusable `provision-vm.yml` |

## How it differs from `new-node/`

1. Adds the `kenske/technitium` provider.
2. Adds a `module "dns"` block alongside `module "vm"`.
3. Workflow passes `create_dns_record: true`, which tells
   `provision-vm.yml@main` to also load `/technitium/` from Infisical and
   expose `TECHNITIUM_HOST` / `TECHNITIUM_TOKEN` to the Terraform apply.

## Prerequisites

- The `lan` zone must already exist in Technitium. It's created and owned
  by [homelab-services/services/dns/terraform-config/](https://github.com/BlakeHastings/homelab-services/tree/main/services/dns/terraform-config).
- The Infisical machine identity for the calling repo must have **read**
  on the `/technitium/` path (one-time grant per repo).

See [`docs/decisions/dns-management.md`](../../decisions/dns-management.md)
for the design rationale.
