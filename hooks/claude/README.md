# Claude Hook Templates

Target path relative to plugin root:
- `hooks/hooks.json`

The `docs/` files in this directory are reference material. The JSON file is the actual template to copy.

## Hook JSON Field Surface

Plugin-safe or confirmed fields shown in the live example:
- top-level `description`
- `hooks`
- event name (`SessionStart`, `PostToolUse`)
- matcher group `matcher`
- matcher group `hooks`
- hook handler `type`
- hook handler `command`
- hook handler `timeout`

Broader runtime fields not shown in the live example:
- `if`
- `timeoutSec`
- `statusMessage`
