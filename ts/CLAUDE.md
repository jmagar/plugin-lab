# TypeScript Template Notes

This directory is the canonical TypeScript plugin scaffold.

## Source Of Truth

If a scaffolded TypeScript plugin needs a file, prefer putting it here rather than in repo root.

## Expected Key Files

- `package.json`
- `tsconfig.json`
- `Dockerfile`
- `entrypoint.sh`
- `Justfile`
- `lefthook.yml`
- `.github/workflows/ci.yaml`
- `my_plugin_mcp/client.ts`
- `my_plugin_mcp/index.ts`
- `tests/test_live.sh`

## Conventions

- package/bin name is `my-plugin-mcp`
- source root is `my_plugin_mcp`
- MCP SDK + Zod + Express is the default stack
- hook runner is lefthook
- Docker runs non-root
- `.env` backups should sit beside `.env` as `.env.bak.*`

## Maintenance

- keep template examples runnable
- keep paths aligned with `scaffold-plugin.sh`
- if you rename files here, update the scaffold in the same change
