---
description: Inspect My Plugin health, state, or resources
allowed-tools: Bash(curl:*), mcp__my-plugin-mcp__my_plugin
argument-hint: [resource-id] [--verbose] [--json]
model: sonnet
---

Target path relative to plugin root: `commands/my-plugin/inspect.md`

This is a maximal Claude slash-command template. Replace the filename, namespace, and tool names for the real plugin command.

## Frontmatter Reference

Plugin-safe fields shown in the live example:
- `description`
  - Required in practice.
  - Short autocomplete text shown to the user.
- `allowed-tools`
  - Optional but strongly recommended.
  - Pre-approves tools for this command.
- `argument-hint`
  - Optional.
  - Documents the expected CLI-like arguments for the command.
- `model`
  - Optional.
  - Pins command execution to a specific Claude model.

Broader notes:
- This template only shows fields that are already in use for command-style Markdown templates here.
- If additional command frontmatter is introduced later, document it next to the template before adding it to the live example.

## Instructions

1. If `$ARGUMENTS` is empty, inspect overall service health.
2. If `$ARGUMENTS` contains a resource id, fetch that resource first.
3. If `$ARGUMENTS` contains `--verbose`, include recent logs or expanded fields.
4. Prefer MCP mode when the tool is available.
5. Fall back to HTTP only when MCP is unavailable.
6. Never perform destructive actions in this command.
