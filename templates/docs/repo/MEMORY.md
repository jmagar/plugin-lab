# Memory Files — my-plugin

Claude Code memory system for persistent knowledge across sessions.

## What is memory

Memory files are persistent, file-based knowledge that Claude Code retains across conversation sessions. They store project decisions, user preferences, external system pointers, and learned corrections.

## Location

Memory files live in the `.claude/memory/` directory at the project root:

```
my-plugin/
└── .claude/
    └── memory/
        ├── MEMORY.md              # Index file (pointer list)
        ├── project_architecture.md
        ├── user_preferences.md
        └── reference_upstream_api.md
```

## Index file

`MEMORY.md` is the index — a pointer list linking to individual memory files. Keep it under 200 lines.

```markdown
# Memory Index

- [Architecture Decisions](project_architecture.md) — MCP server layout, tool organization
- [User Preferences](user_preferences.md) — Coding style, review habits
- [Upstream API Notes](reference_upstream_api.md) — Rate limits, quirks, undocumented behavior
```

## Memory types

| Type | Prefix | Purpose | Example |
| --- | --- | --- | --- |
| `user` | `user_` | User-specific info | Role, preferences, team context |
| `feedback` | `feedback_` | Corrections and learned behaviors | "Always use uv, not pip" |
| `project` | `project_` | Project decisions and architecture | Tech stack choices, patterns |
| `reference` | `reference_` | External system pointers | API quirks, service endpoints |

## Frontmatter format

Every memory file starts with YAML frontmatter:

```yaml
---
name: architecture-decisions
description: MCP server architecture and tool organization patterns
type: project
---
```

## When to save

Save memory when encountering:

- User role or team context ("I'm the infra lead")
- Corrections to previous behavior ("Use ruff, not flake8")
- Project architecture decisions ("We chose FastMCP over raw SDK")
- External system pointers ("The upstream API has a 100 req/min limit")
- Non-obvious conventions ("All tool names use kebab-case")

## When NOT to save

Do not save:

- Code patterns visible in the codebase (read the code instead)
- Git history facts (use `git log`)
- Debugging sessions and their solutions (ephemeral)
- Temporary state ("Currently working on feature X")
- Information already in `CLAUDE.md` or documentation files

## Memory vs other persistence

| Mechanism | Scope | Lifetime | Use for |
| --- | --- | --- | --- |
| Memory files | Project-wide | Permanent | Decisions, preferences, pointers |
| `CLAUDE.md` | Project-wide | Permanent | Instructions, conventions, rules |
| Git commits | Project-wide | Permanent | Code history |
| Session context | Single session | Ephemeral | Current task state |

## Managing memory

- Review memory files periodically — remove stale entries
- Keep individual files focused on one topic
- Update the index when adding or removing files
- Memory files are committed to git (no credentials in memory files)
