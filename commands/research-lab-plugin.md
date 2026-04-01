---
description: Research current MCP/plugin/runtime guidance for lab plugin work
argument-hint: <topic or target stack>
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, Task, Skill
---

# Research Lab Plugin

Use the `lab-research-specialist` skill and `rex-the-researcher` agent to gather current primary-source guidance for plugin work.

## Inputs

Start from `$ARGUMENTS`.

If the topic is vague, clarify the exact research target first. Examples:

- TypeScript MCP server stack
- latest Claude plugin manifest behavior
- Codex plugin manifest + app config
- current FastMCP or RMCP patterns
- Docker and auth guidance for remote MCP servers

## Workflow

1. Read [skills/lab-research-specialist/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/lab-research-specialist/SKILL.md).
2. Spawn `rex-the-researcher`.
3. When broad coverage is needed, have Rex split work into parallel tracks such as:
   - MCP protocol and transport
   - Claude Code plugin docs
   - Codex plugin docs
   - language SDK/runtime updates
   - adjacent Docker/auth/testing guidance
4. Synthesize the findings into one report with:
   - confirmed facts
   - changes from prior assumptions
   - implications for templates
   - implications for existing plugins

## Required Artifact

Write the result to:

- `docs/research/<topic>-<timestamp>.md`

Use primary sources wherever possible and mark inferences explicitly.
