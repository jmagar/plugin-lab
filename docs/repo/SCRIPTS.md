# Scripts Reference -- plugin-lab

All scripts in `scripts/` and `hooks/scripts/`.

## Repo Scripts (scripts/)

### scaffold-plugin.sh

**Purpose:** Generate a new MCP server plugin from canonical templates.

```bash
bash scripts/scaffold-plugin.sh <service-name> <language> [--port PORT]
```

Reads shared assets from `templates/` and language-specific assets from `templates/py/`, `templates/ts/`, or `templates/rs/`. Performs global find-and-replace on placeholder names (`my-plugin`, `my_plugin`, `MY_SERVICE`, etc.). The `PLUGIN_TEMPLATES_ROOT` env var can override the template location.

### lint-plugin.sh

**Purpose:** Comprehensive plugin linter validating 16 check categories.

```bash
bash scripts/lint-plugin.sh [project-dir]
```

Checks: manifest existence and fields, userConfig attributes, Codex displayName, version sync, env var naming, domain+help tool presence, required files, symlink conventions, skill files, hook executability, Docker Compose patterns, .env not tracked, required directories, asset files.

Exit codes: 0 (all required checks pass), 1 (one or more failures).

### check-version-sync.sh

**Purpose:** Verify all version-bearing files have the same version string.

```bash
bash scripts/check-version-sync.sh [project-dir]
```

Checks: `Cargo.toml`, `package.json`, `pyproject.toml`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `gemini-extension.json`. Warns (non-blocking) if `CHANGELOG.md` lacks an entry for the current version.

### ensure-ignore-files.sh

**Purpose:** Ensure .gitignore and .dockerignore have all required patterns.

```bash
bash scripts/ensure-ignore-files.sh [--check] [project-dir]
```

Default mode appends missing patterns. `--check` mode reports missing patterns and exits non-zero if any are absent.

### check-docker-security.sh

**Purpose:** Audit Docker configuration for security issues.

```bash
bash scripts/check-docker-security.sh [project-dir]
```

### check-no-baked-env.sh

**Purpose:** Verify no environment variables are baked into Docker images.

```bash
bash scripts/check-no-baked-env.sh [project-dir]
```

### check-outdated-deps.sh

**Purpose:** Check for outdated dependencies across package managers.

```bash
bash scripts/check-outdated-deps.sh [project-dir]
```

### validate-marketplace.sh

**Purpose:** Validate `.claude-plugin/marketplace.json` structure and references.

```bash
bash scripts/validate-marketplace.sh [repo-root]
```

Checks: JSON validity, required fields, local path existence, GitHub repo reachability, remote manifest version comparison.

### update-doc-mirrors.sh

**Purpose:** Refresh mirrored markdown docs from first-line source URLs.

```bash
bash scripts/update-doc-mirrors.sh [root-dir]
```

Any `.md` file whose first line is `# https://example.com/path/to/doc.md` is treated as a mirror and fully overwritten by the fetched content. Produces `.diff` sidecar files for changed docs. Covers mirrors in `agents/`, `hooks/`, `skills/`, `.claude-plugin/`, `.codex-plugin/`, and `templates/`.

### sync-env.sh and fix-env-perms.sh

Repo-level versions of the hook scripts. Accept a `project-dir` argument for use outside the hook context.

## Hook Scripts (hooks/scripts/)

### sync-env.sh

**Trigger:** SessionStart
**Purpose:** Sync `CLAUDE_PLUGIN_OPTION_*` values into `.env` with file locking and backup rotation.

### fix-env-perms.sh

**Trigger:** PostToolUse
**Purpose:** Ensure `.env` and backups have `chmod 600`.

### ensure-ignore-files.sh

**Trigger:** SessionStart
**Purpose:** Append missing patterns to `.gitignore` and `.dockerignore`.

See [HOOKS.md](../plugin/HOOKS.md) for detailed behavior descriptions.

## Skill Scripts (skills/setup/scripts/)

### setup-creds.sh

**Purpose:** Create `~/.claude-homelab/.env` from template, install `load-env.sh`.

Called by the `setup` skill when the credential file is missing.

## Script Conventions

All scripts follow these rules:
- `set -euo pipefail` (strict mode)
- Quote all variables: `"$var"`
- Shebangs: `#!/usr/bin/env bash`
- Accept `[project-dir]` as first argument, default to current directory
- Support `--help` / `-h` for usage
- Exit 0 on success, 1 on failure
