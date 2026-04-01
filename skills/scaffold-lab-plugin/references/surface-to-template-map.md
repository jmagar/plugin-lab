# Surface-to-Template Map

This table maps each of the 15 canonical plugin surfaces to the template file in `~/workspace/plugin-templates/` or the language-specific layer, what to specialize when copying, and whether the surface is shared across languages or language-specific.

---

## Surface Map

| # | Surface | Template Path | What to Specialize | Shared or Language-Specific |
|---|---------|--------------|-------------------|----------------------------|
| 1 | Package manifest | `py/pyproject.toml` · `rs/Cargo.toml` · `ts/package.json` | Package name, version (set to `0.1.0`), description, author, entry point, dependencies | Language-specific |
| 2 | `.claude-plugin/plugin.json` | `my-plugin/.claude-plugin/plugin.json` (see also `docs/` sub-files) | Plugin name, description, version, tool list, userConfig keys, transport URL, PORT env var | Shared |
| 3 | `.codex-plugin/plugin.json` | `my-plugin/.codex-plugin/plugin.json` | Plugin name, description, version, tool list, userConfig keys | Shared |
| 4 | `.mcp.json` | `my-plugin/.mcp.json` | Plugin name key, absolute path to `docker-compose.yaml`, service name (`mcp`) | Shared |
| 5 | `.app.json` | `my-plugin/.app.json` | App name, description, version, homepage URL, icon path | Shared |
| 6 | `README.md` | `py/README.md` · `rs/README.md` · `ts/README.md` | Plugin name, service name, env var table, tool reference section, install command | Language-specific (install/run instructions differ) |
| 7 | `CLAUDE.md` | `py/CLAUDE.md` · `rs/CLAUDE.md` · `ts/CLAUDE.md` | Plugin name, repo layout, local run command, test command, key conventions | Language-specific (toolchain commands differ) |
| 8 | `CHANGELOG.md` | `my-plugin/CHANGELOG.md` | Plugin name in header; leave `## [Unreleased]` and `## [0.1.0]` sections intact | Shared |
| 9 | `Dockerfile` | `py/Dockerfile` · `rs/Dockerfile` · `ts/Dockerfile` | Base image version, `WORKDIR`, `COPY` paths, exposed port (`PORT`), entry command | Language-specific |
| 10 | `docker-compose.yaml` | `py/docker-compose.yaml` · `rs/docker-compose.yaml` · `ts/docker-compose.yaml` | Service name, image name, port mapping (`PORT`), env var list, volume mounts, healthcheck URL | Language-specific (minor toolchain differences) |
| 11 | `entrypoint.sh` | `py/entrypoint.sh` · `rs/entrypoint.sh` · `ts/entrypoint.sh` | Process launch command, required env var names for startup validation | Language-specific |
| 12 | `Justfile` | `py/Justfile` · `rs/Justfile` · `ts/Justfile` | Plugin name in comments, test command, lint command, build command | Language-specific (toolchain commands differ) |
| 13 | `.env.example` | `my-plugin/.env.example` | All `YOUR_*` placeholder values, variable names matching `userConfig` keys in `.claude-plugin/plugin.json`, PORT value | Shared |
| 14 | Ignore files | `my-plugin/.gitignore/<lang>/.gitignore` · `my-plugin/.dockerignore/<lang>/.dockerignore` | Usually no specialization needed; add any plugin-specific build artifacts | Language-specific |
| 15 | CI workflow | `my-plugin/.github/workflows/ci.yaml/<lang>/ci.yaml` | Plugin name in comments, test command, lint command, Docker image name | Language-specific |

Plus: **live test scaffold**

| Surface | Template Path | What to Specialize | Notes |
|---------|--------------|-------------------|-------|
| Live test | `py/tests/` · `rs/tests/` · `ts/tests/` | Service URL env var name, at least one real API call, skip guard env var | Must include skip guard; see canonical-spec.md for correct skip guard patterns |

---

## Specialization Reference

### Names and Identifiers

When copying a template, replace all occurrences of the following placeholders with the real plugin values:

| Placeholder | Replace With |
|-------------|-------------|
| `my-plugin` | Kebab-case plugin name (e.g., `gotify-mcp`) |
| `my_plugin` | Snake-case plugin name (e.g., `gotify_mcp`) |
| `MyPlugin` | PascalCase plugin name (e.g., `GotifyMcp`) |
| `MY_PLUGIN` | Screaming-snake env var prefix (e.g., `GOTIFY`) |
| `my-service` | The external service being wrapped (e.g., `gotify`) |
| `8000` / `PORT` | The actual port number chosen for this plugin |
| `0.1.0` | Starting version (always `0.1.0` for new plugins) |

### Port Assignment

Assign a port that does not conflict with other running homelab services. Document the chosen port in `.env.example` as `PORT=<chosen>` and in `docker-compose.yaml` as `"${PORT}:<chosen>"`.

### userConfig Keys

Every env var in `.env.example` that is a credential or secret must appear in `.claude-plugin/plugin.json`'s `userConfig` with `"sensitive": true`. Non-credential config (PORT, feature flags) stays only in `.env.example`.

### Transport URL

The HTTP transport URL in `.claude-plugin/plugin.json` must use the PORT env var:

```json
"transport": {
  "type": "http",
  "url": "http://localhost:${PORT}/mcp"
}
```

---

## Language Layer Quick Reference

| Language | Layer Directory | Package Manager | Test Runner | Linter |
|----------|----------------|-----------------|-------------|--------|
| Python | `~/workspace/plugin-templates/py/` | `uv` / `pip` | `pytest` | `ruff` |
| Rust | `~/workspace/plugin-templates/rs/` | `cargo` | `cargo test` | `clippy` |
| TypeScript | `~/workspace/plugin-templates/ts/` | `pnpm` | `vitest` | `biome` / `eslint` |

Use the Justfile in the selected language layer to discover the exact commands for each target.
