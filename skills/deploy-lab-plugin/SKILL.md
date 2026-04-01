---
name: deploy-lab-plugin
description: Containerize and deploy a lab plugin using Docker and Docker Compose. Use when the user wants to create or update a Dockerfile, docker-compose.yaml, entrypoint.sh, or health endpoint; audit an existing container config for drift; or plan a deploy strategy for a plugin. Trigger phrases include "Dockerize my Rust plugin", "containerize my Python MCP server", "set up Compose for my TypeScript plugin".
---

# Deploy Lab Plugin

Produce canonical Docker and Docker Compose configuration for a lab plugin.

## Default Assumptions

When the user omits details, apply these defaults without asking:

- **Port**: `8080` (override only if the user specifies a different port)
- **Env file**: `env_file: .env` in the Compose service stanza
- **Healthcheck defaults**: `interval: 30s`, `timeout: 10s`, `retries: 3`, `start_period: 10s`
- **No external volumes** unless the user explicitly mentions persistent data or a data directory
- **No inter-service networking** unless the user mentions other Compose services
- **Language selection**: infer from trigger phrase or project files (`Cargo.toml` → Rust, `pyproject.toml`/`setup.py` → Python, `package.json` → TypeScript/Node)

If a required input cannot be inferred (e.g., the plugin name or the list of required env vars), ask before generating files.

## Canonical Container Shape

A conforming plugin container:

- uses a **multi-stage Dockerfile** (builder stage + minimal runtime stage)
- runs as a **non-root user** in the runtime stage
- exposes a `/health` endpoint on the plugin's HTTP port returning HTTP 200
- reads all config from **environment variables** — no baked-in secrets
- has an **`entrypoint.sh`** that validates every variable in `.env.example` before starting the server
- is declared in **`docker-compose.yaml`** with `env_file`, named volume mounts, and a `healthcheck` directive
- has a **`.dockerignore`** that excludes `.env`, dev artifacts, and test data

## Language Layer Directories

Use the correct canonical template base for the target language:

- **Python** — `~/workspace/plugin-templates/py/`
- **Rust** — `~/workspace/plugin-templates/rs/`
- **TypeScript / Node** — `~/workspace/plugin-templates/ts/`

Specialize the template with the plugin's package name, binary or module entrypoint, correct port, required env var names, and any extra system packages needed at runtime. Do not invent new layer ordering or USER patterns outside what the template establishes.

## Gather Inputs First

Before writing container files, confirm or infer:

- plugin name and language (Python, Rust, TypeScript)
- HTTP port the server listens on (default: 8080)
- required environment variables from `.env.example`
- any volume mounts (data directories, socket paths)
- whether the plugin needs network access to other Compose services

## Reviewing Existing Container Config

Check for these common drift patterns:

- single-stage Dockerfile (no builder/runtime split)
- `USER root` in the runtime stage
- baked-in secrets or hardcoded URLs in the image
- missing `healthcheck` in Compose
- `/health` endpoint absent or not returning HTTP 200
- `.env` referenced via inline `environment:` block instead of `env_file:`
- no `.dockerignore` or patterns that are too broad (e.g., `*` ignoring everything)
- `entrypoint.sh` that does not validate all vars from `.env.example`

Produce a findings list with file references before making any changes.

## Updating Container Config

When modifying an existing config:

1. Identify the specific gap from the findings list
2. Apply the targeted change — avoid rewriting stable layers unnecessarily
3. Verify `entrypoint.sh` still validates all env vars after any `.env.example` additions
4. Confirm the Compose healthcheck interval/timeout matches the server's actual startup time
5. Re-test locally with `just build && just up` before considering complete

## Deploy Strategy

Standard homelab deploy workflow:

1. CI builds and pushes the image on a tagged release (see pipeline-lab-plugin)
2. The Compose file is checked into the plugin repo
3. Secrets are provided via `.env` on the host — never committed to git
4. Deploy command on the host:
   ```bash
   docker compose pull
   docker compose up -d
   ```

### Rollback

To roll back to a prior release, pin the previous image tag in `docker-compose.yaml` and redeploy:

```yaml
# docker-compose.yaml — pin to prior tag to roll back
services:
  my-plugin:
    image: ghcr.io/owner/my-plugin:1.2.3   # was: 1.3.0
```

Then apply:

```bash
docker compose up -d
```

The running container is replaced with the pinned version. No scale-to-zero step is needed. After confirming the rollback is stable, either fix forward and cut a new release, or update the pinned tag to the correct prior version permanently.

To confirm the rollback succeeded:

```bash
docker compose ps
docker compose logs my-plugin --tail 50
curl -sf http://localhost:8080/health
```

## Required Output

At minimum, produce:

- [ ] `Dockerfile` — multi-stage, non-root runtime stage
- [ ] `entrypoint.sh` — validates all vars from `.env.example`, then execs the server
- [ ] `docker-compose.yaml` — service with `env_file`, `healthcheck`, correct port
- [ ] `.dockerignore` — excludes `.env`, dev artifacts, test data
- [ ] Confirmation or stub of `/health` endpoint in server code
- [ ] Summary of assumptions made (port, volumes, env vars, language template used)

## Verification

After generating or updating container files:

```bash
# Validate Compose config parses cleanly
docker compose config --quiet

# Check shell syntax on entrypoint
bash -n entrypoint.sh

# Build the image locally
just build

# Start and confirm health
just up
curl -sf http://localhost:8080/health && echo "healthy"

# Check logs for startup errors
docker compose logs my-plugin --tail 50
```

## Related Skills

- **scaffold-lab-plugin** — creates the initial plugin structure that this skill containerizes
- **pipeline-lab-plugin** — CI builds and pushes the image that this skill's Compose file references
- **align-lab-plugin** — use to audit and fix an existing Docker config for canonical drift
