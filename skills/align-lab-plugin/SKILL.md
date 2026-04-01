---
name: align-lab-plugin
description: Bring an existing MCP plugin into full alignment with the homelab canonical plugin spec. Use when the user wants to update a plugin to current standards, replace stale scaffolding with the `plugin-templates` repo, reconcile manifest drift, standardize Docker and CI files, or turn a review report into a concrete alignment plan and implementation.
---

# Align Lab Plugin

Align an existing plugin to the current homelab canonical spec.

## Start From Evidence

Do not begin editing from vague assumptions.

Start with one of:

- a fresh plugin review
- an existing review report
- a concrete list of files the user wants aligned

If no review exists, perform a quick audit of the canonical surfaces before planning edits.

## Alignment Targets

Prioritize these surfaces:

- manifests and version sync
- `.env.example` and runtime contract
- `Dockerfile` and `docker-compose.yaml`
- `entrypoint.sh`
- `Justfile`
- hook scripts and hook config
- CI workflows
- live tests
- README and CLAUDE guidance
- commands, agents, and skills

## Use Canonical Sources

When aligning files:

- prefer `~/workspace/plugin-templates/` for shared plugin-contract files
- prefer `~/workspace/plugin-templates/<lang>/` for runtime and language-toolchain files
- keep justified plugin-specific differences
- remove stale or duplicated custom scaffolding

Do not erase a deviation just because it differs. Preserve it when it is clearly intentional and still valid.

## Plan Before Editing

Write a concrete alignment plan before making broad edits.

The plan should separate:

- required fixes
- optional improvements
- justified deviations to preserve
- open questions requiring user input

## Implement Safely

Make changes in an order that reduces churn:

1. manifests and config contract
2. runtime and Docker files
3. tests and CI
4. docs and AI-facing files

Do not claim full alignment unless the final files and verification steps support it.

## Produce an Alignment Report

Write the alignment summary to:

- `docs/reports/plugin-alignments/<timestamp>.md`

Include:

- source plugin path
- canonical sources used
- files changed
- preserved deviations
- follow-up work
- verification commands run

## Verification

Run the strongest available local checks for the target plugin after alignment.

Prefer:

- manifest validation
- version-sync checks
- shell syntax checks
- JSON/TOML/YAML parsing
- test or CI-equivalent commands

State clearly what was and was not verified.
