---
description: Create, review, or update MCP tools using the action+subaction pattern
argument-hint: <plugin-path> [create|review|update] [tool-name]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Tool Lab Plugin

Use the `tool-lab-plugin` skill and `tilly-the-toolsmith` agent to create, review, or update MCP tools.

## Inputs

Start from `$ARGUMENTS`.

Parse as: `<plugin-path> [mode] [tool-name]`

- `mode` defaults to `create` if not specified
- `tool-name` is required for `create` and `update`; optional for `review`

If any required input is missing, ask before proceeding.

## Workflow

1. Read [skills/tool-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/tool-lab-plugin/SKILL.md).
2. Spawn `tilly-the-toolsmith`.
3. Tell Tilly to:
   - inspect the plugin at the provided path
   - for `create`: gather the operation set and produce a full tool contract + handlers
   - for `review`: audit all tools for action+subaction conformance and produce a findings list
   - for `update`: identify the gap, update schema/dispatch/handlers, and keep the help tool in sync
   - dispatch a `rex-the-researcher` worker if the wrapped API may have changed

## Required Output

Tilly should return:

- the tool contract (action enum, subaction enums, parameter schemas)
- the dispatch table shape
- handler stubs or implementations
- the `*_help` companion tool definition
- any breaking-change warnings if updating stable pairs
