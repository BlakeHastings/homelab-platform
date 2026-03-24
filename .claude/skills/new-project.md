---
name: new-project
description: Scaffold a new project repo that provisions VMs via homelab-platform
---

The user wants to create a new project that uses homelab-platform for VM provisioning. Help them set up the minimum viable structure.

## Step 1: Gather requirements

Ask the user for:
- **Project name** (e.g., `my-app`)
- **GitHub repo URL** (e.g., `https://github.com/BlakeHastings/my-app`)
- **VMs needed** — for each VM: name, purpose, VMID, sizing
- **Does this project need observability?** — if yes, recommend provisioning an observability VM or pointing at an existing one

## Step 2: Create the project structure

Create the following files in the current directory (or a subdirectory if specified):

### For each VM the user needs:

**`terraform/nodes/<vm-name>/main.tf`**
```hcl
module "vm" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm?ref=main"
  vm_name        = "<vm-name>"
  vm_id          = <vmid>
  target_node    = var.proxmox_node
  template_id    = var.template_id
  cpu_cores      = var.cpu_cores
  memory_mb      = var.memory_mb
  disk_gb        = var.disk_gb
  mac_address    = "<mac>"
  dns_servers    = [var.gateway]
  ssh_public_key = var.ssh_public_key
}
output "vm_ip" { value = module.vm.vm_ip }
output "vm_id" { value = module.vm.vm_id }
output "vm_name" { value = module.vm.vm_name }
```

**`terraform/nodes/<vm-name>/backend.tf`** — local state on terraform-runner

**`terraform/nodes/<vm-name>/variables.tf`** — standard variables (copy from example)

**`terraform/nodes/<vm-name>/versions.tf`** — bpg/proxmox provider

**`.github/workflows/provision-<vm-name>.yml`** — calls `homelab-platform/provision-vm.yml@main` with explicit secret mapping

### Project-level files:

**`README.md`** — brief description, links to provisioning docs

**`.gitignore`**:
```
ansible/vars/secrets.yml
*.tfstate
*.tfstate.backup
.terraform/
```

## Step 3: Explain what GitHub Secrets to add

Tell the user to add these to their GitHub repo secrets:

| Secret | Description |
|--------|-------------|
| `PROXMOX_VE_ENDPOINT` | `https://<proxmox-ip>:8006` |
| `PROXMOX_VE_API_TOKEN` | `terraform@pam!ci-token=<uuid>` |
| `PROXMOX_VE_SSH_USERNAME` | `root` |
| `PROXMOX_VE_SSH_PASSWORD` | Proxmox root SSH password |
| `TF_VAR_PROXMOX_NODE` | Proxmox node name |
| `TF_VAR_TEMPLATE_ID` | `9000` |
| `TF_VAR_GATEWAY` | Router IP |
| `TF_VAR_SSH_PUBLIC_KEY` | Contents of `~/.ssh/homelab-deploy.pub` |
| `ANSIBLE_PRIVATE_KEY` | Contents of `~/.ssh/homelab-deploy` |
| `GITHUB_ACTIONS_RUNNER_TOKEN` | Generate fresh before each provisioning run |

## Step 4: Remind them about prerequisites

Before any provisioning workflow will work:

1. **terraform-runner must be bootstrapped** — see `homelab-platform/docs/nodes/terraform-runner/01-bootstrap.md`
2. **Proxmox Ubuntu 24.04 template must exist** (VMID 9000)
3. **DHCP reservation set** in router for each VM's MAC address
4. **Fresh runner token** generated immediately before triggering workflow

## Notes

- The terraform-runner is shared — it serves all projects. No need to provision a new one per project.
- `secrets: inherit` does NOT work cross-repo. Each secret must be explicitly mapped in the workflow.
- See `homelab-platform/docs/troubleshooting/` for common issues.
