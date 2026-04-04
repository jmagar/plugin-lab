# Templates Directory

This directory contains the scaffold source tree used by `plugin-lab` when generating new plugins.

## Purpose

`templates/` is intended to mirror the root of a scaffolded plugin repository. The goal is to keep boilerplate isolated here instead of mixing scaffold assets into the working root of `plugin-lab`.

Over time, this directory should house the current boilerplate files that would otherwise live in the generated plugin root, along with any language-specific folders and scaffold-only supporting structure.

## Mental Model

Treat `templates/` as the canonical template version of a generated plugin root.

- If a file should appear in the root of a newly scaffolded plugin, it should generally live at the matching path under `templates/`
- If a scaffolded plugin needs language-specific source trees, those should also live here under their expected paths
- If a subtree needs its own local rules, document those rules with a colocated `CLAUDE.md`
- If a plugin exposes bare shell executables, place them under `templates/bin/`

This keeps the scaffold contract explicit and prevents generated-plugin boilerplate from being confused with the files used to build and maintain `plugin-lab` itself.

## What Belongs Here

- Root-level boilerplate files for scaffolded plugins
- Language-specific scaffold folders and starter files
- Documentation, config, and manifest templates intended for generated repos
- Reusable scaffold fragments that are part of the generated output shape
- Subdirectories that mimic real paths in generated plugins
- `bin/` scaffolding for plugin executables that should be on `PATH`

## What Does Not Belong Here

- Documentation about how to use `plugin-lab` itself
- Architecture notes for this repo
- Contributor guides for humans working directly in this repo
- Runtime output or generated artifacts produced during scaffolding

Those belong in the top-level `docs/` directory or other repo-owned locations in `plugin-lab`.

## Structure

Keep paths inside `templates/` aligned with the paths they should occupy in scaffolded output. For example, a boilerplate root `README.md` for generated plugins should live at `templates/README.md`, while generated documentation templates should live under `templates/docs/`.

When a template subtree represents a distinct concern, add a local `CLAUDE.md` there to define the contract for that subtree. For `templates/bin/`, document which executables belong there and how they are expected to be invoked from Claude Code plugin workflows.

## Authoring Rules

- Prefer stable, reusable boilerplate over one-off examples
- Keep placeholders explicit and easy to search for
- Preserve path fidelity between `templates/` and generated output whenever practical
- Document required inputs and naming conventions near the template family that uses them
- Avoid mixing repo-maintenance files with scaffold source files
