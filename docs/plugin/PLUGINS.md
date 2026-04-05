# Plugin Manifests -- plugin-lab

plugin-lab publishes manifests for three platforms: Claude Code, OpenAI Codex, and Google Gemini.

## Claude Code Manifest

**File:** `.claude-plugin/plugin.json`

```json
{
  "name": "plugin-lab",
  "description": "Agents, commands, skills, and scripts for scaffolding, reviewing, aligning, and deploying homelab MCP server plugins.",
  "version": "1.0.5",
  "author_url": "https://github.com/jmagar",
  "author": {
    "name": "jmagar",
    "email": "jmagar@users.noreply.github.com"
  },
  "homepage": "https://github.com/jmagar/plugin-lab",
  "repository": "https://github.com/jmagar/plugin-lab",
  "license": "MIT"
}
```

Required fields: `name`, `version`, `description`. The manifest does not declare `mcpServers` because plugin-lab is not an MCP server.

### Marketplace Entry

The `.claude-plugin/marketplace.json` in plugin-lab is a **template** for scaffolded plugins, not a live marketplace. It contains placeholder values (`my-plugin-mcp`, `your-org`) that get replaced during scaffolding.

## Codex Manifest

**File:** `.codex-plugin/plugin.json`

The Codex manifest includes an `interface` section with display metadata (`displayName`, `shortDescription`, `longDescription`, brand color, icons). The `skills`, `mcpServers`, and `apps` fields point to relative paths within the repo.

Note: The Codex manifest in plugin-lab is partly a template -- it contains placeholder values (e.g., `my-plugin-mcp`, `Your team`) that demonstrate the canonical shape.

## Gemini Extension Manifest

**File:** `gemini-extension.json`

```json
{
  "name": "plugin-lab",
  "version": "1.0.5",
  "description": "...",
  "contextFileName": "GEMINI.md"
}
```

Points Gemini to `GEMINI.md` for context. The Gemini manifest is the simplest of the three.

## Version Sync

All three manifests must carry the same version string. The `scripts/check-version-sync.sh` script validates this across all version-bearing files.

Bump type is determined by commit prefix:
- `feat!:` or `BREAKING CHANGE` -- major (X+1.0.0)
- `feat` or `feat(...)` -- minor (X.Y+1.0)
- Everything else -- patch (X.Y.Z+1)
