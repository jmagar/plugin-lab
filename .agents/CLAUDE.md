# `.agents/`

This directory holds Codex-facing agent marketplace data for `plugin-lab`.

## Purpose

Use `.agents/` for repo-scoped Codex catalog metadata that describes what plugins or agent surfaces are available from this repository. Keep it separate from the plugin manifests themselves.

## Contract

- `plugins/` is the place for the repo marketplace catalog
- Treat `marketplace.json` as catalog metadata, not runtime configuration
- Keep paths relative to the repo root when referencing local plugin folders
- Do not use this directory for documentation about `plugin-lab` itself

## Notes

This directory exists to help Codex discover and load local plugins from the repo. If a plugin is added or restructured, update the marketplace entry to match the actual path and plugin name.
