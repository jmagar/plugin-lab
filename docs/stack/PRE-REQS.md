# Prerequisites -- plugin-lab

Required tools and versions for working with plugin-lab and developing scaffolded plugins.

## For plugin-lab Development

These are needed to work on plugin-lab itself (editing templates, running scripts, refreshing docs):

| Tool | Minimum Version | Purpose |
| --- | --- | --- |
| Bash | 4.0+ | All scripts use associative arrays and other Bash 4 features |
| Git | 2.x | Version control |
| jq | 1.6+ | JSON validation in lint and marketplace scripts |
| Python 3 | 3.10+ | Version extraction in `check-version-sync.sh` |
| curl | any | Marketplace validation, doc mirror fetching |
| wget | any | Doc mirror fetching |
| Claude Code | latest | Plugin discovery and command execution |

### Verification

```bash
bash --version | head -1        # GNU bash, version 4.x+
git --version                   # git version 2.x
jq --version                    # jq-1.6+
python3 --version               # Python 3.10+
curl --version | head -1        # curl 7.x+
```

## For Python Plugin Development

Additional requirements when working with the Python template (`templates/py/`):

| Tool | Minimum Version | Purpose |
| --- | --- | --- |
| Python | 3.11+ | Runtime for FastMCP server |
| uv | latest | Package management |
| ruff | latest | Linting |
| mypy or ty | latest | Type checking |
| pytest | latest | Testing |
| pre-commit | latest | Local dev quality gate |
| Docker | 24+ | Container builds |
| Docker Compose | v2 | Container orchestration |

### Python Setup

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install pre-commit
uv tool install pre-commit

# Verify
uv --version
python3 --version
ruff --version
```

## For TypeScript Plugin Development

Additional requirements when working with the TypeScript template (`templates/ts/`):

| Tool | Minimum Version | Purpose |
| --- | --- | --- |
| Node.js | 20+ | Runtime for MCP SDK server |
| npm or pnpm | latest | Package management |
| TypeScript | 5+ | Type system |
| biome or eslint | latest | Linting |
| vitest or jest | latest | Testing |
| lefthook | latest | Local dev quality gate |
| Docker | 24+ | Container builds |
| Docker Compose | v2 | Container orchestration |

### TypeScript Setup

```bash
# Install Node.js (via nvm or system package)
nvm install 20

# Install lefthook
npm install -g @evilmartians/lefthook

# Verify
node --version    # v20.x+
npm --version
tsc --version     # Version 5.x
```

## For Rust Plugin Development

Additional requirements when working with the Rust template (`templates/rs/`):

| Tool | Minimum Version | Purpose |
| --- | --- | --- |
| Rust | stable | Compiler toolchain |
| cargo | (bundled) | Build and package management |
| clippy | (bundled) | Linting |
| lefthook | latest | Local dev quality gate |
| Docker | 24+ | Container builds |
| Docker Compose | v2 | Container orchestration |

### Rust Setup

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install lefthook
cargo install lefthook

# Verify
rustc --version
cargo --version
cargo clippy --version
```

## Optional Tools

| Tool | Purpose |
| --- | --- |
| yamllint | YAML validation for CI workflows |
| shellcheck | Static analysis for shell scripts |
| mcporter | MCP contract testing harness |
| just | Task runner (for scaffolded plugins, not plugin-lab itself) |

### Install Optional Tools

```bash
# yamllint
pip install yamllint

# shellcheck
apt install shellcheck  # or brew install shellcheck

# just
cargo install just  # or brew install just
```
