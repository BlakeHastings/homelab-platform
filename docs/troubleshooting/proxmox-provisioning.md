# Troubleshooting: Proxmox VM Provisioning

> Status: Active

Gotchas encountered when using the `bpg/proxmox` Terraform provider and cloud-init with Proxmox.

---

## `terraform apply` hangs waiting for VM IP

**Cause:** `qemu-guest-agent` is not installed in the cloud-init template.

The `bpg/proxmox` provider detects the VM's assigned IP by querying the QEMU guest agent after boot. If the agent isn't running, Terraform polls indefinitely.

**Fix:** During template creation, before converting to template:

```bash
apt install -y qemu-guest-agent
systemctl enable qemu-guest-agent
```

The `cloud-init.yaml.tpl` in the `proxmox-vm` module installs it automatically, but the template VM itself must have it or the very first boot will fail before cloud-init runs.

---

## All cloned VMs get the same DHCP IP

**Cause:** The template has a populated `/etc/machine-id`. All clones inherit it, so DHCP sees them as the same machine.

**Fix:** Before converting the VM to a template:

```bash
# Clear machine-id — each clone will generate a unique one on first boot
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Disable predictable network interface names (avoids eth0 vs ens3 inconsistency)
ln -s /dev/null /etc/systemd/network/99-default.link

apt clean && cloud-init clean
shutdown -h now
```

Then: `qm template 9000`

---

## Cloud-init snippet upload fails: "storage does not support content type"

**Cause:** The `bpg` provider uploads cloud-init snippets to Proxmox `local` storage. Proxmox's `local-lvm` (LVM thin pool) only supports `images` and `rootdir` content types — it can't store snippet files.

**Fix:**
1. Use `local` (directory-backed) storage for snippets, not `local-lvm`
2. Enable Snippets content type: **Proxmox UI → Datacenter → Storage → local → Edit → check Snippets**

The `proxmox-vm` module hardcodes `datastore_id = "local"` for snippet upload — this is intentional.

---

## `bpg/proxmox` provider requires SSH in addition to API token

Unlike `telmate/proxmox`, the `bpg` provider needs SSH access to the Proxmox host to upload the cloud-init snippet file. Both `PROXMOX_VE_SSH_USERNAME` and `PROXMOX_VE_SSH_PASSWORD` must be set.

These are passed as GitHub secrets in the provisioning workflow.

---

## Why `bpg/proxmox` instead of `telmate/proxmox`

`telmate/proxmox` is effectively abandoned — no meaningful updates in years, many open issues. `bpg/proxmox` is actively maintained and works correctly with modern Proxmox versions. Version is pinned at `~> 0.99.0` in the module.

---

## VM self-signed TLS certificate warning

Proxmox ships with a self-signed certificate. The Terraform provider config includes `insecure = true` to suppress TLS errors. This is expected and safe in a LAN environment where you control the Proxmox host.

---

## Runner token expires before provisioning completes

The `GITHUB_ACTIONS_RUNNER_TOKEN` used in the Ansible runner registration phase expires **1 hour** after generation. If the token expires mid-run (e.g., Terraform takes a long time to provision), Ansible's runner registration will fail.

**Fix:** Generate the token immediately before triggering the workflow, not in advance.

> GitHub → repo → Settings → Actions → Runners → New self-hosted runner → copy the `--token` value

---

## `secrets: inherit` does not work cross-repo

`secrets: inherit` only works when calling a reusable workflow from within the **same repository**. When calling `homelab-platform/.github/workflows/provision-vm.yml` from another repo, each secret must be mapped explicitly:

```yaml
secrets:
  PROXMOX_VE_ENDPOINT: ${{ secrets.PROXMOX_VE_ENDPOINT }}
  PROXMOX_VE_API_TOKEN: ${{ secrets.PROXMOX_VE_API_TOKEN }}
  # ... etc
```

For personal GitHub accounts (no org-level secrets), duplicate all secrets in each project repo.

The shorthand `secrets: inherit` works within the same org or same repo only.
