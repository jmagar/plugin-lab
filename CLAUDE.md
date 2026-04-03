# plugin-templates Development Notes

This repo exists to hold the canonical MCP plugin scaffold.

## Source of Truth

- repo root is the shared plugin-contract layer.
- `py/`, `ts/`, and `rs/` are the language-specific implementation layers.

Never introduce two active paths for the same template surface.

## Rule

If a scaffold consumes a file, that file must live in exactly one of these places:

- repo root, if it is shared across languages
- one language directory, if it is runtime-, toolchain-, or language-specific

Do not duplicate shared files into `py/`, `ts/`, and `rs/`.

## Consumer Contract

`/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh` reads:

- shared assets from repo root
- language-specific assets from one of `py/`, `ts/`, or `rs/`

If you move or rename template files here, update the scaffold script and any combo instructions in `claude-homelab` in the same change.

## Hygiene

- no duplicate shared trees under language directories
- no placeholder-only paths unless the scaffold actually consumes them
- root docs should describe the repo, not impersonate a language template
- per-language `README.md` and `CLAUDE.md` should describe that language layer only


## Version Bumping

**Every feature branch push MUST bump the version in ALL version-bearing files.**

Bump type is determined by the commit message prefix:
- `feat!:` or `BREAKING CHANGE` → **major** (X+1.0.0)
- `feat` or `feat(...)` → **minor** (X.Y+1.0)
- Everything else (`fix`, `chore`, `refactor`, `test`, `docs`, etc.) → **patch** (X.Y.Z+1)

**Files to update (if they exist in this repo):**
- `Cargo.toml` — `version = "X.Y.Z"` in `[package]`
- `package.json` — `"version": "X.Y.Z"`
- `pyproject.toml` — `version = "X.Y.Z"` in `[project]`
- `.claude-plugin/plugin.json` — `"version": "X.Y.Z"`
- `.codex-plugin/plugin.json` — `"version": "X.Y.Z"`
- `gemini-extension.json` — `"version": "X.Y.Z"`
- `README.md` — version badge or header
- `CHANGELOG.md` — new entry under the bumped version

All files MUST have the same version. Never bump only one file.
CHANGELOG.md must have an entry for every version bump.