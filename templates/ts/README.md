# TypeScript Plugin Template

This directory is the full self-contained TypeScript MCP plugin template.

It is the source used when scaffolding a TypeScript plugin from:

- `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh`

## Includes

- TypeScript manifest: `package.json`
- compiler config: `tsconfig.json`
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
- do not depend on files outside `ts/` at scaffold time
- if the scaffold consumes a file for TypeScript, that file should live here
- update this template first, then update scaffold consumers if paths change

## Runtime Shape

- module directory: `my_plugin_mcp/`
- compiled output rooted under `dist/my_plugin_mcp/`
- dual transport by default: HTTP + stdio
- Express + MCP SDK is the default stack
