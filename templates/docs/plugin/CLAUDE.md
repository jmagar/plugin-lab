# Plugin Surface Documentation — my-plugin

Index for the `plugin/` documentation subdirectory. These docs cover every Claude Code plugin surface area available to my-plugin.

## File index

| File | Surface | Description |
| --- | --- | --- |
| [PLUGINS.md](PLUGINS.md) | Manifests | `plugin.json` structure, required/optional fields, version sync |
| [AGENTS.md](AGENTS.md) | Agents | Agent definitions, frontmatter schema, delegation patterns |
| [SKILLS.md](SKILLS.md) | Skills | Skill definitions, progressive disclosure, reference docs |
| [COMMANDS.md](COMMANDS.md) | Commands | Slash commands, namespacing, dynamic context injection |
| [HOOKS.md](HOOKS.md) | Hooks | Session/tool hooks, scripts, matcher syntax |
| [CHANNELS.md](CHANNELS.md) | Channels | Bidirectional messaging with external services |
| [OUTPUT-STYLES.md](OUTPUT-STYLES.md) | Output Styles | Custom formatting for agent/tool responses |
| [SCHEDULES.md](SCHEDULES.md) | Schedules | Cron-based recurring agent execution |
| [CONFIG.md](CONFIG.md) | Settings | Plugin configuration, userConfig, env sync |
| [MARKETPLACES.md](MARKETPLACES.md) | Marketplaces | Publishing to Claude/Codex/Gemini marketplaces |

## How plugin surfaces compose

A Claude Code plugin is a bundle of one or more surfaces. Not every plugin needs every surface — pick what fits:

```
plugin.json (required)        Declares the plugin to Claude Code
  +-- mcpServers               MCP tools and resources
  +-- skills/                  Domain knowledge and workflows
  +-- agents/                  Specialized autonomous behaviors
  +-- commands/                User-invocable slash commands
  +-- hooks/                   Lifecycle event handlers
  +-- channels/                External messaging integration
  +-- output-styles/           Custom response formatting
  +-- schedules                Recurring automated tasks
  +-- settings.json            Plugin-level config
```

The minimum viable plugin is `plugin.json` alone. Each additional surface adds capability without requiring the others. See individual docs for details.

## Cross-references

- [CONFIG.md](../CONFIG.md) — Environment variables and `.env` conventions
- [GUARDRAILS.md](../GUARDRAILS.md) — Security patterns enforced across all surfaces
- [INVENTORY.md](../INVENTORY.md) — Complete component inventory
