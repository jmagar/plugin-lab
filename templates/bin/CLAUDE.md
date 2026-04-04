# `templates/bin/`

This subtree contains plugin executables that should be added to `PATH` in generated Claude Code plugin repositories.

## Purpose

Use `templates/bin/` for small, directly invokable helper commands that belong in a plugin scaffold. These files are copied into the generated plugin root at `bin/` and are intended to be called as bare commands from Bash-based workflows, hooks, or other local automation.

## Contract

- Put executable entrypoints here, not repo-maintenance scripts
- Keep the files shell-friendly and portable unless a specific runtime is required
- Make names stable and descriptive so they are safe to expose on `PATH`
- Treat this directory as scaffold output, not as documentation for `plugin-lab` itself

## Expectations

- Each executable should have a shebang
- Executables should be safe to call without extra wrapper logic
- Commands should prefer deterministic behavior and clear exit codes
- If a script needs inputs, document them near the file that consumes them

## Notes for Claude Code Plugins

This subtree is specifically for plugin surfaces that Claude Code can invoke directly from the shell. Use it for generated plugin utilities such as:

- setup helpers
- validation helpers
- lightweight wrapper commands
- plugin-local tooling that needs to be discoverable on `PATH`

Do not use `templates/bin/` for files that are only useful inside this repository's own maintenance workflows.
