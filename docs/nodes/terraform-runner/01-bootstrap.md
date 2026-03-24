# terraform-runner — Bootstrap Guide

> Status: Active

The `terraform-runner` is a lightweight Proxmox VM dedicated to running Terraform and Ansible for all VM provisioning across all projects. It's the only VM in the cluster that is bootstrapped manually — after it exists, every other VM is provisioned by GitHub Actions running on it.

**Why a dedicated VM?** Service VMs should stay lean and focused on their workloads. Terraform + Ansible work happens here instead. See [runner-tiers.md](../../patterns/runner-tiers.md).

---

## What It Runs

| Service | Purpose |
|---------|---------|
| GitHub Actions runner (`self-hosted-infra`) | Executes all provisioning workflows |
| Terraform binary | Provisions VMs on Proxmox |
| Ansible + collections | Configures VMs after provisioning |
| Portainer Agent (:9001) | Visible in Portainer Server on management VM |
| Node Exporter (:9100) | System metrics → Prometheus |
| Grafana Alloy | Logs → Loki on observability-vm |

Terraform state files live at `/home/ubuntu/terraform-state/<node-name>/` on this VM.

---

## One-Time Prerequisites (do these before bootstrap)

### 1. Ubuntu 24.04 Cloud-Init Template (VMID 9000)

Run on the **Proxmox host**:

```bash
# Download Ubuntu 24.04 cloud image
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Create template VM
qm create 9000 --name ubuntu-2404-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm resize 9000 scsi0 +28G   # total ~30GB
```

Start the VM temporarily, then SSH in and run:

```bash
apt install -y qemu-guest-agent && systemctl enable qemu-guest-agent

# Clear machine-id so all clones get unique IDs and DHCP leases
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Disable predictable network interface names
ln -s /dev/null /etc/systemd/network/99-default.link

# Clean up
apt clean && cloud-init clean
shutdown -h now
```

Convert to template:

```bash
qm template 9000
```

Enable snippets on `local` storage: **Proxmox UI → Datacenter → Storage → local → Edit → check Snippets**. This is required for Terraform to upload cloud-init user-data files.

---

### 2. Proxmox API Token for Terraform

Run on the **Proxmox host**:

```bash
pveum user add terraform@pam
pveum acl modify / -user terraform@pam -role PVEVMAdmin
pveum acl modify /storage/local -user terraform@pam -role PVEDatastoreAdmin
pveum acl modify /storage/local-lvm -user terraform@pam -role PVEDatastoreAdmin
```

In the **Proxmox web UI**: Datacenter → Permissions → API Tokens → Add:
- User: `terraform@pam`
- Token ID: `ci-token`
- Uncheck "Privilege Separation"

Copy the token string — it is shown **only once**: `terraform@pam!ci-token=<uuid>`

---

### 3. Deploy SSH Keypair

Run on your **dev machine**:

```bash
ssh-keygen -t ed25519 -C "homelab-deploy" -f ~/.ssh/homelab-deploy -N ""
```

- **`~/.ssh/homelab-deploy.pub`** → GitHub Secret `TF_VAR_SSH_PUBLIC_KEY`
- **`~/.ssh/homelab-deploy`** (private key contents) → GitHub Secret `ANSIBLE_PRIVATE_KEY`

---

### 4. GitHub Secrets

Add these to your project repo (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `PROXMOX_VE_ENDPOINT` | `https://<proxmox-ip>:8006` |
| `PROXMOX_VE_API_TOKEN` | `terraform@pam!ci-token=<uuid>` |
| `PROXMOX_VE_SSH_USERNAME` | `root` |
| `PROXMOX_VE_SSH_PASSWORD` | Proxmox root SSH password |
| `TF_VAR_PROXMOX_NODE` | Your Proxmox node name (e.g., `pve`) |
| `TF_VAR_TEMPLATE_ID` | `9000` (VMID of the Ubuntu template) |
| `TF_VAR_GATEWAY` | Your router IP (e.g., `192.168.1.1`) |
| `TF_VAR_SSH_PUBLIC_KEY` | Contents of `~/.ssh/homelab-deploy.pub` |
| `ANSIBLE_PRIVATE_KEY` | Contents of `~/.ssh/homelab-deploy` |
| `GITHUB_ACTIONS_RUNNER_TOKEN` | Fresh token per run (generate just before) |

> **GITHUB_ACTIONS_RUNNER_TOKEN** expires 1 hour after generation. Generate it from:
> GitHub → Settings → Actions → Runners → New self-hosted runner → copy the token from the `--token` flag.

---

## Bootstrap the terraform-runner VM

### Step 1 — Create VM in Proxmox

In the **Proxmox web UI**:
1. Right-click VMID 9000 (ubuntu-2404-template) → Clone
2. Set name: `terraform-runner`, VMID: `100` (or any available ID)
3. Clone type: Full Clone
4. Storage: local-lvm
5. Click Clone

After cloning:
- Open the VM → Hardware → Add → CloudInit Drive → storage: local
- Open the VM → Cloud-Init tab:
  - User: `ubuntu`
  - IP Config: Static, set to e.g. `192.168.1.20/24`, Gateway: `192.168.1.1`
- Start the VM

Wait ~60 seconds for cloud-init to complete, then test SSH:
```bash
ssh ubuntu@192.168.1.20
```

### Step 2 — Generate a fresh GitHub runner token

In GitHub: your repo → Settings → Actions → Runners → New self-hosted runner → copy the `--token` value.

### Step 3 — Run the bootstrap playbook

Clone `homelab-platform` to your dev machine, then from the repo root:

```bash
ansible-playbook -i "192.168.1.20," ansible/infra-runner.yml \
  --ask-become-pass \
  -e "ansible_user=ubuntu" \
  -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
  -e "runner_label=self-hosted-infra" \
  -e "github_actions_runner_url=https://github.com/BlakeHastings/homelab-platform" \
  -e "github_actions_runner_token=<YOUR_FRESH_TOKEN>"
```

After the `docker` phase completes, you may need to reconnect for the docker group to take effect:
```bash
# Re-run skipping docker phase if you hit docker permission errors
ansible-playbook ... --skip-tags docker
```

### Step 4 — Verify

In GitHub: your repo → Settings → Actions → Runners — the `terraform-runner` should appear as **Idle** with labels `self-hosted, self-hosted-infra`.

---

## Next Steps

With the infra runner online, all other VMs can be provisioned via GitHub Actions:

1. Add Terraform node configs to your project repo (using the `proxmox-vm` module)
2. Add a workflow that calls `homelab-platform/provision-vm.yml`
3. Set all GitHub Secrets listed above
4. Trigger the workflow — the infra runner picks it up and provisions the VM
