# Rust Template Notes

This directory is the canonical Rust plugin scaffold.

## Source Of Truth

If a scaffolded Rust plugin needs a file, prefer putting it here rather than in repo root.

## Expected Key Files

- `Cargo.toml`
- `Dockerfile`
- `entrypoint.sh`
- `Justfile`
- `lefthook.yml`
- `.github/workflows/ci.yaml`
- `my_plugin_mcp/client.rs`
- `my_plugin_mcp/main.rs`
- `tests/test_live.sh`

## Conventions

- crate/bin name is `my-plugin-mcp`
- source root is `my_plugin_mcp`
- `rmcp` is the default server stack
- hook runner is lefthook
- Docker runs non-root
- `.env` backups should sit beside `.env` as `.env.bak.*`

## Maintenance

- keep template examples runnable
- keep paths aligned with `scaffold-plugin.sh`
- if you rename files here, update the scaffold in the same change
