# Target path relative to plugin root: Dockerfile
# syntax=docker/dockerfile:1

FROM rust:1.86-slim-bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml ./
RUN mkdir -p my_plugin_mcp && echo "fn main() {}" > my_plugin_mcp/main.rs && cargo build --release && rm -rf my_plugin_mcp
COPY my_plugin_mcp/ my_plugin_mcp/
RUN touch my_plugin_mcp/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/my-plugin-mcp /usr/local/bin/my-plugin-mcp
COPY . .
RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home --shell /sbin/nologin app \
  && mkdir -p /data /app/logs && chown -R app:app /data /app
USER 1000:1000
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:9000/health || exit 1
ENTRYPOINT ["./entrypoint.sh"]
