# Target path relative to plugin root: Dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml ./
RUN uv sync --no-dev
COPY . .

FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:$PATH"
RUN mkdir -p /app/logs && useradd -u 1000 -m appuser && chown -R 1000:1000 /app
USER 1000:1000
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:9000/health || exit 1
ENTRYPOINT ["./entrypoint.sh"]
