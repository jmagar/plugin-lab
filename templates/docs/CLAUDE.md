# Documentation Templates

This directory contains documentation template assets that `plugin-lab` can use when scaffolding or updating plugin and MCP-server documentation in other repositories.

## Purpose

Use this subtree for template source files that produce docs for generated plugins or MCP servers. These are not docs for `plugin-lab` itself; they are boilerplate inputs that the generator will render or copy into target repos.

## Intended Scope

This area is reserved for MCP server documentation templates first. It should grow into a consistent template pack for common generated docs such as:

- Overview or README-style docs
- Installation and setup docs
- Configuration docs
- Tools or API reference docs
- Operational notes and troubleshooting docs

## Boundaries

- Put human-facing documentation for developing or using `plugin-lab` in the repo's top-level `docs/`
- Put generated target-repo doc boilerplate here
- Keep naming and placeholder conventions consistent across all template files added here

## Future Conventions

When concrete templates are added, keep them grouped by documentation concern or scaffold family. If a template family needs its own rules, add another colocated `CLAUDE.md` in that subtree.
