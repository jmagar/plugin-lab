# Scaffold Template Mapping

This document captures the initial mapping from the current `plugin-lab` repository root to the future mirrored scaffold root under `templates/`.

## Goal

Make `templates/` the canonical source tree for scaffolded plugin output. Boilerplate that belongs in generated plugins should live there at matching paths, while files that describe or operate `plugin-lab` itself should remain in the real repo root.

## Rules

- If a file exists to describe, run, or publish `plugin-lab` itself, keep it in the repo root
- If a file is boilerplate intended to appear in generated plugins, mirror it under `templates/`
- If a directory already represents a canonical scaffold surface for generated plugins, it is a strong candidate to move under `templates/`
- Ambiguous files should be classified before any move

## Initial Mapping

### Keep At Repo Root

These are `plugin-lab` assets, not generated-plugin boilerplate.

| Current path | Reason |
| --- | --- |
| `README.md` | Entry point for understanding and using `plugin-lab` |
| `CLAUDE.md` | Repo-level working instructions for this repository |
| `CHANGELOG.md` | Release history for `plugin-lab` itself |
| `LICENSE` | License for this repository |
| `docs/` | Human-facing docs about `plugin-lab` |
| `.claude-plugin/` | Claude plugin manifest for consuming `plugin-lab` |
| `scripts/` | Repo maintenance and orchestration logic |
| `bin/` | Repo execution helpers |
| `templates/` | New canonical scaffold source root |

### Mirror Under `templates/`

These are strong boilerplate candidates because they already look like generated-plugin output or scaffold inputs.

| Current path | Target path | Notes |
| --- | --- | --- |
| `.env.example` | `templates/.env.example` | Generic generated-plugin env template |
| `.gitignore` | `templates/.gitignore` | Should likely be trimmed to scaffold-safe ignores |
| `.mcp.json` | `templates/.mcp.json` | Generated MCP server registration stub |
| `.lsp.json` | `templates/.lsp.json` | Generated LSP server registration stub |
| `.app.json` | `templates/.app.json` | Generated app-integration stub |
| `gemini-extension.json` | `templates/gemini-extension.json` | Generated Gemini extension boilerplate |
| `settings.json` | `templates/settings.json` | Generated default plugin settings stub |
| `.codex-plugin/plugin.json` | `templates/.codex-plugin/plugin.json` | Already reads like generated plugin metadata |
| `bin/` | `templates/bin/` | Executable helpers intended to land on `PATH` in generated plugins |
| `templates/py/` | Canonical Python scaffold subtree | Moved from the repo root |
| `templates/ts/` | Canonical TypeScript scaffold subtree | Moved from the repo root |
| `templates/rs/` | Canonical Rust scaffold subtree | Moved from the repo root |

### Stay At Root, But Reserve Matching Paths In `templates/`

These directories stay in the real `plugin-lab` root as working repo surfaces. Matching directories should still exist under `templates/` so the scaffold root can mirror the expected generated-plugin shape when those template families are populated later.

| Current path | Matching template path | Decision |
| --- | --- | --- |
| `agents/` | `templates/agents/` | Keep real content at repo root for now; reserve scaffold path |
| `assets/` | `templates/assets/` | Keep real content at repo root for now; reserve scaffold path |
| `commands/` | `templates/commands/` | Keep real content at repo root for now; reserve scaffold path |
| `hooks/` | `templates/hooks/` | Keep real content at repo root for now; reserve scaffold path |
| `output-styles/` | `templates/output-styles/` | Keep real content at repo root for now; reserve scaffold path |
| `prompts/` | `templates/prompts/` | Keep real content at repo root for now; reserve scaffold path |
| `skills/` | `templates/skills/` | Keep real content at repo root for now; reserve scaffold path |

### Keep Out Of `templates/` For Now

These look like repo-local or development-environment files rather than generated-plugin boilerplate.

| Current path | Reason |
| --- | --- |
| `.omc/` | Likely repo-local tooling state or metadata |
| `templates/.lsp.json` | Template-only LSP config placeholder; not used by the live plugin |
| `templates/settings.json` | Template-only default settings placeholder; not used by the live plugin |

## Recommended Migration Order

1. Mirror high-confidence root boilerplate into matching paths under `templates/`
2. Update generators to read from `templates/` instead of the repo root
3. Keep working repo surfaces such as `skills/`, `commands/`, and `hooks/` at the real root until their scaffold equivalents are intentionally authored under `templates/`
4. Populate reserved directories under `templates/` as each scaffold family is defined
5. Leave `plugin-lab` repo docs and repo manifests at the real root

## Immediate Next Candidates

The safest first moves are:

- `.env.example`
- `.gitignore`
- `.mcp.json`
- `.app.json`
- `gemini-extension.json`
- `.codex-plugin/plugin.json`
- `templates/py/`
- `templates/ts/`
- `templates/rs/`
