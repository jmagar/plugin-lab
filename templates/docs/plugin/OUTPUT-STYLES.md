# Output Style Definitions — my-plugin

Custom formatting for agent and tool responses.

## Purpose

Output styles control how Claude Code formats responses from plugin tools and agents. They enable compact, consistent, and domain-appropriate output without requiring each tool to implement its own formatting.

## File location

```
output-styles/
  compact-table.md
  dashboard.md
  json-summary.md
```

Output styles are Markdown files in the `output-styles/` directory. Each defines a formatting template that Claude Code applies to matching responses.

## Current status

Output styles are an emerging feature in the Claude Code plugin system. The patterns below reflect current conventions and may evolve.

## Defining an output style

<!-- scaffold:specialize — add plugin-specific output styles -->

```markdown
---
name: compact-status
description: Compact status table for my-service health checks
---

Format health check responses as a table:

| Service | Status | Latency | Details |
| --- | --- | --- | --- |
| [service name] | OK/DEGRADED/DOWN | [ms] | [brief note] |

Rules:
- Use emoji indicators: OK, WARN, FAIL
- Sort by status (failures first)
- Omit healthy services if more than 10 results
- Include timestamp at the bottom
```

## Use cases

| Style | When to apply | Format |
| --- | --- | --- |
| Compact table | List/status responses | Aligned columns, minimal whitespace |
| JSON summary | API responses | Structure with key fields, values omitted |
| Dashboard | Multi-service health | Grouped sections with status indicators |
| Error report | Failure responses | Error, context, suggested fix |

## Configuration

Output styles can be referenced by agents and commands:

```markdown
## Output

Use the `compact-status` output style for health check results.
```

Agents and commands reference styles by name. Claude Code loads the matching style definition and applies its formatting rules.

## Best practices

- Keep styles focused on one output type
- Define clear formatting rules (column order, truncation, sorting)
- Include an example of formatted output in the style definition
- Use styles to reduce token usage on repetitive outputs

## Cross-references

- [AGENTS.md](AGENTS.md) — Agents that apply output styles
- [COMMANDS.md](COMMANDS.md) — Commands that reference output styles
