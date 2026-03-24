# homelab-platform

Reusable infrastructure primitives for Proxmox-based homelabs. Any project can use these to provision and configure VMs via a shared GitHub Actions infra runner.

---

## What's Here

| Path | What it is |
|------|-----------|
| `.github/workflows/provision-vm.yml` | Reusable workflow: Terraform + Ansible for any VM |
| `terraform/modules/proxmox-vm/` | Generic Proxmox VM module (cloud-init, DHCP via MAC) |
| `ansible/base-vm.yml` | Configures any service VM: Docker, runner, observability |
| `ansible/infra-runner.yml` | Configures the terraform-runner VM itself |
| `ansible/vars/main.yml` | Platform defaults |
| `ansible/templates/alloy-config.j2` | Grafana Alloy log shipping template |
| `configs/docker-compose/observability-vm.yml` | LGTM observability stack |
| `configs/alloy/alloy-config.alloy` | Static Alloy config (for manual deploys) |
| `docs/patterns/runner-tiers.md` | The infra/service runner tier model |
| `docs/nodes/terraform-runner/` | How to bootstrap the infra runner |
| `docs/nodes/observability-vm/` | How to deploy the LGTM stack |
| `docs/examples/new-node/` | Complete working example for a new VM node |
| `docs/troubleshooting/` | Common Proxmox provisioning and Ansible gotchas |
| `docs/decisions/` | Architecture decision records |
| `docs/observability/` | Observability stack overview and exporters |
| `docs/deployment/` | Runner management and multi-stage workflow patterns |

---

## Runner Tier Model

Two tiers — see [docs/patterns/runner-tiers.md](docs/patterns/runner-tiers.md) for full details.

| Label | VM | Does |
|-------|----|------|
| `self-hosted-infra` | terraform-runner | Runs Terraform + Ansible for all projects |
| `self-hosted-service` | any service VM | Hosts services; receives deployments |

---

## Using in a Project

### 1. Provision a VM

In your project repo, add a Terraform node config that uses the `proxmox-vm` module:

```hcl
# terraform/nodes/my-vm/main.tf
module "my_vm" {
  source = "github.com/BlakeHastings/homelab-platform//terraform/modules/proxmox-vm"

  vm_name    = "my-vm"
  vm_id      = 202
  mac_address = "BC:24:11:00:02:02"
  # ... other vars
}
```

Then call the reusable workflow:

```yaml
# .github/workflows/provision-my-vm.yml
jobs:
  provision:
    uses: BlakeHastings/homelab-platform/.github/workflows/provision-vm.yml@main
    with:
      vm_name: my-vm
      runner_label: self-hosted-service
      runner_repo_url: https://github.com/your-org/your-repo
      terraform_working_dir: terraform/nodes/my-vm
    secrets:
      PROXMOX_VE_ENDPOINT:         ${{ secrets.PROXMOX_VE_ENDPOINT }}
      PROXMOX_VE_API_TOKEN:        ${{ secrets.PROXMOX_VE_API_TOKEN }}
      PROXMOX_VE_SSH_USERNAME:     ${{ secrets.PROXMOX_VE_SSH_USERNAME }}
      PROXMOX_VE_SSH_PASSWORD:     ${{ secrets.PROXMOX_VE_SSH_PASSWORD }}
      ANSIBLE_PRIVATE_KEY:         ${{ secrets.ANSIBLE_PRIVATE_KEY }}
      GITHUB_ACTIONS_RUNNER_TOKEN: ${{ secrets.GITHUB_ACTIONS_RUNNER_TOKEN }}
      TF_VAR_PROXMOX_NODE:         ${{ secrets.TF_VAR_PROXMOX_NODE }}
      TF_VAR_TEMPLATE_ID:          ${{ secrets.TF_VAR_TEMPLATE_ID }}
      TF_VAR_GATEWAY:              ${{ secrets.TF_VAR_GATEWAY }}
      TF_VAR_SSH_PUBLIC_KEY:       ${{ secrets.TF_VAR_SSH_PUBLIC_KEY }}
# Note: secrets: inherit does NOT work cross-repo — each secret must be mapped explicitly
```

### 2. Deploy services to it

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: [self-hosted, self-hosted-service]
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up -d
```

---

## First-Time Setup

Bootstrap the terraform-runner once before anything else:
→ [docs/nodes/terraform-runner/01-bootstrap.md](docs/nodes/terraform-runner/01-bootstrap.md)

---

## Adding a New VM to a Project

See [docs/examples/new-node/](docs/examples/new-node/) for complete working templates.

If using Claude Code: run `/add-node` in your project repo.

---

## Documentation

| Topic | Location |
|-------|----------|
| Runner tier model | [docs/patterns/runner-tiers.md](docs/patterns/runner-tiers.md) |
| Bootstrap terraform-runner | [docs/nodes/terraform-runner/01-bootstrap.md](docs/nodes/terraform-runner/01-bootstrap.md) |
| Deploy LGTM observability | [docs/nodes/observability-vm/01-lgtm-stack.md](docs/nodes/observability-vm/01-lgtm-stack.md) |
| New VM example | [docs/examples/new-node/](docs/examples/new-node/) |
| Proxmox provisioning gotchas | [docs/troubleshooting/proxmox-provisioning.md](docs/troubleshooting/proxmox-provisioning.md) |
| Ansible common gotchas | [docs/troubleshooting/ansible-common-gotchas.md](docs/troubleshooting/ansible-common-gotchas.md) |
| Why dedicated infra runner | [docs/decisions/terraform-runner-architecture.md](docs/decisions/terraform-runner-architecture.md) |
| Secrets management | [docs/decisions/secrets-management.md](docs/decisions/secrets-management.md) |
| Observability overview | [docs/observability/overview.md](docs/observability/overview.md) |
| Exporters reference | [docs/observability/exporters.md](docs/observability/exporters.md) |
| Runner management | [docs/deployment/runner-management.md](docs/deployment/runner-management.md) |
| Multi-stage workflows | [docs/deployment/multi-stage-workflows.md](docs/deployment/multi-stage-workflows.md) |
