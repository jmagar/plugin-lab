# Slash Commands — my-plugin

Patterns for defining user-invocable slash commands in Claude Code.

## File location

Commands are Markdown files discovered by Claude Code from `commands/`:

```
commands/
  my-command.md                  # /my-command
  my-service/
    action.md                    # /my-service:action
    other-action.md              # /my-service:other-action
```

## Naming

| Layout | File | Resulting command |
| --- | --- | --- |
| Single | `commands/check.md` | `/check` |
| Namespaced | `commands/my-service/status.md` | `/my-service:status` |
| Namespaced | `commands/my-service/search.md` | `/my-service:search` |

The directory name becomes the namespace prefix. The filename (minus `.md`) becomes the command after the colon.

## Frontmatter

```yaml
---
description: Short description shown in autocomplete
argument-hint: <required> [optional]
allowed-tools: Bash(tool:*), mcp__my-plugin__my_tool
---
```

| Field | Required | Description |
| --- | --- | --- |
| `description` | yes | One-line description for autocomplete menu |
| `argument-hint` | no | Hint for expected arguments (`<required>`, `[optional]`) |
| `allowed-tools` | no | Pre-approved tools — no permission prompts at runtime |

### allowed-tools syntax

| Pattern | Matches |
| --- | --- |
| `Bash(tool:*)` | All Bash commands |
| `Bash(rtk git status)` | Specific Bash command |
| `mcp__my-plugin__my_tool` | Specific MCP tool |
| `Read` | File read tool |
| `Write` | File write tool |

## Body

The command body contains instructions for Claude to follow when the command is invoked.

```markdown
---
description: Check my-service health
allowed-tools: Bash(tool:*)
---

Check the health of my-service: $ARGUMENTS

## Instructions

1. Run the health check script
2. Parse the JSON response
3. Report status summary
```

### Variables

| Variable | Description |
| --- | --- |
| `$ARGUMENTS` | Replaced with everything the user types after the command |

### Dynamic context injection

Use `` !`command` `` to inject shell output into the prompt at invocation time:

```markdown
---
description: Show my-service status
allowed-tools: Bash(tool:*)
---

Current container status:
!`docker ps --filter name=my-service --format "table {{.Names}}\t{{.Status}}"`

## Instructions
Analyze the container status above and report health.
```

The shell command runs before Claude sees the prompt. Output is injected inline.

## Symlink setup

For Claude Code to discover commands outside a plugin install, symlink to `~/.claude/commands/`:

```bash
# Single command
ln -sf ~/path/to/repo/commands/my-command.md ~/.claude/commands/my-command.md

# Namespaced commands (symlink the directory)
ln -sf ~/path/to/repo/commands/my-service ~/.claude/commands/my-service
```

Plugin-installed commands are discovered automatically without symlinks.

## Example command template

<!-- scaffold:specialize — replace with actual command logic -->

**Single command** (`commands/status.md`):

```markdown
---
description: Check my-plugin service status
argument-hint: [service-name]
allowed-tools: Bash(tool:*), mcp__my-plugin__my_tool
---

Check the status of: $ARGUMENTS

## Instructions

1. If a service name is provided, check that specific service
2. Otherwise, check all services
3. Report status as a summary table
4. Flag any services that are degraded or down
```

**Namespaced command** (`commands/my-service/search.md`):

```markdown
---
description: Search my-service resources
argument-hint: <query>
allowed-tools: Bash(tool:*), mcp__my-plugin__my_tool
---

Search my-service for: $ARGUMENTS

## Instructions

1. Use the MCP tool if available, otherwise fall back to curl
2. Display results as a compact table
3. Limit to 20 results unless the user asks for more
```

## Cross-references

- [AGENTS.md](AGENTS.md) — Agents that commands may delegate to
- [SKILLS.md](SKILLS.md) — Skills that provide domain knowledge for commands
- [HOOKS.md](HOOKS.md) — Hooks triggered by tool use within commands
