# Marketplace Publishing — my-plugin

Registration and publishing patterns for Claude, Codex, and Gemini marketplaces.

## Marketplace locations

| Marketplace | Manifest file | Registry scope |
| --- | --- | --- |
| Claude | `.claude-plugin/marketplace.json` | homelab-core mono-repo |
| Codex | `.codex-plugin/marketplace.json` | homelab-core mono-repo |
| Gemini | (via `gemini-extension.json`) | Per-repo |

Marketplace manifests live in the homelab-core repo (`claude-homelab`), not in individual plugin repos. Each plugin repo has its own `plugin.json` but the marketplace catalog is centralized.

## Entry format

```json
{
  "name": "my-plugin",
  "source": {
    "source": "github",
    "repo": "jmagar/my-plugin"
  },
  "version": "0.1.0",
  "category": "infrastructure",
  "tags": ["mcp", "homelab"]
}
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Plugin name (kebab-case, matches repo) |
| `source` | yes | Object with `source` type and `repo` identifier |
| `version` | yes | Must match `plugin.json` version |
| `category` | yes | One of: `infrastructure`, `media`, `utilities`, `dev-tools`, `research` |
| `tags` | no | Discovery tags (array of strings) |

### Categories

| Category | Description | Examples |
| --- | --- | --- |
| `infrastructure` | Server, network, storage management | unraid, unifi, swag, syslog |
| `media` | Media management and requests | overseerr, plex, radarr, sonarr |
| `utilities` | Notifications, bookmarks, notes | gotify, linkding, memos |
| `dev-tools` | Development and scaffolding | plugin-lab |
| `research` | Experimental and AI research | axon |

## Bundled vs external plugins

Not every service integration needs its own repository.

### Bundled (skills-only)

Skills that live inside `claude-homelab/skills/` are bundled with homelab-core. They appear in the marketplace as bundled entries — no separate `source.repo`.

Examples: plex, radarr, sonarr, tailscale, zfs, bytestash, linkding, memos

### External (full plugin)

Plugins with their own repo at `jmagar/<plugin-name>`. The marketplace entry references the external repo via `source`.

Examples: overseerr-mcp, unraid-mcp, unifi-mcp, gotify-mcp, swag-mcp

## Graduation criteria

A bundled skill graduates to its own external repo when it gains additional plugin surface area beyond a skill directory:

| Surface | Requires own repo? |
| --- | --- |
| SKILL.md + references only | No — stays bundled |
| + MCP server | Yes |
| + Agents | Yes |
| + Commands | Yes |
| + Hooks | Yes |
| + Any combination above | Yes |

When graduating:

1. Create new repo: `jmagar/my-plugin`
2. Move skill content + add new surfaces
3. Add marketplace entry with `source.repo`
4. Remove bundled skill from homelab-core (or keep as a thin pointer)

## Version sync

The marketplace `version` field must match the plugin's `plugin.json` version. On every version bump:

1. Bump version in `plugin.json` (both `.claude-plugin/` and `.codex-plugin/`)
2. Bump version in `gemini-extension.json`
3. Bump version in `Cargo.toml` / `package.json` / `pyproject.toml`
4. Update marketplace entry version in homelab-core
5. Add `CHANGELOG.md` entry

Verify with `just check-contract`.

## Installation

Users install plugins via the marketplace command:

```
/plugin marketplace add jmagar/my-plugin
```

This clones the repo, reads `plugin.json`, prompts for `userConfig`, and activates all plugin surfaces.

## Cross-references

- [PLUGINS.md](PLUGINS.md) — Plugin manifest structure
- [CONFIG.md](CONFIG.md) — userConfig prompted at install
- See [CHECKLIST](../CHECKLIST.md) for pre-release quality checks
