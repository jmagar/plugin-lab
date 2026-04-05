# MCP Tools Reference

<!-- scaffold:specialize — replace example actions/subactions with actual tool surface -->

## Design Philosophy

my-plugin exposes exactly two MCP tools:

| Tool | Purpose | Parameters |
|------|---------|------------|
| `my_plugin` | Primary tool — action+subaction dispatch | `action`, `subaction`, `id?`, `params?` |
| `my_plugin_help` | Returns markdown reference for all actions | _(none)_ |

This 2-tool pattern keeps the MCP surface small while supporting an arbitrarily large action space. Clients call `my_plugin_help` first to discover available operations, then call `my_plugin` with the appropriate action and subaction.

## Primary Tool: `my_plugin`

### Input Schema

```json
{
  "action": "<action>",
  "subaction": "<subaction>",
  "id": "<resource-id>",
  "params": { "<key>": "<value>" }
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | enum | yes | Resource type to operate on |
| `subaction` | enum | yes | Operation to perform on the resource |
| `id` | string | no | Target resource identifier |
| `params` | object | no | Action-specific parameters; include `{ "confirm": true }` for destructive ops |

### Actions

<!-- scaffold:specialize — replace with actual actions for this service -->

| Action | Description | Common Subactions |
|--------|-------------|-------------------|
| `resource` | Manage resources | `list`, `get`, `create`, `update`, `delete` |
| `system` | System operations | `info`, `status`, `health` |

### Subactions

Each action supports a subset of subactions. The full matrix is returned by `my_plugin_help`.

**CRUD subactions** (available on most actions):

| Subaction | Description | Requires `id` |
|-----------|-------------|----------------|
| `list` | List all resources | no |
| `get` | Get a single resource | yes |
| `create` | Create a resource | no |
| `update` | Update a resource | yes |
| `delete` | Delete a resource | yes |

### Response Format

All responses use MCP text content blocks:

```json
{
  "content": [
    {
      "type": "text",
      "text": "## Resources\n\n| Name | Status |\n|------|--------|\n| foo | running |"
    }
  ]
}
```

Responses are formatted as markdown tables or structured text for LLM consumption.

## Help Tool: `my_plugin_help`

Takes no parameters. Returns a markdown document listing all actions, subactions, and usage examples.

```json
// Request
{ "name": "my_plugin_help", "arguments": {} }

// Response
{
  "content": [
    {
      "type": "text",
      "text": "# MyPlugin MCP Server\n\n## Available Actions and Subactions\n..."
    }
  ]
}
```

## Destructive Operations

Operations that modify or delete data require a confirmation gate.

### Confirmation Flow

1. Client calls with destructive subaction (e.g., `delete`):
   ```json
   { "action": "resource", "subaction": "delete", "id": "abc-123" }
   ```

2. Server returns a confirmation prompt:
   ```json
   {
     "content": [{ "type": "text", "text": "Confirm: delete resource abc-123? Re-call with params: { confirm: true }" }]
   }
   ```

3. Client re-calls with confirmation:
   ```json
   { "action": "resource", "subaction": "delete", "id": "abc-123", "params": { "confirm": true } }
   ```

### Safety Environment Variables

| Variable | Default | Effect |
|----------|---------|--------|
| `MY_PLUGIN_MCP_ALLOW_DESTRUCTIVE` | `false` | When `true`, auto-confirms all destructive operations |
| `MY_PLUGIN_MCP_ALLOW_YOLO` | `false` | When `true`, skips elicitation entirely (implies destructive) |

These are intended for CI/testing only. Never enable in production.

## Error Responses

Errors follow a consistent format:

```json
{
  "content": [
    { "type": "text", "text": "Error: resource not found (id: abc-123)" }
  ],
  "isError": true
}
```

Common error types:
- **ValidationError** — invalid action, subaction, or missing required parameter
- **NotFoundError** — resource ID does not exist
- **AuthError** — upstream API rejected credentials
- **TimeoutError** — upstream service did not respond

## Example Tool Calls

```json
// List all resources
{ "action": "resource", "subaction": "list" }

// Get a specific resource
{ "action": "resource", "subaction": "get", "id": "abc-123" }

// Create a resource
{ "action": "resource", "subaction": "create", "params": { "name": "my-resource" } }

// Delete with confirmation
{ "action": "resource", "subaction": "delete", "id": "abc-123", "params": { "confirm": true } }

// System info
{ "action": "system", "subaction": "info" }
```

## See Also

- [SCHEMA.md](SCHEMA.md) — Schema definitions behind these tools
- [AUTH.md](AUTH.md) — Authentication required before tool calls
- [ENV.md](ENV.md) — Safety gate environment variables
