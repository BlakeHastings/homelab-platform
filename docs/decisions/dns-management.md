# Decision: DNS Management in Terraform

> Status: Active

## Decision

DNS records are managed in Terraform via the `kenske/technitium` provider.
Two pieces, split deliberately:

1. **`terraform/modules/dns-record/`** (this repo) — a thin reusable module
   wrapping the provider's `technitium_dns_zone_record`. Any Terraform root
   can compose it next to `module "proxmox-vm"`.
2. **The `lan` primary zone** itself — created once and owned by
   `homelab-services/services/dns/terraform-config/`, never duplicated.

The reusable `.github/workflows/provision-vm.yml` workflow accepts a
`create_dns_record: bool` input. When `true`, it loads
`/technitium/` from Infisical alongside `/proxmox/`, `/terraform/`,
`/ansible/`, and forwards `TECHNITIUM_HOST` / `TECHNITIUM_TOKEN` to the
Terraform apply step as `TF_VAR_technitium_*`.

## Why composable, not integrated into `proxmox-vm`

`proxmox-vm` callers aren't all the same. Some VMs are ephemeral
(test runners, throwaway experiments) and shouldn't pollute the
authoritative DNS zone. Some homelab installations may not have Technitium
at all and would still want to use `proxmox-vm`.

Integrating DNS into `proxmox-vm` would force every caller to either
configure the `technitium` provider or special-case it with `count = 0`
plumbing — friction for the common case. Keeping the modules separate
lets callers opt in by writing two `module` blocks instead of one.

The reusable workflow's `create_dns_record` flag is the matching
opt-in at the CI layer: non-DNS callers don't need `/technitium/` access in
Infisical.

## Why the zone lives in `homelab-services`, not here

The zone is a singleton — its SOA, refresh interval, allowed-update
policy, and existence are all single-point-of-truth concerns. If two roots
declared `technitium_dns_zone "primary"`, the second `terraform apply`
would fight the first.

`homelab-services` is the natural owner because the DNS *service*
(Technitium itself) is deployed there. Records, on the other hand, live
naturally with the thing they describe — the consumer's VM Terraform.

## Why `kenske/technitium`

Surveyed four community Technitium providers in May 2026:

| Provider | Scope | Verdict |
|----------|-------|---------|
| `kenske/technitium` | zones, records, DHCP scopes, DHCP reservations | **chosen** — broad enough, room to grow into DHCP |
| `kevynb/technitium` | records only (no zones) | too narrow |
| `darkhonor/technitium` | zones, records, block lists, server settings, STIG mode | STIG opinions add overhead a homelab won't use |
| `chinyongcy/technitium` | zones, records | smaller surface than kenske, similar feature set |

Pinned to `~> 0.2.2` (latest as of Nov 2025). Single-maintainer risk is
real; fallback if the provider goes unmaintained is direct API calls via
`null_resource` + `local-exec curl` against
[Technitium's HTTP API](https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md).

## Known gaps (managed in the UI for now)

`kenske/technitium` v0.2.2 does not model:

- **Forwarders / recursion settings** — Technitium's default (pure
  recursion to root servers) is what most homelabs want anyway. Set
  upstream forwarders via the UI if you need to.
- **Block lists** — UI: DNS → Blocked Zones → Block Lists.

Both change rarely. If they ever need code-management, the
`null_resource` + Technitium API escape hatch is the path.

## Bootstrap is one-time and manual

Terraform cannot mint its own API token; a human must log in once to the
Technitium UI to create the `terraform` user and generate a token. The
runbook lives at
[`homelab-services/services/dns/BOOTSTRAP.md`](https://github.com/BlakeHastings/homelab-services/blob/main/services/dns/BOOTSTRAP.md).
