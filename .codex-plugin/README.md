# Codex Plugin Manifest Templates

Target paths relative to plugin root:
- `.codex-plugin/plugin.json`

These files are copied as-is into the plugin repo under `.codex-plugin/`.

## Frontmatter / Field Surface

`plugin.json` live example fields:
- `name`
- `author.name`
- `author.email`
- `author.url`
- `description`
- `version`
- `skills`
- `homepage`
- `repository`
- `license`
- `keywords`
- `mcpServers`
- `apps`
- `interface.displayName`
- `interface.shortDescription`
- `interface.longDescription`
- `interface.developerName`
- `interface.category`
- `interface.capabilities`
- `interface.websiteURL`
- `interface.privacyPolicyURL`
- `interface.termsOfServiceURL`
- `interface.defaultPrompt`
- `interface.brandColor`
- `interface.composerIcon`
- `interface.logo`
- `interface.screenshots`

Broader notes:
- The bundled local Codex docs also show a richer published-plugin manifest with install-surface metadata in `.codex-plugin/plugin.json`.
- `.agents/plugins/marketplace.json` still carries marketplace selection and install policy for local or curated catalogs.
- Keep the live example limited to fields confirmed by the current Codex plugin schema you are targeting.
