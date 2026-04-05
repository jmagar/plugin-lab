# Hook Scripts -- plugin-lab

plugin-lab includes 3 hook scripts that run at Claude Code lifecycle events. These scripts enforce security and hygiene constraints automatically.

## Hook Summary

| Script | File | Trigger | Purpose |
| --- | --- | --- | --- |
| sync-env | `hooks/scripts/sync-env.sh` | SessionStart | Sync userConfig values into `.env`, validate MCP token |
| fix-env-perms | `hooks/scripts/fix-env-perms.sh` | PostToolUse | Ensure `.env` and backups have chmod 600 |
| ensure-ignore-files | `hooks/scripts/ensure-ignore-files.sh` | SessionStart | Ensure .gitignore and .dockerignore have required patterns |

## Hook Details

### sync-env.sh

**Trigger:** SessionStart
**Location:** `hooks/scripts/sync-env.sh`

Syncs Claude Code `userConfig` values into the plugin's `.env` file. Uses file locking (`flock`) to prevent concurrent writes.

**Behavior:**
1. Acquires an exclusive lock on `.env.lock` (10 second timeout)
2. Reads managed variables from `CLAUDE_PLUGIN_OPTION_*` environment variables
3. Creates `.env` backup before modification (keeps last 3 backups)
4. Upserts each managed variable using awk-based pattern matching
5. Validates that `MY_SERVICE_MCP_TOKEN` is set -- exits with error if missing
6. Sets `chmod 600` on `.env` and all backups

**Managed variables:**
- `MY_SERVICE_URL`
- `MY_SERVICE_API_KEY`
- `MY_SERVICE_MCP_URL`
- `MY_SERVICE_MCP_TOKEN`

**Error condition:** If `MY_SERVICE_MCP_TOKEN` is not set after sync, the script prints instructions for generating a token (`openssl rand -hex 32`) and exits non-zero.

### fix-env-perms.sh

**Trigger:** PostToolUse
**Location:** `hooks/scripts/fix-env-perms.sh`

Ensures `.env` file permissions are correct after any tool execution that might have modified files.

**Behavior:**
1. Checks if `.env` exists (exits 0 if not)
2. Reads stdin to drain any piped input
3. Sets `chmod 600` on `.env` and all `.env.bak.*` files

This is a defensive hook -- it runs after every tool use to catch cases where a tool might have created or modified the `.env` file with incorrect permissions.

### ensure-ignore-files.sh

**Trigger:** SessionStart
**Location:** `hooks/scripts/ensure-ignore-files.sh`

Ensures `.gitignore` and `.dockerignore` contain all required patterns for security and hygiene.

**Two modes:**
- Default (no flags): Appends missing patterns to the files
- `--check`: Reports missing patterns and exits non-zero if any are missing (for CI)

**Required .gitignore patterns:**
```
.env, .env.*, !.env.example, logs/*, !logs/.gitkeep, *.log,
.claude/settings.local.json, .claude/worktrees/, .omc/, .lavra/,
.beads/, .serena/, .worktrees, .full-review/, .full-review-archive-*,
.vscode/, .cursor/, .windsurf/, .1code/, .cache/,
docs/plans/, docs/sessions/, docs/reports/, docs/research/, docs/superpowers/
```

**Required .dockerignore patterns:**
```
.git, .github, .env, .env.*, !.env.example, .claude, .claude-plugin,
.codex-plugin, .omc, .lavra, .beads, .serena, .worktrees,
.full-review, .full-review-archive-*, .vscode, .cursor, .windsurf,
.1code, docs, tests, scripts, *.md, !README.md, logs, *.log, .cache
```

## Hook Documentation

Mirrored documentation for Claude Code and Codex hook formats lives in:

- `hooks/docs/claude/` -- Claude Code hook documentation
- `hooks/docs/codex/` -- Codex hook documentation

Refresh mirrors with `scripts/update-doc-mirrors.sh`.

## Hook Configuration

Hook scripts are referenced from the plugin's hook configuration. The `CLAUDE_PLUGIN_ROOT` environment variable points to the plugin root directory, which hook scripts use to locate `.env` and other files.

## Corresponding Repo Scripts

The `scripts/` directory contains standalone versions of similar functionality:

| Hook script | Repo script equivalent |
| --- | --- |
| `hooks/scripts/sync-env.sh` | `scripts/sync-env.sh` |
| `hooks/scripts/fix-env-perms.sh` | `scripts/fix-env-perms.sh` |
| `hooks/scripts/ensure-ignore-files.sh` | `scripts/ensure-ignore-files.sh` |

The repo scripts accept a `project-dir` argument and can be used outside the hook context (e.g., in CI or manual validation).
