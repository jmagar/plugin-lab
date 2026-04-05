# Hook Configuration — my-plugin

Lifecycle hooks that run automatically during Claude Code sessions.

## File location

```
hooks/
  hooks.json                   # Hook declarations
  scripts/
    sync-env.sh                # Sync userConfig to .env
    fix-env-perms.sh           # Enforce chmod 600 on .env
    ensure-ignore-files.sh     # Keep .gitignore aligned
```

## hooks.json structure

```json
{
  "description": "Sync credentials and enforce security",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/sync-env.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-ignore-files.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fix-env-perms.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-ignore-files.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Hook events

| Event | When it fires | Typical use |
| --- | --- | --- |
| `SessionStart` | Claude Code session begins | Sync credentials, validate environment |
| `PreToolUse` | Before a tool executes | Block dangerous operations, inject context |
| `PostToolUse` | After a tool executes | Fix permissions, enforce invariants |

## Hook object fields

| Field | Required | Type | Description |
| --- | --- | --- | --- |
| `type` | yes | string | Always `"command"` |
| `command` | yes | string | Shell command or script path |
| `timeout` | no | number | Seconds before the hook is killed (default: 10) |

## Matcher syntax

The `matcher` field on `PreToolUse` and `PostToolUse` groups filters which tool invocations trigger the hooks. Use pipe-separated tool names:

| Matcher | Triggers on |
| --- | --- |
| `Write\|Edit\|MultiEdit\|Bash` | Any file write or shell command |
| `Bash` | Shell commands only |
| `Write\|Edit` | File creation or modification only |
| `mcp__my-plugin__my_tool` | Specific MCP tool call |

Omitting `matcher` means the hooks run on every tool use (not recommended for `PostToolUse`).

## Path variables

| Variable | Expands to |
| --- | --- |
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to the plugin's root directory |

Always use `${CLAUDE_PLUGIN_ROOT}` for script paths. Never hardcode absolute paths.

## Standard hook scripts

### sync-env.sh

Syncs `userConfig` values from plugin settings into the `.env` file:

```bash
#!/bin/bash
set -euo pipefail
ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
# Read userConfig values and write to .env
# Preserves existing values, adds missing keys
```

### fix-env-perms.sh

Enforces restrictive permissions on `.env`:

```bash
#!/bin/bash
set -euo pipefail
ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
if [[ -f "$ENV_FILE" ]]; then
  chmod 600 "$ENV_FILE"
fi
```

### ensure-ignore-files.sh

Verifies `.gitignore` and `.dockerignore` contain required patterns:

```bash
#!/bin/bash
set -euo pipefail
# Ensure .env, *.secret, credentials.* are in .gitignore
# Ensure .env, *.secret are in .dockerignore
```

## Writing custom hooks

1. Create the script in `hooks/scripts/`
2. Make it executable: `chmod +x hooks/scripts/my-hook.sh`
3. Use `set -euo pipefail` for strict mode
4. Keep execution fast — hooks block the session
5. Use `${CLAUDE_PLUGIN_ROOT}` for paths
6. Add to `hooks.json` under the appropriate event

## Example: custom PostToolUse hook

<!-- scaffold:specialize — add plugin-specific hooks -->

```json
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-service-health.sh",
          "timeout": 15
        }
      ]
    }
  ]
}
```

## Cross-references

- [CONFIG.md](CONFIG.md) — Settings that hooks sync
- [PLUGINS.md](PLUGINS.md) — Plugin manifest where hooks are registered
- See [GUARDRAILS](../GUARDRAILS.md) for security patterns enforced by hooks
