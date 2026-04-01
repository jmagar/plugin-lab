# Agent Marketplace Template

Target path relative to plugin root:
- `.agents/plugins/marketplace.json`

Use this only for repos that publish marketplace metadata for agent-capable tooling.

Live example fields:
- `name`
- `interface.displayName`
- `plugins[].name`
- `plugins[].source.source`
- `plugins[].source.path`
- `plugins[].policy.installation`
- `plugins[].policy.authentication`
- `plugins[].category`

Broader notes:
- The bundled local Codex docs put marketplace display and install policy here.
- Plugin-specific install-surface metadata can also exist in `.codex-plugin/plugin.json`.
- If marketplace metadata grows beyond these fields, document the additions here before expanding the JSON template.
