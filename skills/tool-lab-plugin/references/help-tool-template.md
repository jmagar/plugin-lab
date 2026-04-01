# Help Tool Template

Every plugin that uses the action+subaction dispatch pattern must include a companion help tool. This document defines the tool's name convention, inputSchema, response shape, and provides a concrete example.

## Name Convention

The help tool is named `<plugin-name>_help`.

Examples:
- Main tool: `gotify` → Help tool: `gotify_help`
- Main tool: `overseerr` → Help tool: `overseerr_help`
- Main tool: `paperless_ngx` → Help tool: `paperless_ngx_help`

The help tool is registered as a separate tool alongside the main tool, not as a subaction of the main tool.

## InputSchema

The help tool takes no required parameters. An optional `action` filter narrows the output to a single resource group.

```json
{
  "name": "gotify_help",
  "description": "List all valid action/subaction combinations for the gotify tool, with their required and optional parameters.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "action": {
        "type": "string",
        "description": "Optional. Filter output to this action only. If omitted, all actions are listed.",
        "enum": ["message", "application", "client"]
      }
    },
    "required": []
  }
}
```

## Response Shape

The help tool returns `isError: false` with a plain-text table in the content array. The table has four columns:

| Column | Content |
|--------|---------|
| `action` | The resource name |
| `subaction` | The operation verb |
| `required` | Comma-separated list of required parameter names, or `—` |
| `optional` | Comma-separated list of optional parameter names, or `—` |

```json
{
  "isError": false,
  "content": [
    {
      "type": "text",
      "text": "<the text table>"
    }
  ]
}
```

## Concrete Example: Gotify Plugin

The following is the actual response content for `gotify_help` (the Gotify plugin is used as the reference example throughout this template — substitute your plugin's actual operations).

```
gotify tool — available action/subaction combinations

action        subaction   required              optional
-----------   ---------   -------------------   ----------------
message       create      title                 message, priority, app_token
message       list        —                     app_id, limit
message       delete      id                    —
application   create      name                  description
application   list        —                     —
application   delete      id                    —
application   update      id, name              description
client        create      name                  —
client        list        —                     —
client        delete      id                    —

Use: {"action": "<action>", "subaction": "<subaction>", ...params}
For filtered help: {"action": "message"}
```

## Implementation Sketch

### Python

```python
HELP_TABLE = {
    "message": [
        {"subaction": "create",  "required": ["title"],  "optional": ["message", "priority", "app_token"]},
        {"subaction": "list",    "required": [],         "optional": ["app_id", "limit"]},
        {"subaction": "delete",  "required": ["id"],     "optional": []},
    ],
    "application": [
        {"subaction": "create",  "required": ["name"],        "optional": ["description"]},
        {"subaction": "list",    "required": [],              "optional": []},
        {"subaction": "delete",  "required": ["id"],          "optional": []},
        {"subaction": "update",  "required": ["id", "name"],  "optional": ["description"]},
    ],
    "client": [
        {"subaction": "create",  "required": ["name"],  "optional": []},
        {"subaction": "list",    "required": [],        "optional": []},
        {"subaction": "delete",  "required": ["id"],    "optional": []},
    ],
}

def render_help(action_filter: str | None = None) -> str:
    lines = ["gotify tool — available action/subaction combinations", ""]
    lines.append(f"{'action':<14}{'subaction':<12}{'required':<22}{'optional'}")
    lines.append(f"{'-'*11:<14}{'-'*9:<12}{'-'*19:<22}{'-'*16}")

    actions = [action_filter] if action_filter else list(HELP_TABLE.keys())
    for action in actions:
        for row in HELP_TABLE.get(action, []):
            req = ", ".join(row["required"]) if row["required"] else "—"
            opt = ", ".join(row["optional"]) if row["optional"] else "—"
            lines.append(f"{action:<14}{row['subaction']:<12}{req:<22}{opt}")

    lines.append("")
    lines.append('Use: {"action": "<action>", "subaction": "<subaction>", ...params}')
    if not action_filter:
        lines.append('For filtered help: {"action": "message"}')
    return "\n".join(lines)


async def handle_help_tool(params: dict) -> dict:
    action_filter = params.get("action")
    return {
        "isError": False,
        "content": [{"type": "text", "text": render_help(action_filter)}],
    }
```

## Why the Help Tool Matters

MCP clients — including Claude — can call the help tool at runtime to discover what a plugin supports without reading the JSON schema or source code. This is especially useful when:

- A user asks "what can the gotify tool do?" — the model calls `gotify_help` and relays the table.
- A model is unsure which subaction handles a particular operation — it calls `gotify_help` with an `action` filter to narrow the list.
- An automated audit tool (e.g., `review-lab-plugin`) checks for `*_help` conformance — a missing or malformed help tool is flagged as a finding.

The help tool is not optional. Every plugin using the action+subaction pattern must include it.
