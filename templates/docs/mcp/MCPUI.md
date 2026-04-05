# MCP UI Patterns

Protocol-level UI hints for MCP servers to improve client-side rendering of tools and results.

<!-- scaffold:specialize -- update tool names and UI examples -->

## What is MCP UI

MCP UI is a set of protocol annotations that allow MCP servers to provide rendering hints to clients. Instead of clients displaying raw JSON or plain text, servers can suggest how tool parameters should be collected and how results should be displayed.

MCP UI does not mandate a specific UI framework. It provides schema-level metadata that clients interpret according to their rendering capabilities (CLI, web, native).

## UI capabilities

### Tool parameter forms

Schema annotations guide how clients present input fields:

```json
{
  "name": "my_plugin",
  "inputSchema": {
    "type": "object",
    "properties": {
      "action": {
        "type": "string",
        "enum": ["list_items", "get_item", "delete_item", "health"],
        "description": "Operation to perform",
        "x-ui-widget": "select"
      },
      "id": {
        "type": "integer",
        "description": "Item ID",
        "x-ui-widget": "number",
        "x-ui-condition": {"action": ["get_item", "delete_item"]}
      },
      "confirm": {
        "type": "boolean",
        "description": "Confirm destructive operation",
        "x-ui-widget": "checkbox",
        "x-ui-condition": {"action": ["delete_item"]}
      }
    }
  }
}
```

| Annotation | Purpose |
|------------|---------|
| `x-ui-widget` | Preferred input widget (select, text, number, checkbox, textarea) |
| `x-ui-condition` | Show field only when other fields match specified values |
| `x-ui-placeholder` | Placeholder text for input fields |
| `x-ui-group` | Group related fields under a collapsible section |

### Result visualization

Tool responses can include rendering hints:

```json
{
  "content": [
    {
      "type": "text",
      "text": "| Name | Status |\n|------|--------|\n| item-1 | active |\n| item-2 | stopped |",
      "annotations": {
        "x-ui-render": "table"
      }
    }
  ]
}
```

| Hint | Rendering |
|------|-----------|
| `table` | Parse markdown table into sortable/filterable grid |
| `json` | Syntax-highlighted, collapsible JSON tree |
| `log` | Monospace, auto-scroll, timestamp-aware |
| `chart` | Render data series as a chart (client-dependent) |

### Status dashboards

Servers can expose a status resource for dashboard rendering:

```json
{
  "uri": "my-plugin://status",
  "name": "Service Status",
  "annotations": {
    "x-ui-render": "dashboard",
    "x-ui-refresh": 30
  }
}
```

The `x-ui-refresh` hint tells clients to poll the resource at the specified interval (seconds).

### Configuration panels

For elicitation-backed configuration, UI annotations describe the form layout:

```json
{
  "schema": {
    "type": "object",
    "properties": {
      "url": {
        "type": "string",
        "format": "uri",
        "x-ui-widget": "url",
        "x-ui-group": "Connection"
      },
      "api_key": {
        "type": "string",
        "x-ui-widget": "password",
        "x-ui-group": "Connection"
      },
      "log_level": {
        "type": "string",
        "enum": ["DEBUG", "INFO", "WARNING", "ERROR"],
        "x-ui-widget": "select",
        "x-ui-group": "Advanced"
      }
    }
  }
}
```

## Implementation

Adding UI annotations to an existing MCP server requires no code changes to tool logic. Annotations are added to:

1. **Tool input schemas** -- `x-ui-*` properties alongside standard JSON Schema fields.
2. **Response content** -- `annotations` object on content items.
3. **Resource metadata** -- `annotations` on resource definitions.

Clients that do not understand `x-ui-*` annotations ignore them. The server remains fully functional for CLI-only clients.

## Current status

MCP UI is an emerging specification. Current support:

| Feature | Status |
|---------|--------|
| JSON Schema for tool inputs | Stable (core MCP) |
| Content type annotations | Stable (core MCP) |
| `x-ui-*` widget hints | Draft proposal |
| Conditional field visibility | Draft proposal |
| Dashboard resources | Draft proposal |
| Chart rendering | Experimental |

Servers should include UI annotations where useful but must not depend on clients rendering them. All tool functionality must work without UI support.

## Future direction

- Standardized `x-ui-*` vocabulary across MCP implementations.
- Client-side component library for common MCP UI patterns.
- Bidirectional UI: clients sending layout preferences to servers.
- Integration with Web MCP for browser-native rendering (see [WEBMCP](WEBMCP.md)).

See also: [WEBMCP](WEBMCP.md) | [TOOLS](TOOLS.md) | [SCHEMA](SCHEMA.md)
