# `assets/`

This directory holds visual and presentation assets for plugin surfaces.

## Purpose

Use `assets/` for icons, logos, screenshots, and other files that are meant to be shown in plugin install surfaces or related documentation.

## Contract

- Keep assets small, stable, and easy to reference from manifests
- Use descriptive filenames that match the plugin they belong to
- Store presentation assets here rather than mixing them into manifests or code

## Notes

For Codex plugins, this directory is typically referenced from `.codex-plugin/plugin.json` and other presentation metadata. Do not place repo-maintenance files here.
