---
name: tool-lab-plugin
description: Create, review, or update MCP tools inside a plugin using the action+subaction dispatch pattern. Use when the user wants to add a new tool to an existing plugin, audit existing tools for conformance, refactor a flat tool list into action+subaction shape, or generate the parameter schema and dispatch logic for a tool.
---

# Tool Lab Plugin

Design and implement MCP tools that follow the canonical action+subaction dispatch pattern.

## Understand the Action+Subaction Pattern

Every tool exposes a single entry point with two required parameters:

- `action` — the high-level operation (e.g., `message`, `application`, `client`)
- `subaction` — the specific verb within that operation (e.g., `create`, `list`, `delete`)

Additional parameters are operation-specific and validated after dispatch.

Example shape:

```json
{
  "name": "gotify",
  "description": "Manage Gotify notifications",
  "inputSchema": {
    "type": "object",
    "properties": {
      "action": {
        "type": "string",
        "enum": ["message", "application", "client"],
        "description": "Resource to operate on"
      },
      "subaction": {
        "type": "string",
        "enum": ["create", "list", "delete", "get"],
        "description": "Operation to perform"
      }
    },
    "required": ["action", "subaction"]
  }
}
```

A companion `*_help` tool lists all valid action+subaction combinations with parameter details.

## Gather Inputs First

Before designing or modifying tools, collect:

- plugin name and language
- the service or API being wrapped
- the operations the tool must support
- existing tool definitions if reviewing or updating
- any naming constraints (existing MCP tool names, service terminology)

If inputs are missing, ask before proceeding.

## Creating a New Tool

Produce in order:

1. **Tool contract** — action enum, subaction enum per action, parameter schemas
2. **Dispatch table** — how action+subaction maps to handler functions
3. **Handler stubs** — one function per action+subaction pair
4. **Help tool** — lists all valid combinations with required/optional params
5. **Registration** — how the tool is registered with the MCP server

Follow the language-specific handler pattern from `~/workspace/plugin-templates/<lang>/`.

## Reviewing Existing Tools

Check for:

- flat tools that should be collapsed into action+subaction shape
- missing `*_help` companion tool
- undocumented or inconsistent parameter names
- actions or subactions not reflected in the enum
- handlers that do not validate parameters before calling the service
- error responses that don't follow the canonical error shape

Produce a findings list with file references before making changes.

## Updating Tools

When modifying existing tools:

1. Review current tool contract and handler set
2. Identify the gap (missing subaction, wrong parameter, enum drift)
3. Update the schema, dispatch table, and handler in one coherent change
4. Update the help tool to reflect the new shape
5. Update any affected tests

Avoid renaming stable action/subaction pairs — that is a breaking change.

## Required Output

At minimum:

- the tool contract (schema)
- the dispatch table shape
- the handler stubs or implementations
- the help tool definition
- any breaking-change warnings
