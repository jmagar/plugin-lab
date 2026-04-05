# Prerequisites — my-plugin

Required tools and versions before developing or deploying.

## All languages

These tools are required regardless of the plugin language:

| Tool | Version | Install | Purpose |
| --- | --- | --- | --- |
| Git | 2.40+ | System package manager | Version control |
| Docker | 24+ | [docs.docker.com](https://docs.docker.com/get-docker/) | Container builds and deployment |
| Docker Compose | v2+ | Bundled with Docker Desktop | Service orchestration |
| just | latest | `cargo install just` | Task runner |
| openssl | any | System package manager | Token generation |
| curl | any | System package manager | HTTP testing |
| jq | 1.6+ | System package manager | JSON parsing |

### Verify

```bash
git --version        # git version 2.40+
docker --version     # Docker version 24+
docker compose version  # Docker Compose version v2+
just --version       # just X.Y.Z
openssl version      # OpenSSL X.Y.Z
curl --version       # curl X.Y.Z
jq --version         # jq-1.6+
```

## Python

<!-- scaffold:specialize — remove if not Python -->

| Tool | Version | Install | Purpose |
| --- | --- | --- | --- |
| Python | 3.10+ (3.12 recommended) | System or pyenv | Runtime |
| uv | latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Package manager and runner |

### Verify

```bash
python3 --version    # Python 3.12.x
uv --version         # uv X.Y.Z
```

### Quick start

```bash
git clone https://github.com/jmagar/my-plugin.git
cd my-plugin
just setup           # Copy .env.example -> .env
just install         # uv sync --dev
just dev             # Start dev server
```

## TypeScript

<!-- scaffold:specialize — remove if not TypeScript -->

| Tool | Version | Install | Purpose |
| --- | --- | --- | --- |
| Node.js | 22+ | [nodejs.org](https://nodejs.org/) or nvm | Runtime |
| pnpm | 9+ | `corepack enable` | Package manager |

### Verify

```bash
node --version       # v22.x.x
pnpm --version       # 9.x.x
```

### Quick start

```bash
git clone https://github.com/jmagar/my-plugin.git
cd my-plugin
just setup           # Copy .env.example -> .env
just install         # pnpm install
just dev             # Start dev server
```

## Rust

<!-- scaffold:specialize — remove if not Rust -->

| Tool | Version | Install | Purpose |
| --- | --- | --- | --- |
| Rust | 1.86+ | [rustup.rs](https://rustup.rs/) | Compiler and toolchain |
| cargo | 1.86+ | Bundled with Rust | Build system and package manager |
| sccache | latest (optional) | `cargo install sccache` | Compilation cache |
| mold | latest (optional) | System package manager | Fast linker |

### Verify

```bash
rustc --version      # rustc 1.86.x
cargo --version      # cargo 1.86.x
```

### Quick start

```bash
git clone https://github.com/jmagar/my-plugin.git
cd my-plugin
just setup           # Copy .env.example -> .env
just install         # cargo build
just dev             # Start dev server
```

## Optional tools

| Tool | Purpose | Install |
| --- | --- | --- |
| `gh` | GitHub CLI for PRs and issues | [cli.github.com](https://cli.github.com/) |
| `docker scout` | Container vulnerability scanning | Bundled with Docker Desktop |
| `act` | Run GitHub Actions locally | `brew install act` or `go install` |

## Cross-references

- [SETUP](../SETUP.md) — step-by-step setup guide
- [TECH](TECH.md) — technology stack details
- [RECIPES](../repo/RECIPES.md) — Justfile recipes for development
