# Repository Docs

This directory contains documentation about `plugin-lab` itself.

## Purpose

Use `docs/` for repo-owned, human-facing documentation that explains how to use, extend, develop, or operate `plugin-lab`.

## What Belongs Here

- Setup guides for this repo
- Contributor and workflow documentation
- Design notes for `plugin-lab`
- Usage guides for commands, generators, or internal systems in this repo

## What Does Not Belong Here

- Boilerplate intended to be copied into other repositories
- Generator input files for MCP server docs
- Reusable scaffold fragments for produced plugins

Those belong under `templates/`.

## Boundary With `templates/`

- `docs/` explains this repo
- `templates/` defines output for other repos

Keep that separation strict so repo documentation does not get confused with generated documentation assets.
