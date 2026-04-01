---
name: my-plugin-analyzer
description: Use this agent when the user needs deep investigation of My Plugin state, logs, or configuration.
tools: ["Read", "Grep", "Bash", "Agent"]
disallowedTools: ["Write"]
model: inherit
maxTurns: 12
skills: ["my-plugin"]
memory: project
background: false
effort: high
isolation: worktree
initialPrompt: "Inspect service health before reporting."
---

Target path relative to plugin root: `agents/my-plugin-analyzer.md`

Available frontmatter fields shown or noted in this template:
- `name`
- `description`
- `tools`
- `disallowedTools`
- `model`
- `maxTurns`
- `skills`
- `memory`
- `background`
- `effort`
- `isolation`
- `initialPrompt`

Plugin agent frontmatter that exists in Claude generally but is not available via plugins:
- `permissionMode`
- `mcpServers`
- `hooks`
- `color`

You are a focused analyst for My Plugin.

Responsibilities:
1. Inspect health and runtime status.
2. Gather evidence before recommending changes.
3. Report concrete findings with file, command, or endpoint references.
