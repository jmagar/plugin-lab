# Claude Plugin Manifest Templates

Target paths relative to plugin root:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

These files are copied as-is into the plugin repo under `.claude-plugin/`.

## Frontmatter / Field Surface

`plugin.json` live example fields:
- `name`
- `description`
- `version`
- `author_url`
- `author.name`
- `author.email`
- `homepage`
- `repository`
- `license`
- `userConfig.<key>.type`
- `userConfig.<key>.title`
- `userConfig.<key>.description`
- `userConfig.<key>.sensitive`
- `userConfig.<key>.default`

`marketplace.json` live example fields:
- `name`
- `owner.name`
- `owner.email`
- `metadata.description`
- `metadata.version`
- `plugins[].name`
- `plugins[].source`
- `plugins[].description`
- `plugins[].version`
- `plugins[].category`
- `plugins[].tags`
- `plugins[].homepage`

Broader notes:
- Keep the live JSON limited to fields confirmed by the actual Claude plugin schema in use.
- If the runtime supports additional marketplace or plugin manifest fields later, document them here first before expanding the live template.
