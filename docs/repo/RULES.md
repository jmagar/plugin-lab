# Rules and Conventions -- plugin-lab

Git workflow, versioning, code standards, and the single-source-of-truth contract.

## Single Source of Truth

**Every file exists in exactly one place.**

- Shared plugin-contract files live at the repo root or under `templates/`
- Language-specific files live under one language directory (`templates/py/`, `templates/ts/`, or `templates/rs/`)
- Never duplicate shared files into language directories
- `docs/` explains plugin-lab itself; `templates/` defines output for generated repos

If you move or rename a template file, update the scaffold script and any combo instructions in `claude-homelab` in the same change.

## No Duplication

- No shared trees duplicated under language directories
- No placeholder-only paths unless the scaffold actually consumes them
- Root docs describe this repo, not a language template
- Per-language `README.md` and `CLAUDE.md` describe that language layer only

## Git Workflow

### Branch Strategy

- `main` -- production-ready code
- Feature branches for new skills, agents, templates
- PR required before merge

### Commit Conventions

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Examples:
```
feat(scaffold): add Rust template support
fix(lint): correct userConfig validation for sensitive fields
docs(skills): update review-lab-plugin references
refactor(hooks): simplify sync-env locking
```

### Never Commit

- `.env` files
- Credentials or API keys
- Large binary files
- Temporary/debug files
- Files listed in `.gitignore`

## Version Bumping

**Every feature branch push MUST bump the version in ALL version-bearing files.**

Bump type by commit prefix:
- `feat!:` or `BREAKING CHANGE` -- major (X+1.0.0)
- `feat` or `feat(...)` -- minor (X.Y+1.0)
- Everything else -- patch (X.Y.Z+1)

**Files to update:**
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `gemini-extension.json`
- `Cargo.toml` (if present)
- `package.json` (if present)
- `pyproject.toml` (if present)
- `README.md` (version badge or header, if present)
- `CHANGELOG.md` (new entry under the bumped version)

All files MUST have the same version. Never bump only one file. Validate with:

```bash
bash scripts/check-version-sync.sh
```

## Code Standards

### Bash Scripts

- `set -euo pipefail` (strict mode)
- Quote all variables: `"$var"`
- `#!/usr/bin/env bash` shebangs
- Executable permissions: `chmod +x`
- Functions for reusable code
- Support `--help` flag
- Return JSON where appropriate

### Markdown

- YAML frontmatter for skills, agents, commands
- Tables for structured data
- Code examples that are complete and runnable
- Cross-references between related docs
- No marketing language -- technical, precise, pragmatic

### Template Placeholders

All templates use consistent placeholder names:

| Placeholder | Case | Example |
| --- | --- | --- |
| `my-plugin` | kebab-case | `gotify-mcp` |
| `my_plugin` | snake_case | `gotify_mcp` |
| `MyPlugin` | PascalCase | `GotifyMcp` |
| `MY_PLUGIN` | SCREAMING_SNAKE | `GOTIFY` |
| `my-service` | kebab-case | `gotify` |
| `8000` | port number | `9158` |
| `0.1.0` | initial version | `0.1.0` |

## Security Rules

- No credentials in code, docs, or commit history
- `.env` always in `.gitignore` and `.dockerignore`
- `chmod 600` on all `.env` files
- Hook scripts enforce these rules automatically
- See [GUARDRAILS.md](../GUARDRAILS.md) for the full security policy
