# `dns-record` module

Creates a single **A** or **CNAME** record in an existing Technitium primary
zone. Thin wrapper around the
[`kenske/technitium`](https://registry.terraform.io/providers/kenske/technitium/latest)
provider's `technitium_dns_zone_record` resource.

The zone itself is **not** created here — that's a singleton owned by
[`homelab-services/services/dns/terraform-config/`](https://github.com/BlakeHastings/homelab-services/tree/main/services/dns/terraform-config).
This module is for records that live with the thing they describe.

See [`docs/decisions/dns-management.md`](../../../docs/decisions/dns-management.md)
for the design rationale.

## Two modes

Exactly **one** of `ip` or `cname` must be set. Setting both, or neither, is
a validation error at plan time.

### Mode 1: A record (`ip`)

Use when the IP is pinned (DHCP reservation, static assignment, external
service). The record points directly at the address.

```hcl
module "dns" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/dns-record?ref=main"

  hostname = module.vm.vm_name   # → my-vm.lan
  ip       = module.vm.vm_ip
  zone     = "lan"
}
```

⚠️ **Fragile to DHCP changes.** If the VM's IP changes (lease renewal
without a reservation), this record goes stale until you re-apply
terraform. Use Mode 2 instead unless you've got DHCP reservations or a
truly static IP.

### Mode 2: CNAME (`cname`) — preferred for VMs

Use when you want a friendly alias that follows another name. The CNAME
itself never changes; resolution chains to the target, whose A record
updates on each DHCP renewal (router auto-registration handles this for
VMs whose hostname matches `<name>-vm`).

```hcl
module "dns" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/dns-record?ref=main"

  hostname = "zoe"                  # → zoe.lan
  cname    = "${module.vm.vm_name}.lan"  # → zoe-vm.lan (router-auto-registered)
  zone     = "lan"
}
```

The CNAME is stable forever. Only the underlying A record on `zoe-vm.lan`
moves when DHCP changes, and the router pushes that update for free.

## When to skip this module entirely

If the canonical hostname (`<name>-vm.lan`) is fine as the name users
type, don't use this module at all — the router's DHCP→Technitium
auto-registration handles it for free. Add the module only when you want
a different / friendlier alias.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `hostname` | string | — | Bare hostname; combined with `zone` to form the FQDN. Must match `^[a-z0-9][a-z0-9-]*$`. |
| `ip` | string | `null` | A-record target. Mutually exclusive with `cname`. |
| `cname` | string | `null` | CNAME target FQDN. Mutually exclusive with `ip`. |
| `zone` | string | `"lan"` | Primary zone name. Must already exist in Technitium. |
| `ttl` | number | `3600` | Record TTL in seconds. |

## Outputs

| Name | Description |
|------|-------------|
| `fqdn` | `"${hostname}.${zone}"`. |
| `ip` | Echoes `var.ip` (null for CNAME mode). |
| `cname` | Echoes `var.cname` (null for A mode). |
| `type` | `"A"` or `"CNAME"`. |

## Required Infisical access

The calling repo's GitHub Actions machine identity needs **read** on the
`/technitium/` path in the homelab Infisical project to pull
`TECHNITIUM_HOST` and `TECHNITIUM_TOKEN` at workflow time. Grant this
once per repo that uses the module.
