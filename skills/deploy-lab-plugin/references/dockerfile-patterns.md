# Dockerfile Patterns

Multi-stage Dockerfile examples for all three supported language runtimes. Each example is annotated to explain why each layer is structured the way it is. Use these as the canonical baseline — specialize with the plugin's package name, port, and extra system packages.

---

## Python

```dockerfile
# ── Builder stage ────────────────────────────────────────────────────────────
# Use the full Python image so pip and build tools are available.
# Pin to a minor version tag (not :latest) for reproducible builds.
FROM python:3.12-slim AS builder

WORKDIR /build

# Copy dependency manifest first — Docker caches this layer separately.
# If only application code changes, this layer is not rebuilt.
COPY pyproject.toml ./
# Copy lock file if present (pip-tools, uv, or poetry.lock)
COPY requirements*.txt ./

# Install dependencies into a prefix directory so they can be copied cleanly
# into the runtime stage without dragging along pip or setuptools.
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# Copy application source after dependencies — preserves the dependency cache.
COPY src/ ./src/

# ── Runtime stage ─────────────────────────────────────────────────────────────
# Use the same minor version slim image — minimal OS surface.
FROM python:3.12-slim AS runtime

# Create a non-root user with a fixed UID.
# Fixed UID matters when volume-mounted files need consistent ownership.
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy the installed packages from the builder stage.
COPY --from=builder /install /usr/local

# Copy application source.
COPY --from=builder /build/src ./src

# Copy the entrypoint script and make it executable.
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Drop privileges before the process starts.
USER appuser

# Expose the HTTP port. Default is 8080; change to match your plugin.
EXPOSE 8080

# Use the entrypoint script — it validates env vars then execs the server.
ENTRYPOINT ["./entrypoint.sh"]
CMD ["python", "-m", "src.server"]
```

**Key decisions:**
- `--prefix=/install` lets the runtime stage copy only the package tree, not pip itself
- `COPY pyproject.toml` before `COPY src/` means dependency installs are cached separately from code changes
- Fixed UID `1001` ensures volume ownership is stable across container restarts

---

## Rust

```dockerfile
# ── Builder stage ────────────────────────────────────────────────────────────
# Use the official Rust image for the build. It includes cargo and the full toolchain.
# Pin to a minor version; the build toolchain version affects the compiled binary.
FROM rust:1.78-slim AS builder

WORKDIR /build

# Copy manifests first to cache the dependency download and compilation layer.
# This is Rust's equivalent of installing requirements before copying source.
COPY Cargo.toml Cargo.lock ./

# Create a stub src/main.rs so cargo can compile dependencies without the real source.
# This tricks Docker's layer cache — dependency compilation is cached until Cargo.lock changes.
RUN mkdir -p src && echo 'fn main() {}' > src/main.rs && \
    cargo build --release && \
    rm -rf src target/release/.fingerprint/my-plugin-*

# Now copy the real source and do the final compile.
COPY src/ ./src/
RUN cargo build --release

# ── Runtime stage ─────────────────────────────────────────────────────────────
# Debian bookworm-slim: smaller than the Rust image, still has glibc for dynamically linked binaries.
# Use scratch only if you link fully statically (musl target).
FROM debian:bookworm-slim AS runtime

# Install only what the binary needs at runtime (TLS certs for HTTPS client calls).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy only the compiled binary — not the entire build directory.
COPY --from=builder /build/target/release/my-plugin ./my-plugin

COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["./my-plugin"]
```

**Key decisions:**
- The stub `src/main.rs` trick caches Rust's slow dependency compilation layer
- `debian:bookworm-slim` provides glibc for dynamically linked binaries; switch to `scratch` if using the `x86_64-unknown-linux-musl` target
- `ca-certificates` is almost always needed if the plugin makes outbound HTTPS calls

---

## TypeScript / Node

```dockerfile
# ── Builder stage ────────────────────────────────────────────────────────────
# Use the LTS Node image. Alpine is smaller but can cause issues with
# native addon compilation — prefer slim (Debian-based) for reliability.
FROM node:22-slim AS builder

WORKDIR /build

# Copy package manifests before source code.
# node_modules is cached as long as package.json and the lock file don't change.
COPY package.json package-lock.json ./

# Install all dependencies including devDependencies needed for the build.
RUN npm ci --ignore-scripts

# Copy source and build.
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:22-slim AS runtime

RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy only the compiled output and production dependencies.
# npm ci --omit=dev installs only what the runtime needs — no TypeScript compiler, etc.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

COPY --from=builder /build/dist ./dist

COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "dist/server.js"]
```

**Key decisions:**
- Two separate `npm ci` runs: one with devDependencies (builder), one without (runtime) — this ensures the production image never ships TypeScript, ts-node, or test frameworks
- `--ignore-scripts` on `npm ci` prevents postinstall scripts from running as root during the build, which is a common security risk
- `node:22-slim` (Debian-based) is preferred over `node:22-alpine` to avoid musl/glibc issues with native addons

---

## Common Notes for All Languages

- **Never use `:latest`** for base images. It makes builds non-reproducible and can introduce silent breaking changes.
- **Always set a non-root USER** in the runtime stage. Running as root inside a container is a significant attack surface.
- **Copy manifests before source** in the builder stage to maximize Docker layer cache hits.
- **The entrypoint script is always copied into the image** — it must validate env vars at container startup before the server process starts.
- **`.dockerignore`** must exclude `.env`, `node_modules/`, `target/`, `__pycache__/`, and test fixtures to prevent sensitive or unnecessary files from entering the build context.
