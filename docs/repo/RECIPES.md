# Build and Task Automation -- plugin-lab

## No Justfile

plugin-lab does not have a Justfile. Unlike the MCP server plugins it scaffolds, plugin-lab is a development toolkit with no build step, no Docker image, and no server process.

Task automation is handled through direct script invocation from the `scripts/` directory.

## Common Operations

### Scaffold a new plugin

```bash
bash scripts/scaffold-plugin.sh <service-name> <language> [--port PORT]
```

Examples:
```bash
bash scripts/scaffold-plugin.sh gotify python --port 9158
bash scripts/scaffold-plugin.sh synapse typescript --port 3000
bash scripts/scaffold-plugin.sh syslog rust --port 3100
```

### Validate version sync

```bash
bash scripts/check-version-sync.sh [project-dir]
```

### Validate marketplace manifest

```bash
bash scripts/validate-marketplace.sh [repo-root]
```

### Refresh mirrored docs

```bash
bash scripts/update-doc-mirrors.sh [root-dir]
```

### Check ignore files

```bash
# Append missing patterns
bash scripts/ensure-ignore-files.sh [project-dir]

# Check-only mode (CI)
bash scripts/ensure-ignore-files.sh --check [project-dir]
```

### Docker security audit

```bash
bash scripts/check-docker-security.sh [project-dir]
bash scripts/check-no-baked-env.sh [project-dir]
```

### Dependency freshness

```bash
bash scripts/check-outdated-deps.sh [project-dir]
```

## Scaffolded Plugin Justfile

Plugins scaffolded by plugin-lab include a Justfile with these canonical targets:

| Target | Purpose |
| --- | --- |
| `dev` | Start dev server |
| `test` | Run unit tests |
| `test-live` | Run live integration tests |
| `lint` | Run linter |
| `type-check` | Run type checker |
| `build` | Build Docker image |
| `docker-build` | Build Docker image |
| `docker-up` | Start containers |
| `push` | Push Docker image |
| `clean` | Clean build artifacts |

These targets mirror the CI workflow steps. See [pipeline-lab-plugin](../plugin/SKILLS.md#pipeline-lab-plugin) for details on the CI/Justfile sync requirement.
