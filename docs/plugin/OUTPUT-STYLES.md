# Output Styles -- plugin-lab

plugin-lab does not define custom output styles. The `output-styles/` directory exists as a reserved scaffold surface.

## What output styles are

Output styles customize the formatting of agent and tool responses in Claude Code. They allow plugins to define consistent response structures for their tools.

## Current state

The `output-styles/` directory contains:
- `CLAUDE.md` -- Directory guidance
- `docs/` -- Mirrored Claude Code output-style documentation
- `.gitkeep` -- Placeholder

Mirrored docs can be refreshed with `scripts/update-doc-mirrors.sh`.

## For scaffolded plugins

Plugins scaffolded by plugin-lab may define output styles if their MCP tools benefit from structured response formatting. The template system does not currently generate output style files -- they are added post-scaffold when needed.
