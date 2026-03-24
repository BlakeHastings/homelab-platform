# Runner Management

> Status: Active

---

## Runner Labels

The two-tier label scheme (see [runner-tiers.md](../patterns/runner-tiers.md)):

| Runner | Labels | VM |
|--------|--------|----|
| Infra runner | `self-hosted`, `self-hosted-infra` | terraform-runner |
| Service VMs | `self-hosted`, `self-hosted-service` | compute-01, observability-vm, etc. |

Workflows target runners by label:

```yaml
# Provisioning jobs — always on infra runner
runs-on: [self-hosted, self-hosted-infra]

# Service deployments — any available service VM
runs-on: [self-hosted, self-hosted-service]

# GPU-specific jobs — service VM with GPU
runs-on: [self-hosted, self-hosted-service, gpu]
```

---

## Runner Token Management

GitHub runner registration tokens **expire 1 hour** after generation. Generate one immediately before triggering a provisioning workflow — not in advance.

**Generate a token:**
> GitHub → repo → Settings → Actions → Runners → New self-hosted runner → copy the `--token` value

The token is passed to the provisioning workflow as a GitHub secret:

```yaml
# In your provisioning workflow trigger
secrets:
  GITHUB_ACTIONS_RUNNER_TOKEN: ${{ secrets.GITHUB_ACTIONS_RUNNER_TOKEN }}
```

Update the `GITHUB_ACTIONS_RUNNER_TOKEN` secret in GitHub repo settings immediately before triggering the workflow.

---

## Runner Registration (Ansible)

Runner installation and registration is handled by the `runner` phase in `base-vm.yml` (service VMs) and `infra-runner.yml` (terraform-runner). It runs automatically as part of `provision-vm.yml`.

To re-register a runner manually (e.g., after token refresh):

```bash
ansible-playbook -i "<VM_IP>," ansible/base-vm.yml \
  --tags runner \
  -e "ansible_user=ubuntu" \
  -e "ansible_ssh_private_key_file=~/.ssh/homelab-deploy" \
  -e "runner_label=self-hosted-service" \
  -e "github_actions_runner_url=https://github.com/your-org/your-repo" \
  -e "github_actions_runner_token=<FRESH_TOKEN>"
```

---

## Maintenance Commands

Runner service names follow the pattern:
`actions.runner.<org>-<repo>.<hostname>`

```bash
# Find the exact service name
systemctl list-units | grep actions.runner

# Check status
sudo systemctl status actions.runner.<org>-<repo>.<hostname>

# Follow logs
journalctl -u actions.runner.<org>-<repo>.<hostname> -f

# Restart
sudo systemctl restart actions.runner.<org>-<repo>.<hostname>
```

---

## Runner Goes Offline

If a runner shows as offline in GitHub Actions, SSH to the VM and check:

```bash
# Is the service running?
sudo systemctl status actions.runner.*

# What does the runner log say?
journalctl -u actions.runner.* -n 50

# Check if the runner process is alive
ps aux | grep Runner.Listener
```

Common causes:
- VM was rebooted but runner service failed to start → `sudo systemctl start actions.runner.*`
- Token expired during initial registration → re-register with a fresh token
- GitHub connectivity issue → check outbound network from VM
