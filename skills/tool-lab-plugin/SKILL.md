---
name: tool-lab-plugin
description: Create, review, or update MCP tools inside a plugin using the action+subaction dispatch pattern. Use when the user wants to add a new tool to an existing plugin, audit existing tools for conformance, refactor a flat tool list into action+subaction shape, or generate the parameter schema and dispatch logic for a tool.
---

# Tool Lab Plugin

Design and implement MCP tools that follow the canonical action+subaction dispatch pattern.

## Understand the Action+Subaction Pattern

Every tool exposes a single entry point with two required parameters:

- `action` — the high-level resource being operated on (e.g., `message`, `application`, `client`)
- `subaction` — the specific verb within that resource (e.g., `create`, `list`, `delete`)

Additional parameters are operation-specific and validated after dispatch.

**Note:** The action and subaction values in the example below are from the Gotify plugin. Substitute your plugin's actual resource names and verbs.

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

A companion `*_help` tool lists all valid action+subaction combinations with parameter details (see `references/help-tool-template.md`).

## Canonical Error Shape

Every tool call that fails must return this shape — never throw an unhandled exception:

```json
{
  "isError": true,
  "content": [
    {
      "type": "text",
      "text": "Error: <action>/<subaction> failed — <reason>"
    }
  ]
}
```

`isError: true` signals to the MCP client that the tool call failed (as distinct from a successful call that returns an error message in its content). The MCP client uses this flag to decide whether to surface a tool failure vs. relay a normal response. See `references/canonical-error-shape.md` for language-specific helper functions and common mistakes.

## Dispatch Table

Map `(action, subaction)` tuples to handler functions. This is the canonical Python pattern:

```python
DISPATCH = {
    ("message", "create"): handle_message_create,
    ("message", "list"):   handle_message_list,
    ("message", "delete"): handle_message_delete,
    ("application", "create"): handle_application_create,
    ("application", "list"):   handle_application_list,
    # add rows as you add handlers
}

async def handle_tool(action: str, subaction: str, params: dict) -> dict:
    handler = DISPATCH.get((action, subaction))
    if handler is None:
        return error_response(f"Unknown action/subaction: {action}/{subaction}")
    return await handler(params)
```

For Rust and TypeScript dispatch patterns, see `references/dispatch-table-patterns.md`.

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

Follow the language-specific handler pattern from the appropriate language layer directory:

- Python: `~/workspace/plugin-templates/py/`
- Rust: `~/workspace/plugin-templates/rs/`
- TypeScript: `~/workspace/plugin-templates/ts/`

## The Help Tool

Every plugin must include a `<plugin-name>_help` tool alongside the main tool. Its inputSchema takes no required parameters (optionally an `action` filter). Its response is a plain-text table listing every valid action/subaction pair and their parameters. MCP clients can call it to discover capabilities at runtime without reading the JSON schema.

See `references/help-tool-template.md` for the full structure, response format, and a concrete Gotify example.

## Reviewing Existing Tools

Check for:

- flat tools that should be collapsed into action+subaction shape
- missing `*_help` companion tool
- undocumented or inconsistent parameter names
- actions or subactions not reflected in the enum
- handlers that do not validate parameters before calling the service
- error responses that don't follow the canonical error shape (especially: exceptions thrown instead of returned, `isError: false` with error text, missing `content` array wrapper)

Produce a findings list with file references before making changes.

## Updating Tools

When modifying existing tools:

1. Review current tool contract and handler set
2. Identify the gap (missing subaction, wrong parameter, enum drift)
3. Update the schema, dispatch table, and handler in one coherent change
4. Update the help tool to reflect the new shape
5. Update any affected tests

Avoid renaming stable action/subaction pairs — that is a breaking change.

## Test Guidance

Tests for MCP tools live in two places:

- `tests/test_live.sh` — shell integration tests that hit the real running service. Run these against a real deployment to verify end-to-end behavior.
- Language-specific unit test files that mock the service layer:
  - Python: `tests/test_tools.py`
  - Rust: `tests/tools_test.rs`
  - TypeScript: `tests/tools.test.ts`

Unit tests mock the service layer and verify dispatch, parameter validation, and error shape. Live tests hit the real service and verify the full stack. When adding a new action/subaction pair, add both a unit test for the handler and a live test for the round-trip.

## Required Output

At minimum:

- the tool contract (schema)
- the dispatch table shape
- the handler stubs or implementations
- the help tool definition
- any breaking-change warnings

## Related Skills

- **scaffold-lab-plugin** — creates the plugin structure that the tools live in
- **pipeline-lab-plugin** — CI pipeline that runs the tool tests
- **review-lab-plugin** — audits existing plugins for `*_help` conformance and canonical error shape
