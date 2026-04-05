# Plugin Checklist — my-plugin

Pre-release and quality checklist. Complete all items before tagging a release.

## Version and metadata

- [ ] All version-bearing files in sync: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `gemini-extension.json`, package manifest
- [ ] `CHANGELOG.md` has an entry for the new version
- [ ] README version badge is correct (if present)

## Configuration

- [ ] `.env.example` documents every environment variable the server reads
- [ ] `.env.example` has no actual secrets — only placeholders
- [ ] `.env` is in `.gitignore` and `.dockerignore`

## Documentation

- [ ] `CLAUDE.md` is current and matches repo structure
- [ ] `README.md` has up-to-date tool reference and environment variable table
- [ ] Skills have `SKILL.md` with correct frontmatter
- [ ] Setup instructions work from a clean clone

## Security

- [ ] No credentials in code, docs, or git history
- [ ] `.gitignore` includes `.env`, `*.secret`, credentials files
- [ ] `.dockerignore` includes `.env`, `.git/`, `*.secret`
- [ ] Hooks enforce permissions: `sync-env.sh`, `fix-env-perms.sh`, `ensure-ignore-files.sh`
- [ ] Destructive actions gated behind `confirm=True`
- [ ] `/health` endpoint is unauthenticated; all other endpoints require bearer auth
- [ ] Container runs as non-root (UID 1000)
- [ ] No baked environment variables in Docker image

## Build and test

- [ ] Docker image builds: `just build`
- [ ] Docker healthcheck passes: `just health`
- [ ] CI pipeline passes: lint, typecheck, test
- [ ] Live integration test passes: `just test-live`
- [ ] Pre-commit hooks configured and passing

## Deployment

- [ ] `docker-compose.yml` uses correct image tag and port
- [ ] `entrypoint.sh` is executable and handles env rewriting
- [ ] SWAG/reverse-proxy config tested (if applicable)

## Registry (if publishing)

- [ ] `server.json` for MCP registry is valid
- [ ] Package published to registry (PyPI / npm / GHCR)
- [ ] DNS verification for `tv.tootie/my-plugin` (if applicable)

## Marketplace (if applicable)

- [ ] Entry in `claude-homelab` marketplace manifest
- [ ] Plugin installs correctly: `/plugin marketplace add jmagar/claude-homelab`
