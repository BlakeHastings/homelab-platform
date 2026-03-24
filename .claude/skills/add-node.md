---
name: add-node
description: Scaffold all files needed to provision a new VM node in this project using homelab-platform
---

The user wants to add a new VM node to this project. Help them scaffold the necessary files.

## Step 1: Gather requirements

Ask the user for the following if not already provided:
- **VM name** (e.g., `worker-01`) — will be used as the hostname and directory name
- **VMID** — must be unique in Proxmox (check existing nodes to avoid conflicts; compute-01 = 200, observability-vm = 201, so start at 202+)
- **MAC address** — must be unique; use the pattern `BC:24:11:00:02:XX` where XX increments per VM
- **Purpose** — what will run on this VM? (agents, services, databases, etc.)
- **Sizing** — CPU cores, memory MB, disk GB (or accept defaults: 2 CPU, 4096 MB, 40 GB)
- **GitHub repo URL** — the repo to register the runner to
- **Will this be the Portainer Server VM?** — only one VM should have `install_portainer_server: true`

## Step 2: Create Terraform node files

Create `terraform/nodes/<vm-name>/` with these 5 files based on the templates in `docs/examples/new-node/`:

1. `main.tf` — calls the proxmox-vm module with the VM's specific name, VMID, and MAC
2. `backend.tf` — local state backend at `/home/ubuntu/terraform-state/<vm-name>/terraform.tfstate`
3. `variables.tf` — standard variable declarations (proxmox_node, template_id, gateway, ssh_public_key, cpu_cores, memory_mb, disk_gb)
4. `versions.tf` — bpg/proxmox provider pin + Proxmox provider config
5. `outputs.tf` — vm_ip, vm_id, vm_name outputs

## Step 3: Create provisioning workflow

Create `.github/workflows/provision-<vm-name>.yml` based on `docs/examples/new-node/provision.yml`.

Set:
- `vm_name` to the VM name
- `cpu_cores`, `memory_mb`, `disk_gb` to the chosen sizing
- `runner_label` to `self-hosted-service` (standard for service VMs)
- `runner_repo_url` to the GitHub repo URL provided
- `terraform_working_dir` to `terraform/nodes/<vm-name>`
- `install_portainer_server` to `true` only if this is the designated Portainer management VM

## Step 4: Remind the user what to do next

After creating the files, tell the user:

1. **Set the DHCP reservation** in their router for the MAC address before provisioning (or the VM will get a random IP)
2. **Update `GITHUB_ACTIONS_RUNNER_TOKEN`** secret in GitHub repo settings immediately before triggering (expires 1 hour after generation)
3. **Trigger the workflow**: Actions → Provision `<vm-name>` → Run workflow
4. **After provisioning**: update their Prometheus scrape config with the new VM's IP
5. If this is the first VM: they need to bootstrap the terraform-runner first — see `docs/nodes/terraform-runner/01-bootstrap.md`

## Notes

- Reference `docs/examples/new-node/` for the exact file templates
- Reference `docs/troubleshooting/proxmox-provisioning.md` if anything goes wrong
- The MAC address scheme `BC:24:11:00:02:XX` is a convention — any locally-administered unicast MAC works (second hex digit must be 2, 6, A, or E for locally administered)
