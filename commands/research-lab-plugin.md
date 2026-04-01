---
description: Research current plugin/MCP/runtime guidance for lab work
argument-hint: <topic or target stack>
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, Task, Skill
---

# Research Lab Plugin

Invoke the `lab-research-specialist` skill, then spawn `rex-the-researcher` to gather current primary-source guidance on `$ARGUMENTS`.

## Inputs

`$ARGUMENTS` is the research topic or target stack. If vague, clarify before spawning. Example valid topics:

- TypeScript MCP server stack
- latest Claude plugin manifest behavior
- Codex plugin manifest + app config
- current FastMCP or RMCP patterns
- Docker and auth guidance for remote MCP servers

## Workflow

1. Invoke the `lab-research-specialist` skill.
2. Spawn `rex-the-researcher` with the topic.
3. For broad coverage, direct Rex to split work into parallel tracks:
   - MCP protocol and transport
   - Claude Code plugin docs
   - Codex plugin docs
   - language SDK/runtime updates
   - adjacent Docker/auth/testing guidance
4. Synthesize findings into one report with:
   - confirmed facts (primary sources cited)
   - changes from prior assumptions
   - implications for templates
   - implications for existing plugins

## Required Artifact

Write the result to:

- `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md`

Mark inferences explicitly. Primary sources take precedence over secondary.
