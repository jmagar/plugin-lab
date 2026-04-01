# plugin-templates

Canonical scaffold source for the MCP plugin ecosystem.

This repo is the source of truth for new plugin scaffolds.

The structure is intentionally split in two layers:

- repo root = shared plugin-contract assets
- `py/`, `ts/`, `rs/` = language-specific runtime and toolchain assets

- `py/`
- `ts/`
- `rs/`

## Layout

- root: shared files used by every plugin scaffold
  - manifests
  - shared skills, agents, commands, hooks, and scripts
  - shared config such as `.env.example`, `.app.json`, `.mcp.json`, and plugin manifests
- `py/`: Python runtime and toolchain layer
- `ts/`: TypeScript runtime and toolchain layer
- `rs/`: Rust runtime and toolchain layer

## Consumers

- `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh` reads:
  - shared assets from repo root
  - language-specific assets from one of `py/`, `ts/`, or `rs/`
- plugin review/alignment/scaffold combos should treat this repo as the canonical template source
- language-specific lab repos should prove these templates, not replace them

## Rules

- update templates here first, then update scaffold consumers
- do not keep duplicate template paths for the same file shape
- repo root is not a fourth template
- repo root is the shared layer, not a dumping ground
- shared assets live at repo root only
- language-specific assets live under exactly one of `py/`, `ts/`, or `rs/`
- if a file exists in all three language directories, it should probably move to repo root unless it is intentionally language-specific

## Current Template Structure

- shared: `~/workspace/plugin-templates/`
- python: `~/workspace/plugin-templates/py/`
- typescript: `~/workspace/plugin-templates/ts/`
- rust: `~/workspace/plugin-templates/rs/`
