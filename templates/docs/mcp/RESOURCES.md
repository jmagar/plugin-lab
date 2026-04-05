# MCP Resources Reference

<!-- scaffold:specialize — replace example resources with actual resource URIs -->

## Overview

MCP resources expose read-only data via URI-based access. Unlike tools, resources do not perform mutations — they return the current state of a data source.

Use resources when:
- Reading current state or configuration
- Browsing hierarchical data (environments, projects, containers)
- Providing context to the LLM without tool invocation overhead

Use tools when:
- Creating, updating, or deleting data
- Performing operations with side effects
- Requiring parameterized queries beyond URI templating

## URI Scheme

All resources use the `my-plugin://` scheme:

```
my-plugin://<resource-type>
my-plugin://<resource-type>/{id}
my-plugin://<resource-type>/{id}/<sub-resource>
```

## Available Resources

<!-- scaffold:specialize — populate with actual resources -->

| URI | Description | MIME Type |
|-----|-------------|-----------|
| `my-plugin://resources` | List all resources | `application/json` |
| `my-plugin://resources/{id}` | Single resource by ID | `application/json` |
| `my-plugin://resources/{id}/details` | Resource details | `application/json` |
| `my-plugin://status` | Service status | `application/json` |

## Registration Pattern

Resources are registered on the McpServer instance. Two forms exist:

**Static URI** — fixed path, no parameters:

```typescript
server.resource(
  "my-plugin-resources",          // registration name
  "my-plugin://resources",        // static URI
  { description: "List of all resources" },
  async (uri) => ({
    contents: [{
      uri: uri.href,
      mimeType: "application/json",
      text: JSON.stringify(await service.list(), null, 2),
    }],
  }),
);
```

**Templated URI** — parameterized path:

```typescript
server.resource(
  "my-plugin-resource-details",
  new ResourceTemplate("my-plugin://resources/{id}/details", { list: undefined }),
  { description: "Details for a specific resource" },
  async (uri, variables) => {
    const id = variables.id as string;
    const data = await service.get(id);
    return {
      contents: [{
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify(data, null, 2),
      }],
    };
  },
);
```

## Response Format

Resource responses return a `contents` array with URI, MIME type, and text payload:

```json
{
  "contents": [
    {
      "uri": "my-plugin://resources",
      "mimeType": "application/json",
      "text": "[{\"id\": \"abc-123\", \"name\": \"example\", \"status\": \"active\"}]"
    }
  ]
}
```

The `text` field contains serialized JSON. Clients parse the JSON from the text value.

## See Also

- [TOOLS.md](TOOLS.md) — For operations that mutate data
- [SCHEMA.md](SCHEMA.md) — Schema definitions for resource data shapes
