# Pre-commit Hook Configuration

Pre-commit hooks for `my-plugin-mcp`. These run locally before each commit and are also enforced in CI.

## Setup

<!-- scaffold:specialize -->

**Python repos** (`.pre-commit-config.yaml`):

```bash
pre-commit install
```

**TypeScript repos** (`lefthook.yml`):

```bash
lefthook install
```

## Hook Configuration

### Python — .pre-commit-config.yaml

```yaml
repos:
  - repo: local
    hooks:
      - id: plugin-validate
        name: Validate plugin manifest
        entry: bash scripts/lint-plugin.sh
        language: system
        pass_filenames: false

      - id: docker-security
        name: Dockerfile security check
        entry: bash scripts/check-docker-security.sh Dockerfile
        language: system
        pass_filenames: false
        files: Dockerfile

      - id: no-baked-env
        name: No baked env vars in Docker
        entry: bash scripts/check-no-baked-env.sh .
        language: system
        pass_filenames: false

      - id: ensure-ignore-files
        name: Ensure .env in ignore files
        entry: bash scripts/ensure-ignore-files.sh --check .
        language: system
        pass_filenames: false
```

### TypeScript — lefthook.yml

```yaml
pre-commit:
  commands:
    plugin-validate:
      run: bash scripts/lint-plugin.sh
    docker-security:
      glob: "Dockerfile*"
      run: bash scripts/check-docker-security.sh Dockerfile
    no-baked-env:
      run: bash scripts/check-no-baked-env.sh .
    ensure-ignore-files:
      run: bash scripts/ensure-ignore-files.sh --check .
```

## Hook Scripts

All scripts live in `scripts/`. Each exits non-zero on failure.

| Script | Purpose |
|--------|---------|
| `lint-plugin.sh` | Validates plugin manifests (`plugin.json` schema, required fields) |
| `check-docker-security.sh` | Lints Dockerfile: non-root user, no `ADD` from URL, no `latest` base tags |
| `check-no-baked-env.sh` | Ensures no `ENV` directives in Dockerfile contain secrets |
| `ensure-ignore-files.sh` | Verifies `.env` appears in `.gitignore` and `.dockerignore` |
| `check-outdated-deps.sh` | Warns on outdated dependencies (advisory, non-blocking) |

## CI Enforcement

The same scripts run in the `docker-security` and `contract-drift` CI jobs (see [CICD.md](CICD.md)), so issues caught by hooks are also caught in CI even if a developer skips hooks.

## Bypassing Hooks

```bash
# Skip all hooks (emergency only)
git commit --no-verify -m "hotfix: ..."
```

Not recommended. CI will still fail on violations.

## Related Docs

- [CICD.md](CICD.md) — same checks in CI
- [DEPLOY.md](DEPLOY.md) — Dockerfile conventions enforced by hooks
- [ENV.md](ENV.md) — environment variable patterns
