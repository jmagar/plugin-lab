# Marketplace Publishing -- plugin-lab

plugin-lab is published to three plugin ecosystems: Claude Code, OpenAI Codex, and Google Gemini.

## Claude Code Marketplace

**Manifest:** `.claude-plugin/plugin.json`

plugin-lab is available through the homelab-core marketplace:

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab
```

The `marketplace.json` file in plugin-lab is a **template** for scaffolded plugins, not a live marketplace. It contains placeholder values that demonstrate the canonical marketplace entry shape.

### Marketplace Entry Shape

```json
{
  "name": "my-plugin-mcp",
  "source": {
    "source": "github",
    "repo": "your-org/my-plugin-mcp"
  },
  "description": "...",
  "version": "0.1.0",
  "category": "utilities",
  "tags": ["mcp", "my-plugin"],
  "homepage": "https://github.com/your-org/my-plugin-mcp"
}
```

## Codex Marketplace

**Manifest:** `.codex-plugin/plugin.json`

The Codex manifest includes an `interface` section for marketplace display:

| Field | Purpose |
| --- | --- |
| `displayName` | Name shown in the marketplace |
| `shortDescription` | One-line summary |
| `longDescription` | Extended description |
| `developerName` | Author/team name |
| `category` | Marketplace category |
| `capabilities` | Tool capabilities (Read, Write, etc.) |
| `brandColor` | Hex color for branding |
| `composerIcon` | Path to icon asset |
| `logo` | Path to logo asset |

## Gemini Extension

**Manifest:** `gemini-extension.json`

The simplest manifest. Points to a `contextFileName` (typically `GEMINI.md`) that provides context to Gemini.

```json
{
  "name": "plugin-lab",
  "version": "1.0.5",
  "description": "...",
  "contextFileName": "GEMINI.md"
}
```

## Version Discipline

All three manifests must carry the same version. The `scripts/check-version-sync.sh` hook validates this. The release workflow (`release-on-main.yaml`) reads the version from the package manifest and fails if a tag for that version already exists -- enforcing a bump on every main push.

## For Scaffolded Plugins

When scaffolding a new plugin, all three manifest templates are generated with placeholder values. The scaffold script replaces plugin name, description, and version. After scaffolding, the developer fills in marketplace-specific metadata (icons, screenshots, category).
