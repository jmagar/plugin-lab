# `.agents/plugins/`

This subtree contains the repo-scoped plugin marketplace for Codex.

## Purpose

Use this directory for `marketplace.json` and related catalog files that point Codex at local plugins stored in this repository.

## Contract

- Keep `source.path` values relative to the marketplace root and prefixed with `./`
- Use one entry per plugin under `plugins[]`
- Keep `name` and `interface.displayName` stable once they are published to users
- Preserve install policy fields on every plugin entry

## Notes

This is catalog metadata only. The actual plugin content lives in the plugin directories that `marketplace.json` references.
