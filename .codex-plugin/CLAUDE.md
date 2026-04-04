# `.codex-plugin/`

This directory contains the Codex plugin manifest for `plugin-lab`.

## Purpose

Use `.codex-plugin/` for the required `plugin.json` and any Codex-specific metadata that describes how this repository should appear and behave in the Codex plugin system.

## Contract

- `plugin.json` is the required manifest entry point
- Keep manifest paths relative to the plugin root
- Keep configuration and presentation metadata here, not in repo docs
- Do not add unrelated project files to this directory

## Notes

When changing the plugin shape, update the manifest and any matching marketplace entry together so the Codex view stays consistent with the actual repository layout.
