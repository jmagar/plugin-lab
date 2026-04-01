# Alignment Targets Reference

Detailed guidance for each of the ten canonical alignment surfaces. For each surface: what correct alignment looks like, what drift looks like, and how to verify.

---

## 1. Manifests and Version Sync

### Correct Alignment

`plugin.json` (or the equivalent language manifest) carries a version string that matches the most recent Git tag exactly. The `name` field matches the repository name and the directory name under `skills/`. The `mcp_version` field references the current MCP protocol revision. If a `CHANGELOG.md` exists, its most recent entry version matches the manifest version.

### Drift

- `plugin.json` version frozen at `0.1.0` while `package.json` or `Cargo.toml` is at `1.3.0`
- `mcp_version` referencing a superseded protocol revision (e.g., `0.8` when `1.0` is current)
- `name` field in `plugin.json` does not match the directory name under `skills/`
- Version in `CHANGELOG.md` header does not match the version in the manifest

### Verification

```bash
# Check all version fields in one pass
grep -rn '"version"' .claude-plugin/plugin.json package.json pyproject.toml Cargo.toml 2>/dev/null

# Check the most recent git tag
git describe --tags --abbrev=0

# Check CHANGELOG header version
head -5 CHANGELOG.md

# Validate plugin.json parses correctly
jq . .claude-plugin/plugin.json
```

---

## 2. `.env.example` and Runtime Contract

### Correct Alignment

Every environment variable read by the application at runtime appears in `.env.example` with a descriptive placeholder value (e.g., `MY_API_KEY=your_api_key_here`) and an inline comment explaining its purpose. The file is ordered by logical group (auth, network, feature flags). No variable in `.env.example` is silently unused by the application.

### Drift

- A variable present in `entrypoint.sh` or application source code is absent from `.env.example`
- A variable in `.env.example` is no longer read by any application code (stale entry)
- Placeholder values are empty strings (`MY_VAR=`) with no explanatory comment
- The file contains a real secret value committed to the repository

### Verification

```bash
# Extract vars validated in entrypoint
grep -oE '[A-Z_]{3,}' entrypoint.sh | sort -u

# Extract vars declared in .env.example
grep -oE '^[A-Z_]+' .env.example | sort -u

# Diff to find gaps
comm -23 \
  <(grep -oE '[A-Z_]{3,}' entrypoint.sh | sort -u) \
  <(grep -oE '^[A-Z_]+' .env.example | sort -u)
# Output should be empty — any line shown is a var checked but not documented

# Confirm no real secrets are present
grep -vE '^#|^[A-Z_]+=your_|^[A-Z_]+=<|^[A-Z_]+=$' .env.example
# Output should be empty
```

---

## 3. Dockerfile

### Correct Alignment

Two named stages: a builder stage that compiles or installs dependencies using the full SDK image, and a runtime stage that copies only the production artifact into a minimal base image. The runtime stage sets a non-root `USER` (e.g., `appuser` with a fixed UID). The base images are pinned to a minor version tag or digest, not `latest`. The `WORKDIR` is consistent between stages. No secrets, tokens, or `.env` content appear in any `ENV` or `ARG` instruction.

### Drift

- Single-stage build that ships compilers and dev dependencies into the final image
- `USER root` in the runtime stage (or no `USER` instruction at all, which defaults to root)
- Base images pinned to `latest` (breaks reproducibility)
- `ENV` instructions that embed real credential values
- `COPY . .` in the runtime stage that copies `.env` or test fixtures into the image

### Verification

```bash
# Check for multi-stage build (should see at least two FROM lines)
grep -c '^FROM' Dockerfile

# Check USER is set in runtime stage
grep -n 'USER' Dockerfile

# Check base images are not pinned to latest
grep '^FROM' Dockerfile | grep ':latest'
# Should return nothing

# Validate Dockerfile syntax (requires BuildKit)
docker buildx build --check . 2>&1 | head -30

# Check no ENV lines contain obvious secret patterns
grep -iE '^ENV.*(KEY|TOKEN|SECRET|PASSWORD)' Dockerfile
# Should return nothing
```

---

## 4. `docker-compose.yaml`

### Correct Alignment

The service stanza uses `env_file: .env` to inject all runtime variables. A `healthcheck` directive is present with the canonical defaults (`interval: 30s`, `timeout: 10s`, `retries: 3`, `start_period: 10s`). Only the required port is published. Persistent data uses named volumes (declared in the top-level `volumes:` block), not bind-mounts to absolute host paths. The service image reference uses a versioned tag matching the current release, not `latest`.

### Drift

- Inline `environment:` block that duplicates `.env.example` values (secrets visible in Compose file)
- `healthcheck` is absent or uses `disable: true`
- Port mapping exposes unnecessary ports (e.g., a debug port published in production)
- Bind-mount to an absolute host path (`/home/user/data:/data`) that breaks portability
- Image tag is `latest` or untagged, making rollbacks impossible

### Verification

```bash
# Validate the Compose file parses and is schema-valid
docker compose config --quiet

# Check healthcheck is present
grep -A5 'healthcheck' docker-compose.yaml

# Check env_file is used (not inline environment block with secrets)
grep 'env_file' docker-compose.yaml

# Check for absolute bind-mount paths
grep -E '^\s+-\s+/' docker-compose.yaml
# Ideally returns nothing (named volumes preferred)
```

---

## 5. `entrypoint.sh`

### Correct Alignment

The script begins with `#!/bin/bash` and `set -euo pipefail`. It iterates over every variable listed in `.env.example` and exits with a non-zero code and a descriptive error message if any variable is unset or empty. After validation it hands off to the server process using `exec "$@"` (or equivalent direct exec), ensuring the server replaces the shell as PID 1 and receives signals correctly.

### Drift

- Missing variable checks — the server starts with unset variables and fails cryptically at runtime
- Silent failure: a missing variable triggers a default value rather than an explicit error
- The script ends with the server process in a subshell (`./server &; wait`) rather than `exec`, breaking signal propagation
- A `sleep`-loop health-wait that masks startup errors and inflates container startup time

### Verification

```bash
# Check shell syntax
bash -n entrypoint.sh

# Check strict mode is set
head -3 entrypoint.sh

# Check exec is used for handoff
grep 'exec' entrypoint.sh

# Dry-run with a missing required var to confirm it exits non-zero
MY_REQUIRED_VAR="" bash entrypoint.sh 2>&1; echo "exit: $?"
# Should print an error and exit non-zero
```

---

## 6. `Justfile`

### Correct Alignment

The canonical targets exist: `build`, `up`, `down`, `logs`, `test`, `lint`, and `clean`. Each target delegates to the correct underlying tool with no hardcoded absolute paths. The `build` target calls `docker compose build`. The `up` target calls `docker compose up -d`. The `test` target calls the language-native test runner. Targets do not contain inline logic that belongs in a script.

### Drift

- Missing targets (e.g., no `test` or `lint` target)
- Targets call the v1 `docker-compose` binary instead of the v2 `docker compose` plugin
- Hardcoded project-specific paths that break when the Justfile is copied to another repo
- Inline multi-line shell logic inside a `just` recipe that should be a separate script

### Verification

```bash
# List all defined targets
just --list

# Check for v1 docker-compose usage (should return nothing)
grep 'docker-compose' Justfile

# Validate Justfile parses without error
just --dry-run build
just --dry-run test
```

---

## 7. Hook Scripts and Hook Config

### Correct Alignment

`hooks.json` (Claude hooks) or `lefthook.yml` (Rust/TypeScript) references only scripts that exist under `hooks/scripts/`. Every referenced script is executable (`chmod +x`). At minimum the hooks cover: env-file permission check (`fix-env-perms.sh`), no-baked-env check (`check-no-baked-env.sh`), and ignore-file sync (`ensure-ignore-files.sh`). Hook globs match the files that should trigger them.

### Drift

- Hook entries pointing to deleted scripts (hook config and scripts directory are out of sync)
- Hook scripts exist but are not executable — hook runs silently succeed without doing anything
- The no-baked-env check is absent, allowing `.env` to be committed to git
- Hook globs are too narrow (e.g., `*.ts` when the hook should fire on `*.json` too)

### Verification

```bash
# Check all scripts referenced in hook config actually exist
# For hooks.json:
jq -r '.hooks[].command' hooks/claude/hooks.json | while read cmd; do
  script=$(echo "$cmd" | awk '{print $1}')
  [[ -f "$script" ]] || echo "MISSING: $script"
done

# Check all hook scripts are executable
find hooks/scripts/ -name '*.sh' ! -executable -print
# Should return nothing

# Validate hooks.json parses
jq . hooks/claude/hooks.json

# Validate lefthook.yml if present
yamllint hooks/lefthook.yml 2>/dev/null || true
```

---

## 8. CI Workflows

### Correct Alignment

`.github/workflows/ci.yaml` runs lint, test, and build steps on every pull request and on push to the main branch. Action versions are pinned to a SHA or a tagged release (e.g., `actions/checkout@v4`, not `@main`). The workflow uses the canonical job structure from `~/workspace/plugin-templates/ts/` (or `py/` or `rs/`). Secrets are passed via `${{ secrets.* }}` — never hardcoded.

### Drift

- Workflow only triggers on push to main, skipping pull request validation
- Action versions pinned to `@main` or `@master` (non-reproducible)
- The build step is absent — tests pass but an uncompilable artifact ships
- Inline secret values in the `env:` block of a workflow step

### Verification

```bash
# Validate YAML syntax
yamllint .github/workflows/ci.yaml

# Check trigger events include pull_request
grep -A5 '^on:' .github/workflows/ci.yaml

# Check for unpinned @main/@master action refs
grep -rE 'uses:.*@(main|master)' .github/workflows/

# Check no hardcoded secrets (crude scan)
grep -iE '(api_key|token|password|secret)\s*=\s*[^$]' .github/workflows/ci.yaml
# Should return nothing
```

---

## 9. Live Tests

### Correct Alignment

`tests/test_live.sh` (or the language-equivalent test file) exercises at least one real MCP tool call against a running container, asserts a non-error HTTP 200 response from `/health`, and exits with a non-zero code if any assertion fails. The test is self-contained: it documents any required env vars and can be run with `just test` after `just up`.

### Drift

- Test file exists but contains only `echo "TODO"` or `exit 0` with no actual assertions
- Tests require undocumented manual setup steps (e.g., a specific database fixture) not described anywhere
- Tests always return exit 0 because errors are swallowed with `|| true`
- The `/health` endpoint is not tested at all

### Verification

```bash
# Check test file is not a stub
grep -c 'TODO\|exit 0' tests/test_live.sh

# Run the tests (requires running container)
just up
just test
echo "exit: $?"

# Confirm /health is tested
grep '/health' tests/test_live.sh
```

---

## 10. README, CLAUDE, Commands, Agents, and Skills

### Correct Alignment

`README.md` covers: what the plugin does, installation steps, configuration (referencing `.env.example` by name), and at least one usage example. `CLAUDE.md` lists the plugin's MCP tools with correct names and brief descriptions of their parameters. Slash commands in `commands/` have correct YAML frontmatter with accurate `allowed-tools` entries. Agent files in `agents/` reference tool names that actually exist in the plugin's tool registry.

### Drift

- `README.md` describes a different plugin's installation flow (copied and not updated)
- `CLAUDE.md` lists tool names that were renamed or removed in a prior refactor
- Command frontmatter has `allowed-tools` entries referencing tools from a different MCP server
- Agent files reference a tool that was split into two tools in a recent release

### Verification

```bash
# Check README has key sections
grep -iE '^## (installation|configuration|usage)' README.md

# Check CLAUDE.md exists and is non-empty
wc -l CLAUDE.md

# Validate command frontmatter YAML (requires yq or python)
for f in commands/*.md; do
  python3 -c "
import sys, re
content = open('$f').read()
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if m:
    import yaml; yaml.safe_load(m.group(1))
    print('OK: $f')
else:
    print('NO FRONTMATTER: $f')
"
done
```
