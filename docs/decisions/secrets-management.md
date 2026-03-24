# Decision: Secrets Management in CI

> Status: Active

## Decision

All secrets are passed to Ansible as `--extra-vars` via GitHub Actions secrets. Ansible Vault is not used in CI.

## The Two Approaches

### Approach A: Ansible Vault (file-based encryption)

```bash
# Local development
ansible-vault encrypt ansible/vars/secrets.yml
ansible-playbook ... --ask-vault-pass

# CI
ansible-playbook ... --vault-password-file /tmp/.vault_pass
```

Vault encrypts a YAML file containing secrets. The encrypted file can be committed to git. The vault password is stored as a GitHub secret and written to a temp file before each run.

### Approach B: GitHub Secrets as extra-vars (current)

```yaml
# In GitHub Actions workflow
- run: |
    ansible-playbook ... \
      -e "litellm_master_key=${{ secrets.LITELLM_MASTER_KEY }}" \
      -e "anthropic_api_key=${{ secrets.ANTHROPIC_API_KEY }}"
```

Secrets live only in GitHub. Ansible receives them as runtime variables. No encrypted file in the repo.

## Why Approach B

**Simpler CI setup.** No vault password file to write and clean up. GitHub Actions secrets are already the authoritative store for CI credentials — no need for a parallel Vault system.

**No accidental commits.** The risk with Vault is committing `secrets.yml` unencrypted or committing it when vault encryption wasn't applied. Extra-vars have no file to accidentally commit. (This happened once with Vault — required `git filter-repo` to purge.)

**Easier secret rotation.** Rotate a GitHub secret in the UI and the next workflow run uses the new value. With Vault, you'd re-encrypt the file and commit.

**Clear separation.** CI secrets live in GitHub (ephemeral, per-run). Local secrets live in `vars/secrets.yml` (gitignored, not committed). The playbook tries to load `vars/secrets.yml` with `ignore_errors: true` — it's used for manual runs and silently skipped in CI.

## Trade-offs

| Approach A (Vault) | Approach B (extra-vars) |
|---------------------|------------------------|
| Encrypted secrets in repo (auditable, version controlled) | Secrets in GitHub (GitHub is the single source of truth) |
| Works offline (no GitHub dependency) | Requires GitHub for CI |
| One password unlocks all secrets | Each secret managed individually |
| File can be accidentally committed | No file to accidentally commit |
| Secrets visible in `ps` output briefly | Secrets visible in `ps` output briefly |

## Local development

For manual playbook runs (not via CI), create `ansible/vars/secrets.yml` locally:

```yaml
# ansible/vars/secrets.yml — gitignored, never committed
litellm_master_key: "sk-..."
anthropic_api_key: "sk-ant-..."
openai_api_key: "sk-..."
```

The playbook loads it with `ignore_errors: true` — it's present locally, absent in CI.

Add to `.gitignore`:
```
ansible/vars/secrets.yml
```
