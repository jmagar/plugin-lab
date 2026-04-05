# Agent Definitions — my-plugin

Patterns for defining autonomous agents within a Claude Code plugin.

## File location

```
agents/
  my-specialist.md
  my-orchestrator.md
```

Agents are Markdown files in the `agents/` directory. Claude Code discovers them automatically when the plugin is installed.

## Naming conventions

| Pattern | Use case | Example |
| --- | --- | --- |
| `*-specialist.md` | Domain expert for a specific service | `notebooklm-specialist.md` |
| `*-orchestrator.md` | Coordinates multiple agents/tools | `deploy-orchestrator.md` |

Use descriptive, hyphenated names. The filename (minus `.md`) becomes the agent identifier.

## YAML frontmatter

```yaml
---
name: my-specialist
description: |
  Use this agent when the user asks about my-service configuration,
  troubleshooting, or API integration.
  <example>
  User: "Check if my-service is healthy"
  -> Invoke my-specialist
  </example>
model: inherit
color: blue
tools:
  - Bash
  - Read
  - Glob
  - Grep
memory: session
---
```

### Frontmatter fields

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Agent identifier (matches filename) |
| `description` | yes | Trigger conditions — when Claude should invoke this agent |
| `model` | no | `inherit` (default) or specific model ID |
| `color` | no | Terminal color: `blue`, `red`, `green`, `yellow`, `cyan`, `magenta` |
| `tools` | yes | Tools this agent is allowed to use |
| `memory` | no | `user` (persists) or `session` (current session only) |

### Tool restrictions

List only the tools the agent actually needs. Fewer tools = safer execution.

| Tool | When to include |
| --- | --- |
| `Bash` | Agent runs shell commands |
| `Read` | Agent reads files |
| `Write` | Agent creates new files |
| `Edit` | Agent modifies existing files |
| `Glob` | Agent searches for files by pattern |
| `Grep` | Agent searches file contents |
| `mcp__plugin__tool` | Agent uses a specific MCP tool |

## Body structure

After the frontmatter, the agent body follows this structure:

```markdown
## Initialization

Read the relevant SKILL.md before taking any action:

1. Read `skills/my-service/SKILL.md` for domain knowledge
2. Check `references/` for API details if needed

## Responsibilities

- Primary task 1
- Primary task 2
- What this agent does NOT do

## Delegation

When to hand off to other agents or ask the user:

- If [condition], suggest the user invoke [other-agent]
- If [condition], ask for clarification before proceeding

## Edge cases

- Service unreachable: Report status, suggest checking connectivity
- Credentials missing: Direct user to run setup
- Ambiguous request: Ask clarifying question before acting

## Output

Format responses as:
- Status: success/failure with reason
- Data: Relevant results in structured format
- Next steps: Actionable suggestions
```

## Skill delegation

Agents should read SKILL.md before acting on a domain. This ensures the agent has current command syntax, API patterns, and workflow knowledge.

```markdown
## Initialization

Before responding to any my-service request:
1. Read `skills/my-service/SKILL.md`
2. If the request involves API calls, also read `skills/my-service/references/api-endpoints.md`
```

## Example agent template

<!-- scaffold:specialize — replace with actual agent responsibilities -->

```markdown
---
name: my-specialist
description: |
  Use this agent when the user asks about my-service status,
  configuration, or troubleshooting.
  <example>
  User: "Is my-service running?"
  -> Invoke my-specialist
  </example>
model: inherit
color: cyan
tools:
  - Bash
  - Read
  - Glob
  - Grep
memory: session
---

## Initialization

Read `skills/my-service/SKILL.md` for domain context.

## Responsibilities

- Check my-service health and connectivity
- Query my-service API for status information
- Troubleshoot common my-service issues
- Does NOT modify my-service configuration without confirmation

## Edge cases

- Service unreachable: Check if container is running, report network status
- Auth failure: Verify credentials in `.env`, suggest re-running setup

## Output

- Health check: OK / DEGRADED / DOWN with details
- API queries: Structured JSON or table format
- Errors: Error message + suggested fix
```

## Cross-references

- [SKILLS.md](SKILLS.md) — Skill definitions agents delegate to
- [COMMANDS.md](COMMANDS.md) — Commands that may invoke agents
- [HOOKS.md](HOOKS.md) — Hooks that run alongside agent sessions
