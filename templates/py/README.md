# Python Plugin Template

This directory is the full self-contained Python MCP plugin template.

It is the source used when scaffolding a Python plugin from:

- `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh`

## Includes

- Python package manifest: `pyproject.toml`
- runtime module directory: `my_plugin_mcp/`
- Claude and Codex plugin manifests
- hooks and hook scripts
- Dockerfile, `docker-compose.yaml`, `entrypoint.sh`
- `Justfile`
- CI workflow
- `.pre-commit-config.yaml`
- `.gitignore`, `.dockerignore`, `.env.example`
- AI-facing files: `skills/`, `agents/`, `commands/`, `CLAUDE.md`
- test scaffold: `tests/test_live.sh`

## Rules

- keep this directory self-contained
- do not depend on files outside `py/` at scaffold time
- if the scaffold consumes a file for Python, that file should live here
- update this template first, then update scaffold consumers if paths change

## Runtime Shape

- module directory: `my_plugin_mcp/`
- entrypoint module: `my_plugin_mcp.server`
- dual transport by default: HTTP + stdio
- Docker and local dev flows are both first-class
