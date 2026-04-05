# Documentation Templates

This directory contains documentation template assets that `plugin-lab` copies into every new plugin repo during scaffolding. These are not docs for `plugin-lab` itself; they are boilerplate inputs rendered into target repos.

## Directory index

### Root-level templates (this directory)

| File | Purpose |
| --- | --- |
| `README.md` | Main plugin README — badges, overview, tools, install, config, examples |
| `SETUP.md` | Step-by-step setup guide — clone, install, configure, verify |
| `CONFIG.md` | Configuration reference — all env vars, userConfig, .env conventions |
| `CHECKLIST.md` | Pre-release quality checklist — version sync, security, CI, registry |
| `GUARDRAILS.md` | Security guardrails — credentials, Docker, auth, input handling |
| `INVENTORY.md` | Component inventory — tools, resources, env vars, surfaces, deps |
| `CLAUDE.md` | This file — index and conventions for the docs template tree |

### Subdirectories

| Directory | Scope |
| --- | --- |
| `mcp/` | MCP server docs: auth, transport, tools, resources, testing, deployment |
| `plugin/` | Plugin system docs: manifests, hooks, skills, commands, channels |
| `repo/` | Repository docs: git conventions, scripts, memory, rules |
| `stack/` | Technology stack docs: prerequisites, architecture, dependencies |
| `upstream/` | Upstream service docs: API reference, integration patterns |

## Placeholder conventions

All templates use consistent placeholder names that get replaced during scaffolding:

| Placeholder | Case | Example replacement |
| --- | --- | --- |
| `my-plugin` | kebab-case | `gotify-mcp` |
| `my_plugin` | snake_case | `gotify_mcp` |
| `MyPlugin` | PascalCase | `GotifyMcp` |
| `MY_PLUGIN` | SCREAMING_SNAKE | `GOTIFY` |
| `my-service` | kebab-case | `gotify` |
| `8000` | port number | `9158` |
| `0.1.0` | initial version | `0.1.0` |

The scaffold tool performs a global find-and-replace across all template files. Use placeholders exactly as shown — do not introduce variants.

## Scaffold markers

Templates include `<!-- scaffold:specialize -->` HTML comments at locations that need per-plugin customization beyond simple text replacement. These mark sections where the scaffold operator (human or agent) must review and adapt the content.

## Style conventions

- Technical, precise, pragmatic — no filler or marketing language
- Use tables for structured data (env vars, tools, dependencies)
- Cross-reference related docs: `See [AUTH](mcp/AUTH.md)`, `See [CONFIG](CONFIG.md)`
- Include code examples that are complete and runnable
- Use `just` recipes as the primary interface for common operations
- Keep imperative mood for instructions: "Set the variable" not "You should set the variable"

## How templates are consumed

During scaffolding (`/plugin-lab:create-lab-plugin` or `scaffold-plugin.sh`):

1. Templates are copied from this directory into the target repo
2. Placeholder names are replaced with actual plugin/service names
3. Language-specific adjustments are applied (Python/TypeScript/Rust)
4. `<!-- scaffold:specialize -->` sections are flagged for manual review

## Boundaries

- Templates here produce docs for generated plugins, not for `plugin-lab` itself
- Human-facing `plugin-lab` documentation lives in the repo's top-level `docs/`
- Keep naming and placeholder conventions consistent across all files
- If a template family in a subdirectory needs its own rules, add a colocated `CLAUDE.md`
