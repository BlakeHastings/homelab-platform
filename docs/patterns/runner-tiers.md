# Runner Tier Model

> Status: Active

GitHub Actions self-hosted runners in this homelab follow a two-tier model. Every VM is either an **infra runner** or a **service VM** — never both.

---

## Tiers

| Tier | Label | VM | Does |
|------|-------|----|------|
| **Infra runner** | `self-hosted-infra` | terraform-runner | Runs Terraform + Ansible against all other VMs |
| **Service VM** | `self-hosted-service` | compute-01, observability-vm, inference-machine, etc. | Hosts running services; receives deployments |

---

## Infra Runner

There is **one** infra runner shared across all projects. It is the only VM bootstrapped manually (see `docs/nodes/terraform-runner/`). After it exists, every other VM is provisioned and configured by GitHub Actions workflows running on it.

**Why a dedicated VM?**
- Needs LAN access to the Proxmox API
- Stores Terraform state on disk — state must persist between runs
- Has Terraform and Ansible installed — not appropriate on a service host

**Any project** can provision VMs using this runner by calling the reusable workflow:

```yaml
uses: BlakeHastings/homelab-platform/.github/workflows/provision-vm.yml@main
```

---

## Service VMs

Service VMs are the targets of provisioning. They:
1. Get provisioned by the infra runner (Terraform creates the VM, Ansible configures it)
2. Run services via Docker Compose
3. Register a GitHub Actions runner so deployment workflows can target them directly

Service VMs never run Terraform or Ansible. All infrastructure operations originate from the infra runner.

---

## Workflow Flow

```
push to project repo
        │
        ▼
[infra runner: self-hosted-infra]
  terraform apply  → VM created in Proxmox
  ansible-playbook → Docker, runner, Alloy installed
        │
        ▼
[service VM runner registered with: self-hosted-service]
        │
        ▼
[deploy workflow runs-on: self-hosted-service]
  docker compose pull + up
```

---

## Adding a New Project

1. Add Terraform config in your project repo using the `proxmox-vm` module from `homelab-platform`
2. Call `provision-vm.yml` from your project's workflow
3. Set `runner_label: self-hosted-service` (or a more specific label for targeted deploys)
4. Deployment workflows target `runs-on: [self-hosted, self-hosted-service]`
