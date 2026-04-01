---
description: Create, review, or update a plugin's MCP tools
argument-hint: <plugin-path> [create|review|update] [tool-name]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Tool Lab Plugin

Invoke the `tool-lab-plugin` skill, then spawn `tilly-the-toolsmith` to work on MCP tools for the plugin at `$ARGUMENTS`.

## Inputs

Parse `$ARGUMENTS` as: `<plugin-path> [mode] [tool-name]`

- `mode` defaults to `create` if not specified
- `tool-name` is required for `create` and `update`; optional for `review`

Ask for missing required inputs before proceeding.

## Workflow

1. Invoke the `tool-lab-plugin` skill.
2. Spawn `tilly-the-toolsmith` with the plugin path, mode, and tool name.
3. Direct Tilly to:
   - inspect the plugin at the provided path
   - for `create`: gather the operation set and produce a full action+subaction contract + handler stubs
   - for `review`: audit all tools for action+subaction conformance and produce a findings list
   - for `update`: identify the gap, update schema/dispatch/handlers, and keep the `*_help` tool in sync
   - dispatch a `rex-the-researcher` worker if the wrapped service API may have changed

## Required Output

- the tool contract (action enum, subaction enums, parameter schemas)
- the dispatch table shape
- handler stubs or full implementations
- the `*_help` companion tool definition
- any breaking-change warnings if updating stable action/subaction pairs
