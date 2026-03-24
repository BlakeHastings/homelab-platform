# Decision: Dedicated terraform-runner VM

> Status: Active

## Decision

All Terraform and Ansible execution runs on a dedicated `terraform-runner` VM, not on any service VM or the machine running the workloads.

## Why

**Service VMs should stay focused.** Running Terraform and Ansible on a machine that also hosts workloads (inference, agents, databases) creates competition for CPU, RAM, and disk I/O. When a provisioning job runs during peak inference load, something suffers.

**Terraform state must live somewhere stable.** With a local backend, state files live on the machine that runs Terraform. If that machine changes (or is the machine being provisioned), state becomes unreliable. A dedicated VM with a fixed IP and persistent disk gives state a permanent home at `/home/ubuntu/terraform-state/<node-name>/terraform.tfstate`.

**The bootstrap problem defines the architecture.** The terraform-runner can't provision itself — it's the only VM set up manually. This constraint makes it natural to give it a single, clear responsibility: run infrastructure tooling. All other VMs flow through it.

**Security.** The terraform-runner has credentials for Proxmox (API token + SSH password) and all managed VMs (SSH deploy key). Isolating these credentials on a dedicated VM limits the blast radius if any service VM is compromised.

## Trade-offs

| Pro | Con |
|-----|-----|
| Clean separation of infra ops from workloads | One more VM to maintain |
| State always co-located with Terraform execution | Manual bootstrap step required |
| Credential isolation | terraform-runner becoming unavailable blocks all provisioning |
| Service VMs stay lean | |

## Remote state alternative

If the terraform-runner VM is lost and state isn't backed up, Terraform loses track of managed resources. If this risk is unacceptable, the local backend can be replaced with Terraform Cloud (free tier, drop-in swap):

```hcl
# backend.tf — replace local backend with Terraform Cloud
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "your-workspace"
    }
  }
}
```

For a homelab where the Proxmox host is also backed up, losing the terraform-runner and recreating it (then re-importing resources with `terraform import`) is an acceptable recovery path.

## Sizing

The terraform-runner is intentionally lightweight: **2 CPU, 2GB RAM, 20GB disk**. Terraform and Ansible are not resource-intensive. The disk only needs to hold Terraform state files (kilobytes each) and the Ansible + Terraform binaries.
