# Multi-Stage Deployment Workflows

> Status: Active

Some deployments require infrastructure to be in a specific state before the application can be deployed. The two-job pattern handles this cleanly.

---

## Pattern: Prepare → Deploy

```yaml
jobs:
  prepare:
    name: Prepare infrastructure
    runs-on: [self-hosted, self-hosted-infra]
    steps:
      # ... ensure required resources exist

  deploy:
    name: Deploy service
    runs-on: [self-hosted, self-hosted-service]
    needs: prepare    # <-- waits for prepare to succeed
    steps:
      # ... deploy the service
```

The `needs:` keyword ensures `deploy` only runs if `prepare` succeeds.

---

## Example: Provision VM → Deploy Service

A common pattern for first-time deployments:

```yaml
jobs:
  provision:
    uses: BlakeHastings/homelab-platform/.github/workflows/provision-vm.yml@main
    with:
      vm_name: my-vm
      runner_label: self-hosted-service
      runner_repo_url: https://github.com/your-org/your-repo
      terraform_working_dir: terraform/nodes/my-vm
    secrets: inherit

  deploy:
    runs-on: [self-hosted, self-hosted-service]
    needs: provision
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up -d
```

Note: `provision` registers a new runner on the VM. That runner picks up the `deploy` job because both are labeled `self-hosted-service`. If you have multiple service VMs, any available one picks up the job — use a more specific label if you need a particular VM.

---

## Example: Ensure Model Loaded → Deploy Agent

For inference workloads, ensure the required model is in VRAM before starting an agent that depends on it:

```yaml
jobs:
  provision-model:
    name: Ensure model is loaded
    runs-on: [self-hosted, self-hosted-service, gpu]
    steps:
      - name: Load model
        run: |
          if lms ls | grep -q "MyModel"; then
            echo "Model present, skipping download"
          else
            lms get "org/MyModel-GGUF"
          fi
          lms load "MyModel" --gpu max --ttl 3600

  deploy-agent:
    name: Deploy agent
    runs-on: [self-hosted, self-hosted-service]
    needs: provision-model
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up -d --remove-orphans
```

---

## Job Outputs Across Stages

Pass data between jobs using `outputs`:

```yaml
jobs:
  provision:
    outputs:
      vm_ip: ${{ steps.get-ip.outputs.vm_ip }}
    steps:
      - id: get-ip
        run: echo "vm_ip=$(terraform output -raw vm_ip)" >> $GITHUB_OUTPUT

  configure:
    needs: provision
    steps:
      - run: echo "Configuring ${{ needs.provision.outputs.vm_ip }}"
```

`provision-vm.yml` uses this to pass the VM IP from Terraform to Ansible.
