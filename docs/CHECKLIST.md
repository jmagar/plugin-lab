# Pre-Release Quality Checklist

Use this checklist before releasing a plugin built with plugin-lab, or before cutting a new release of plugin-lab itself.

## Version Sync

- [ ] All version-bearing files have the same version string
- [ ] `CHANGELOG.md` has an entry for the current version
- [ ] Run `bash scripts/check-version-sync.sh` -- exits 0

Files to check:
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `gemini-extension.json`
- Package manifest (`Cargo.toml`, `package.json`, or `pyproject.toml`)

## Manifests

- [ ] `.claude-plugin/plugin.json` has all required fields (name, version, description)
- [ ] `.codex-plugin/plugin.json` has `interface.displayName`
- [ ] `userConfig` entries have `type`, `title`, `description`, and `sensitive` attributes
- [ ] No generic (unprefixed) env var names in `userConfig`

## Security

- [ ] No credentials in code, docs, or commit history
- [ ] `.env` is in `.gitignore`
- [ ] `.env` is in `.dockerignore`
- [ ] `entrypoint.sh` validates all required env vars before starting
- [ ] No secrets baked into Docker image
- [ ] `~/.claude-homelab/.env` has `chmod 600`

## Docker

- [ ] Multi-stage Dockerfile (builder + runtime)
- [ ] Non-root user in runtime stage
- [ ] `docker-compose.yaml` uses `env_file:` (not inline `environment:`)
- [ ] `docker-compose.yaml` has a `healthcheck`
- [ ] `/health` endpoint returns HTTP 200

## CI/CD

- [ ] `.github/workflows/ci.yaml` runs lint, type-check, test
- [ ] `.github/workflows/publish-image.yaml` builds and pushes to GHCR
- [ ] `.github/workflows/release-on-main.yaml` creates tags and GitHub releases
- [ ] Live tests have a skip guard (`SKIP_LIVE_TESTS=1`)

## Plugin Surfaces

- [ ] Skills have `SKILL.md` with correct frontmatter (`name`, `description`)
- [ ] Agents have YAML frontmatter with `name`, `description`, `model`, `tools`
- [ ] Commands have frontmatter with `description`, `argument-hint`, `allowed-tools`
- [ ] Hook scripts exist and are executable
- [ ] `README.md` covers install, config, usage, and tool reference
- [ ] `CLAUDE.md` describes repo conventions and tool names

## Validation Commands

```bash
# Version sync
bash scripts/check-version-sync.sh

# Ignore file coverage
bash scripts/ensure-ignore-files.sh --check

# No baked env vars in Docker
bash scripts/check-no-baked-env.sh

# Docker security
bash scripts/check-docker-security.sh

# Outdated dependencies
bash scripts/check-outdated-deps.sh
```
