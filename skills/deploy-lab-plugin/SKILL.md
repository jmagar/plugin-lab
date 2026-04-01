---
name: deploy-lab-plugin
description: Containerize and deploy a lab plugin using Docker and Docker Compose. Use when the user wants to create or update a Dockerfile, docker-compose.yaml, entrypoint.sh, or health endpoint; audit an existing container config for drift; or plan a deploy strategy for a plugin.
---

# Deploy Lab Plugin

Produce canonical Docker and Docker Compose configuration for a lab plugin.

## Canonical Container Shape

A conforming plugin container:

- uses a **multi-stage Dockerfile** (builder + runtime stage)
- runs as a **non-root user**
- exposes a `/health` endpoint on the plugin's HTTP port
- reads all config from **environment variables** (no baked-in secrets)
- has a **`entrypoint.sh`** that validates required env vars before starting
- is declared in **`docker-compose.yaml`** with named volume mounts and env_file reference
- is covered by a **`healthcheck`** directive in Compose

## Gather Inputs First

Before writing container files, collect:

- plugin name and language (`python`, `rust`, `typescript`)
- HTTP port the server listens on
- required environment variables (from `.env.example`)
- any volume mounts (data dirs, socket paths)
- whether the plugin needs network access to other Compose services
- existing Dockerfile if reviewing or updating

If inputs are missing, ask before generating files.

## Prefer Canonical Templates

Use `~/workspace/plugin-templates/<lang>/` Dockerfile and entrypoint as the base. Specialize with:

- the plugin's package name and binary/module entrypoint
- the correct port
- the required env var names from `.env.example`
- any extra system packages needed at runtime

Avoid inventing new layer ordering or USER patterns.

## Implementing the Container Config

Produce in order:

1. **Dockerfile** — multi-stage build for the target language
2. **entrypoint.sh** — env var validation, then exec the server
3. **docker-compose.yaml** — service definition with healthcheck, env_file, ports, volumes
4. **`/health` endpoint** — confirm it exists in the server code; stub it if missing
5. **.dockerignore** — exclude dev artifacts, `.env`, test data

## Reviewing Existing Container Config

Check for:

- single-stage Dockerfile (no builder/runtime split)
- root user in runtime stage
- baked-in secrets or hardcoded URLs
- missing healthcheck in Compose
- `/health` endpoint absent or not returning HTTP 200
- `.env` not referenced via `env_file` (copy-pasted inline instead)
- no `.dockerignore` or overly broad ignore patterns

Produce a findings list with file references before making changes.

## Updating Container Config

When modifying:

1. Identify the specific gap
2. Apply the targeted change — avoid rewriting stable layers unnecessarily
3. Verify the entrypoint still validates all env vars after any `.env.example` additions
4. Confirm the Compose healthcheck interval/timeout matches the server startup time
5. Re-test locally with `just build && just up` before considering complete

## Deploy Strategy

For a standard homelab deploy:

- image built and pushed by CI on tag
- Compose file checked into the plugin repo
- secrets provided via `.env` on the host (never committed)
- `docker compose pull && docker compose up -d` as the deploy command
- rollback via `docker compose up -d --scale <service>=0` then redeploy prior tag

## Required Output

At minimum:

- `Dockerfile`
- `entrypoint.sh`
- `docker-compose.yaml`
- `.dockerignore`
- confirmation or stub of `/health` endpoint
- any assumptions about ports, volumes, or required env vars
