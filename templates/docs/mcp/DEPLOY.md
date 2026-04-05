# Deployment Guide

Deployment patterns for `my-plugin-mcp`. Choose the method that fits your environment.

## Local Development

<!-- scaffold:specialize -->

**Python:**

```bash
uv sync && uv run my-plugin-mcp-server
```

**TypeScript:**

```bash
pnpm install && pnpm dev
```

**Rust:**

```bash
cargo run --release
```

**Shortcut:**

```bash
just dev
```

The server starts on `http://localhost:8000` by default. Override with `MY_PLUGIN_PORT`.

## Package Manager

| Language | Install | Run |
|----------|---------|-----|
| Python | `pip install my-plugin-mcp` | `uvx my-plugin-mcp` |
| TypeScript | `npm install -g my-plugin-mcp` | `npx my-plugin-mcp` |
| Rust | `cargo install my-plugin-mcp` | `my-plugin-mcp` |

## Docker

### Build

Multi-stage Dockerfile: builder installs dependencies, runtime copies only the venv/binary.

```bash
docker build -t my-plugin-mcp .
```

### Compose

```yaml
services:
  my-plugin-mcp:
    build: .
    container_name: my-plugin-mcp
    restart: unless-stopped
    ports:
      - "${MY_PLUGIN_PORT:-8000}:8000"
    env_file: .env
    volumes:
      - ./logs:/app/logs
    networks:
      - mcp-net
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  mcp-net:
    external: true
```

```bash
docker compose up -d
```

### Container Conventions

| Concern | Pattern |
|---------|---------|
| Base image | `python:3.12-slim` / `node:22-slim` / `rust:1-slim` (builder) + distroless or slim runtime |
| User | Non-root, UID 1000 (`mcpuser`) |
| Health check | `wget -qO- http://localhost:8000/health` every 30s |
| Logs | Volume mount `./logs:/app/logs` |
| Network | External `mcp-net` |
| Signals | Entrypoint traps SIGTERM/SIGINT for graceful shutdown |

### Entrypoint Pattern

```bash
#!/bin/bash
set -euo pipefail

# Validate required env vars
: "${MY_PLUGIN_URL:?MY_PLUGIN_URL is required}"
: "${MY_PLUGIN_API_KEY:?MY_PLUGIN_API_KEY is required}"

# Defaults
export MY_PLUGIN_PORT="${MY_PLUGIN_PORT:-8000}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Trap signals for graceful shutdown
trap 'kill -TERM $PID' TERM INT
exec "$@" &
PID=$!
wait $PID
```

## Port Assignment

<!-- scaffold:specialize -->

| Service | Default Port | Env Var |
|---------|-------------|---------|
| my-plugin-mcp | 8000 | `MY_PLUGIN_PORT` |

## Related Docs

- [ENV.md](ENV.md) — environment variables
- [LOGS.md](LOGS.md) — logging configuration
- [CONNECT.md](CONNECT.md) — client connection methods
