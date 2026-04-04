# `.claude-plugin/`

This directory contains Claude plugin metadata for `plugin-lab`.

## Purpose

Use `.claude-plugin/` for the Claude-facing manifest, marketplace catalog, and related docs that describe how Claude Code should discover and present this plugin.

## Contract

- Keep `plugin.json` as the manifest entry point
- Keep `marketplace.json` as the catalog for local or curated plugin listings
- Keep manifest and catalog paths relative to the repo root
- Use this directory for Claude plugin surfaces only, not general repo documentation

## Notes

If you change the plugin surface, update the manifest, the marketplace entry, and any related docs together so Claude Code users see a coherent package.
