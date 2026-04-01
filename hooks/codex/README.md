Target path relative to plugin root:
- `hooks/hooks.json`

Hooks are behind a feature flag in config.toml:

[features]
codex_hooks = true

Codex discovers hooks.json next to active config layers.

In practice, the two most useful locations are:

~/.codex/hooks.json
<repo>/.codex/hooks.json
If more than one hooks.json file exists, Codex loads all matching hooks. Higher-precedence config layers do not replace lower-precedence hooks.


Latest generated schemas: 
https://github.com/openai/codex/tree/main/codex-rs/hooks/schema/generated

## Hook JSON field surface shown in the example

- `hooks`
- event name (`SessionStart`, `PreToolUse`, `Stop`)
- matcher group `matcher`
- matcher group `hooks`
- hook handler `type`
- hook handler `command`
- hook handler `timeout`
- hook handler `statusMessage`
