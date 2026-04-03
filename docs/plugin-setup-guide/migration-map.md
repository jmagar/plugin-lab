# Plugin Setup Guide Migration Map

This map preserves a one-to-one checklist against `docs/plugin-setup-guide.md` without modifying the original file.

## Keep Together In The New Entry Docs

Move these sections into the new overview docs:
- `Architecture Overview`
- `Deployment Modes — Local & Docker`
- `Directory Layout`
- `Adding a New Plugin (Checklist)`
- `Credential Flow Diagram`

## Move Into Implementation Standards

Move these sections into standards-oriented docs or template guidance:
- `` `.cache/` Convention ``
- `Language Toolchain Standards`
- `HTTP Security — Bearer Tokens`
- `Tool Design — Action + Subaction Pattern`
- `Code Architecture`
- `Destructive Operations — Confirmation Gate`
- `Middleware & Server Hardening`
- `Validation Checklist`

## Move Into File Templates / File Reference

Map these sections into the shared template root and language-specific implementation roots under `~/workspace/plugin-templates/`:
- `File-by-File Reference`
- `Mode Detection`
- `MCP Mode — Tool Reference`
- `HTTP Fallback Mode`
- `Instructions`
- `Codex CLI Compatibility`

Primary target files:
- `~/workspace/plugin-templates/.claude-plugin/plugin.json`
- `~/workspace/plugin-templates/.claude-plugin/marketplace.json`
- `~/workspace/plugin-templates/.agents/plugins/marketplace.json`
- `~/workspace/plugin-templates/.codex-plugin/plugin.json`
- `~/workspace/plugin-templates/.app.json`
- `~/workspace/plugin-templates/.mcp.json`
- `~/workspace/plugin-templates/.env.example`
- `~/workspace/plugin-templates/my-service.subdomain.conf`
- `~/workspace/plugin-templates/CHANGELOG.md`
- `~/workspace/plugin-templates/skills/`
- `~/workspace/plugin-templates/agents/`
- `~/workspace/plugin-templates/commands/`
- `~/workspace/plugin-templates/hooks/`
- `~/workspace/plugin-templates/scripts/`

Language-variant target files:
- `~/workspace/plugin-templates/py/README.md`, `~/workspace/plugin-templates/ts/README.md`, `~/workspace/plugin-templates/rs/README.md`
- `~/workspace/plugin-templates/py/Dockerfile`, `~/workspace/plugin-templates/ts/Dockerfile`, `~/workspace/plugin-templates/rs/Dockerfile`
- `~/workspace/plugin-templates/py/entrypoint.sh`, `~/workspace/plugin-templates/ts/entrypoint.sh`, `~/workspace/plugin-templates/rs/entrypoint.sh`
- `~/workspace/plugin-templates/py/Justfile`, `~/workspace/plugin-templates/ts/Justfile`, `~/workspace/plugin-templates/rs/Justfile`
- `~/workspace/plugin-templates/py/docker-compose.yaml`, `~/workspace/plugin-templates/ts/docker-compose.yaml`, `~/workspace/plugin-templates/rs/docker-compose.yaml`
- `~/workspace/plugin-templates/py/.github/workflows/ci.yaml`, `~/workspace/plugin-templates/ts/.github/workflows/ci.yaml`, `~/workspace/plugin-templates/rs/.github/workflows/ci.yaml`
- `~/workspace/plugin-templates/py/.gitignore`, `~/workspace/plugin-templates/ts/.gitignore`, `~/workspace/plugin-templates/rs/.gitignore`
- `~/workspace/plugin-templates/py/.dockerignore`, `~/workspace/plugin-templates/ts/.dockerignore`, `~/workspace/plugin-templates/rs/.dockerignore`
- `~/workspace/plugin-templates/py/.pre-commit-config.yaml`, `~/workspace/plugin-templates/ts/lefthook.yml`, `~/workspace/plugin-templates/rs/lefthook.yml`
- `~/workspace/plugin-templates/py/tests/test_live.sh`, `~/workspace/plugin-templates/ts/tests/test_live.sh`, `~/workspace/plugin-templates/rs/tests/test_live.sh`
- `~/workspace/plugin-templates/py/pyproject.toml`, `~/workspace/plugin-templates/ts/package.json`, `~/workspace/plugin-templates/rs/Cargo.toml`
- `~/workspace/plugin-templates/py/my_plugin_mcp/`, `~/workspace/plugin-templates/ts/my_plugin_mcp/`, `~/workspace/plugin-templates/rs/my_plugin_mcp/`

## Move Into Testing / Release Docs

Move these sections into verification and publishing docs:
- `CI/CD Pipeline`
- `Marketplace Registration`
- `Testing with mcporter`
- `Development Tools Reference`

## Move Into Example / Reference Snippets

These are too long for primary guide docs and should stay as templates or example snippets:
- `SWAG Reverse Proxy Config`
- embedded `SKILL.md` examples
- embedded `agents/` examples
- embedded `commands/` examples

## Completeness Checklist

Before considering the migration complete:
- Every `##` heading from `docs/plugin-setup-guide.md` has a mapped destination.
- Every file explicitly requested from `~/workspace/plugin-templates/` and the chosen `~/workspace/plugin-templates/<lang>/` template exists.
- Language-variant templates clearly state the final target path relative to plugin root.
- The original guide remains unchanged for comparison.
