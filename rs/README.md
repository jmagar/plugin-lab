# Rust Plugin Template

This directory is the full self-contained Rust MCP plugin template.

It is the source used when scaffolding a Rust plugin from:

- `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh`

## Includes

- Rust manifest: `Cargo.toml`
- runtime module directory: `my_plugin_mcp/`
- Claude and Codex plugin manifests
- hooks and hook scripts
- Dockerfile, `docker-compose.yaml`, `entrypoint.sh`
- `Justfile`
- CI workflow
- `lefthook.yml`
- `.gitignore`, `.dockerignore`, `.env.example`
- AI-facing files: `skills/`, `agents/`, `commands/`, `CLAUDE.md`
- test scaffold: `tests/test_live.sh`

## Rules

- keep this directory self-contained
- do not depend on files outside `rs/` at scaffold time
- if the scaffold consumes a file for Rust, that file should live here
- update this template first, then update scaffold consumers if paths change

## Runtime Shape

- module directory: `my_plugin_mcp/`
- binary entrypoint: `my_plugin_mcp/main.rs`
- dual transport by default
- `rmcp` is the default Rust MCP stack
