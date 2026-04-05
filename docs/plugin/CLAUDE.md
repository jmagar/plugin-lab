# Plugin Surface Documentation -- plugin-lab

Index for the `plugin/` documentation subdirectory. These docs cover every Claude Code plugin surface area in plugin-lab.

## File index

| File | Surface | Description |
| --- | --- | --- |
| [PLUGINS.md](PLUGINS.md) | Manifests | `plugin.json` structure, required fields, version sync |
| [AGENTS.md](AGENTS.md) | Agents | All 7 agent definitions, frontmatter, delegation patterns |
| [SKILLS.md](SKILLS.md) | Skills | All 8 skills with SKILL.md summaries and reference content |
| [COMMANDS.md](COMMANDS.md) | Commands | All 8 slash commands with arguments and workflows |
| [HOOKS.md](HOOKS.md) | Hooks | Session/tool hooks, 3 hook scripts, trigger conditions |
| [CHANNELS.md](CHANNELS.md) | Channels | Not used by plugin-lab |
| [OUTPUT-STYLES.md](OUTPUT-STYLES.md) | Output Styles | Reserved directory, no custom styles defined |
| [SCHEDULES.md](SCHEDULES.md) | Schedules | Not used by plugin-lab |
| [CONFIG.md](CONFIG.md) | Settings | Plugin configuration and userConfig patterns |
| [MARKETPLACES.md](MARKETPLACES.md) | Marketplaces | Claude, Codex, and Gemini marketplace manifests |

## How plugin-lab uses surfaces

plugin-lab uses five active surfaces:

```
.claude-plugin/plugin.json   Declares the plugin to Claude Code
  +-- skills/                 8 operating procedures for plugin development phases
  +-- agents/                 7 specialized agents, one per lifecycle phase
  +-- commands/               8 slash commands that invoke skills and spawn agents
  +-- hooks/                  3 hook scripts for env sync, permissions, ignore files
```

Channels, output styles, and schedules are not used. The `output-styles/` directory exists as a reserved scaffold surface.

## Cross-references

- [CONFIG.md](../CONFIG.md) -- Environment variables and `.env` conventions
- [GUARDRAILS.md](../GUARDRAILS.md) -- Security patterns enforced across all surfaces
- [INVENTORY.md](../INVENTORY.md) -- Complete component inventory
