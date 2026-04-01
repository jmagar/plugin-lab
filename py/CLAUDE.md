# Python Template Notes

This directory is the canonical Python plugin scaffold.

## Source Of Truth

If a scaffolded Python plugin needs a file, prefer putting it here rather than in repo root.

## Expected Key Files

- `pyproject.toml`
- `Dockerfile`
- `entrypoint.sh`
- `Justfile`
- `.pre-commit-config.yaml`
- `.github/workflows/ci.yaml`
- `my_plugin_mcp/__init__.py`
- `my_plugin_mcp/client.py`
- `my_plugin_mcp/server.py`
- `tests/test_live.sh`

## Conventions

- package/module root is `my_plugin_mcp`
- FastMCP is the default server stack
- runtime entrypoint is `my_plugin_mcp.server:main`
- hook runner is pre-commit, not lefthook
- Docker runs non-root
- `.env` backups should sit beside `.env` as `.env.bak.*`

## Maintenance

- keep template examples runnable
- keep paths aligned with `scaffold-plugin.sh`
- if you rename files here, update the scaffold in the same change
