# Troubleshooting: Ansible Common Gotchas

> Status: Active

Issues encountered running Ansible against homelab machines.

---

## Ansible not found after installing via `uv`

`uv tool install ansible-core` places binaries in `~/.local/share/uv/tools/ansible-core/bin/`. This path is not automatically on `PATH` in GitHub Actions runners or non-interactive SSH sessions.

**Fix:** Always use full paths in scripts, or add to `.bashrc`:

```bash
export PATH="$HOME/.local/share/uv/tools/ansible-core/bin:$PATH"
```

The `infra-runner.yml` playbook adds this to `.bashrc` during setup.

In the GitHub Actions workflow, Ansible is invoked with the full path or the runner's `.bashrc` is sourced first.

---

## Docker group membership not picked up mid-playbook

After adding a user to the `docker` group, the change does not take effect for the current SSH session. Subsequent tasks that run Docker commands will fail with "permission denied".

**Fix:** Use `meta: reset_connection` immediately after the group change:

```yaml
- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: true
  become: true

- name: Reset connection to pick up docker group
  meta: reset_connection
```

---

## `sudo` timestamp collision when running `become` tasks

When multiple Ansible tasks run `become: true` in rapid succession, `sudo` timestamp caching can cause authentication failures.

**Fix:** Run `sudo -v` (refresh sudo credentials) before executing the playbook when doing a manual run:

```bash
sudo -v && ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

---

## Jinja2 syntax in inventory files breaks parsing

Ansible inventory files are parsed with Jinja2. If a hostname or variable contains `{` or `}`, it triggers a template error.

**Fix:** Use dynamic inventory (pass `-i "HOST,"` on the command line) or escape the characters. The provisioning workflow always passes inventory dynamically:

```bash
ansible-playbook -i "$VM_IP," ...
```

---

## Reboot handling during driver installation

When NVIDIA drivers are installed, a reboot is required. Ansible can trigger the reboot, but the playbook itself will lose connection and fail if it tries to continue immediately.

The `inference-setup.yml` playbook handles this by intentionally failing after the reboot task with a clear message, requiring the operator to re-run with `--skip-tags disk,drivers` after the machine comes back up.

This is simpler and more reliable than trying to automatically wait for the reboot in the playbook.

---

## Runner registration token expires in 1 hour

GitHub Actions runner registration tokens expire 1 hour after generation. Always generate the token immediately before running the `runner` tag:

```bash
# Generate fresh token from: GitHub → repo → Settings → Actions → Runners → New self-hosted runner
ansible-playbook ... --tags runner -e "github_actions_runner_token=<FRESH_TOKEN>"
```

Do not store the token in `vars/main.yml` — it will be stale by the time it's used.

---

## `vars/secrets.yml` accidentally committed

If `ansible/vars/secrets.yml` gets committed (even vault-encrypted), it needs to be fully purged from git history — not just deleted in a follow-up commit.

**Fix:** Use `git filter-repo` to remove the file from all history:

```bash
pip install git-filter-repo
git filter-repo --path ansible/vars/secrets.yml --invert-paths
git push --force-with-lease
```

**Prevention:** The pattern of passing all secrets as `--extra-vars` in CI (rather than using vault files) avoids this risk entirely. Vault files are for manual local runs only and should be in `.gitignore`.

---

## `community.docker` collection not found

The `community.docker` Ansible collection must be installed separately — it is not included with `ansible-core`. The `infra-runner.yml` playbook installs it:

```bash
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
```

If running manually on a new machine, run these before any playbook that uses `community.docker.docker_container`.
