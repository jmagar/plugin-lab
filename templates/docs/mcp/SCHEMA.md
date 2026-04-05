# Tool Schema Documentation

## Overview

Tool schemas define the input validation contract for MCP tools. Schemas are defined in code using the language-native validation library, and can be exported as JSON Schema for documentation and client validation.

## Schema Libraries by Language

| Language | Library | Schema Location |
|----------|---------|-----------------|
| TypeScript | [Zod](https://zod.dev/) | `src/mcp/tools/*.ts` |
| Python | [Pydantic](https://docs.pydantic.dev/) | `src/mcp/tools/*.py` |
| Rust | [serde](https://serde.rs/) + [schemars](https://docs.rs/schemars/) | `src/mcp/tools/*.rs` |

## Schema Definition Examples

### TypeScript (Zod)

```typescript
import { z } from "zod";

server.tool(
  "my_plugin",
  "Manage my-service resources",
  {
    action: z.enum(["resource", "system"])
      .describe("Resource type to operate on"),
    subaction: z.enum(["list", "get", "create", "update", "delete"])
      .describe("Operation to perform"),
    id: z.string().optional()
      .describe("Target resource ID"),
    params: z.record(z.string(), z.unknown()).optional()
      .describe("Action-specific parameters"),
  },
  async ({ action, subaction, id, params }) => { /* ... */ }
);
```

### Python (Pydantic)

```python
from enum import Enum
from pydantic import BaseModel, Field
from typing import Optional

class Action(str, Enum):
    resource = "resource"
    system = "system"

class Subaction(str, Enum):
    list = "list"
    get = "get"
    create = "create"
    update = "update"
    delete = "delete"

class MyPluginInput(BaseModel):
    action: Action = Field(description="Resource type to operate on")
    subaction: Subaction = Field(description="Operation to perform")
    id: Optional[str] = Field(None, description="Target resource ID")
    params: Optional[dict] = Field(None, description="Action-specific parameters")
```

### Rust (serde + schemars)

```rust
use schemars::JsonSchema;
use serde::Deserialize;

#[derive(Debug, Deserialize, JsonSchema)]
#[serde(rename_all = "kebab-case")]
pub enum Action {
    Resource,
    System,
}

#[derive(Debug, Deserialize, JsonSchema)]
#[serde(rename_all = "kebab-case")]
pub enum Subaction {
    List, Get, Create, Update, Delete,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct MyPluginInput {
    pub action: Action,
    pub subaction: Subaction,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub params: Option<serde_json::Value>,
}
```

## JSON Schema Output

All schema libraries produce JSON Schema. The generated output for the primary tool:

```json
{
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "enum": ["resource", "system"],
      "description": "Resource type to operate on"
    },
    "subaction": {
      "type": "string",
      "enum": ["list", "get", "create", "update", "delete"],
      "description": "Operation to perform"
    },
    "id": {
      "type": "string",
      "description": "Target resource ID"
    },
    "params": {
      "type": "object",
      "additionalProperties": true,
      "description": "Action-specific parameters"
    }
  },
  "required": ["action", "subaction"]
}
```

## Schema Generation

Generate JSON Schema from code with a Justfile recipe:

```bash
just gen-mcp-schema
```

<!-- scaffold:specialize — define the actual gen-mcp-schema recipe for this stack -->

This outputs `docs/mcp/schema.json` (or prints to stdout) from the source-of-truth schema definitions.

## Keeping Schema and Docs in Sync

1. **Schema is defined in code** — the validation library is the single source of truth
2. **TOOLS.md documents behavior** — action descriptions, subaction semantics, examples
3. **JSON Schema is generated** — never hand-edit `schema.json`
4. **CI can validate** — compare generated schema against committed schema to catch drift

Workflow:
```
Code schema (Zod/Pydantic/serde)
  -> just gen-mcp-schema
  -> schema.json (generated)
  -> TOOLS.md (manually maintained, references schema)
```

## Input Validation

The schema library validates all inputs before dispatch:
- Missing required fields return a `ValidationError`
- Invalid enum values return a `ValidationError` listing valid options
- Type mismatches (e.g., number where string expected) are rejected

## See Also

- [TOOLS.md](TOOLS.md) — Tool behavior documentation
- [RESOURCES.md](RESOURCES.md) — Resource data shapes
