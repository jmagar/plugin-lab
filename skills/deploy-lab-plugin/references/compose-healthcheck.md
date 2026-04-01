# Docker Compose Healthcheck Reference

Canonical `docker-compose.yaml` service stanza with `healthcheck`, `env_file`, `ports`, and `volumes`. Annotated with comments. Includes the full deploy and rollback workflow.

---

## Canonical Service Stanza

```yaml
services:
  my-plugin:
    # Pin to a versioned tag — never use :latest.
    # A pinned tag makes rollbacks trivial: change the tag, run `docker compose up -d`.
    image: ghcr.io/owner/my-plugin:1.2.0

    # Load all runtime config from the .env file on the host.
    # The .env file is never committed to git — it lives only on the host.
    # Do NOT use the inline `environment:` key for secrets; that embeds them in the Compose file.
    env_file:
      - .env

    ports:
      # Publish only the single port the plugin needs.
      # Format: "host_port:container_port"
      # Change 8080 to match your plugin's HTTP port.
      - "8080:8080"

    volumes:
      # Use a named volume for persistent data (SQLite, uploaded files, cache).
      # Named volumes survive `docker compose down` — bind-mounts to host paths do not.
      # Declare the volume name in the top-level `volumes:` block below.
      - my-plugin-data:/app/data

    healthcheck:
      # Probe the /health endpoint inside the container.
      # Use the container-side port (8080), not the host-mapped port.
      test: ["CMD", "curl", "-sf", "http://localhost:8080/health"]

      # How often to run the probe.
      # Default 30s is appropriate for most plugins.
      # Reduce to 10s for plugins where fast failure detection matters.
      interval: 30s

      # How long to wait for the probe before marking it as failed.
      # Keep this shorter than interval. 10s is the canonical default.
      timeout: 10s

      # How many consecutive failures before the container is marked unhealthy.
      # 3 is the canonical default. Increase to 5 for slow-starting services.
      retries: 3

      # Grace period after container start before health checks begin.
      # Set this to slightly longer than your plugin's typical startup time.
      # A plugin that starts in ~5s should use start_period: 10s.
      start_period: 10s

    restart: unless-stopped

# Declare named volumes used by services.
# Named volumes persist across `docker compose down`.
# Use `docker compose down -v` only when you intentionally want to delete data.
volumes:
  my-plugin-data:
```

---

## When to Adjust the Defaults

| Scenario | Adjustment |
|----------|-----------|
| Plugin starts slowly (e.g., loads a large model) | Increase `start_period` to `60s` or more |
| Plugin must recover fast (e.g., network proxy) | Reduce `interval` to `10s`, `retries` to `2` |
| Probe command itself is slow (e.g., database query) | Increase `timeout` to `30s` |
| Stateless plugin with no persistent data | Omit the `volumes:` block entirely |
| Plugin reads from a socket, not HTTP | Replace `curl` with `nc -z localhost <port>` |

---

## Full Deploy Workflow

### First deploy

```bash
# 1. Build the image (CI does this on a tagged release; run locally for testing)
just build

# 2. Start the service in the background
just up
# equivalent to: docker compose up -d

# 3. Confirm the container is running and healthy
docker compose ps
# Look for: STATUS = Up X seconds (healthy)

# 4. Check logs for startup errors
docker compose logs my-plugin --tail 50

# 5. Probe the health endpoint from the host
curl -sf http://localhost:8080/health && echo "healthy"
```

### Updating to a new release

```bash
# 1. Pull the new image (or let CI push it)
docker compose pull

# 2. Restart the service with the new image — zero manual steps
docker compose up -d

# 3. Confirm the new version is running
docker compose ps
docker compose logs my-plugin --tail 20
```

### Rolling back to a prior release

The correct rollback pattern is to pin the prior image tag in `docker-compose.yaml` and redeploy. There is no need to scale the service to zero first.

**Step 1:** Edit `docker-compose.yaml` to pin the prior tag:

```yaml
# Before (current broken release):
image: ghcr.io/owner/my-plugin:1.3.0

# After (rolled back to last known good):
image: ghcr.io/owner/my-plugin:1.2.0
```

**Step 2:** Apply the change:

```bash
docker compose up -d
```

Docker Compose detects that the running container's image differs from the declared image, stops the running container, and starts a new one with the pinned tag. The named volume (`my-plugin-data`) is preserved.

**Step 3:** Confirm the rollback is healthy:

```bash
docker compose ps
docker compose logs my-plugin --tail 50
curl -sf http://localhost:8080/health && echo "healthy"
```

**Step 4:** After the rollback is confirmed stable, either:

- Fix the bug and cut a new release (e.g., `1.3.1`), then update the tag back to the new release
- Keep the pinned tag in `docker-compose.yaml` until a fix is ready — this is intentional and safe

---

## Complete Example with No Persistent Data

For a stateless plugin (no SQLite, no uploaded files):

```yaml
services:
  my-plugin:
    image: ghcr.io/owner/my-plugin:1.2.0
    env_file:
      - .env
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped
```

No `volumes:` block needed. `docker compose down` is safe — no data is lost.

---

## Checking Logs During Troubleshooting

```bash
# Tail logs in real time
docker compose logs my-plugin --follow

# Last 100 lines
docker compose logs my-plugin --tail 100

# Logs since a specific time
docker compose logs my-plugin --since 10m

# Logs from all services at once
docker compose logs --follow
```

---

## Notes

- **`env_file` vs `environment:`** — always use `env_file`. The `environment:` key embeds values in the Compose file, which gets committed to git. The `.env` file stays on the host and is gitignored.
- **Named volumes vs bind-mounts** — named volumes are portable; bind-mounts to absolute host paths (e.g., `/home/user/data:/app/data`) break when moving to a different host. Use named volumes for plugin data.
- **`restart: unless-stopped`** — the plugin restarts automatically after a crash or host reboot, but stays stopped if you explicitly run `docker compose stop`.
- **`curl` in healthcheck** — `curl` must be present in the runtime image. If your runtime image does not include it (e.g., `scratch` or a minimal Rust image), use `wget -qO- http://localhost:8080/health` or install `curl` in the runtime stage.
