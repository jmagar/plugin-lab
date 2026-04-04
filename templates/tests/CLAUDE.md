# Tests

This directory defines the testing contract for scaffolded plugins created from `plugin-lab`.

## Purpose

Use `templates/tests/` as the template-side guidance for how generated plugins should organize and think about testing.

## mcporter Testing Situation

Across the MCP server repos, the live-testing story is mixed but predictable:

- Some repos use simple shell live checks for auth and health smoke tests
- Some repos use `mcporter` for schema discovery, tool execution, and request wiring checks
- `unraid-mcp` and `arcane-mcp` are the clearest examples of deeper `mcporter` coverage
- `synapse-mcp` uses a dedicated `test-mcporter.sh` path for tool coverage
- `unifi-mcp` currently does not have a `tests/test_live.sh` script, so its live-testing setup is less standardized than the others

The practical takeaway for scaffolded plugins is that `mcporter` should be the default live contract harness whenever a plugin exposes MCP tools or resources. Use plain `curl` only for the narrow cases where you are checking health endpoints or auth rejection.

## TDD Requirement

When implementing generated plugins, use TDD.

- Write the failing test first
- Verify it fails for the right reason
- Implement the minimal change
- Verify the test passes

Live scripts and `mcporter` checks are contract validation. They do not replace TDD for the underlying code.

## What Belongs Here

- Testing guidance for scaffolded plugins
- Notes about `mcporter` usage
- Test layering expectations
- Repo-neutral testing conventions that should ship with generated output

## Conventions

- Keep this guidance short and operational
- Prefer rules that apply to generated plugins, not just one repo
- Add deeper, repo-specific testing notes in a colocated `CLAUDE.md` if a future template subtree needs it
