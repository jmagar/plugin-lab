#!/usr/bin/env bash
set -euo pipefail

# ── scaffold-plugin.sh ──────────────────────────────────────────────────────
# Generates a new MCP server plugin from the canonical template defined in
# docs/plugin-setup-guide.md.
#
# Usage:
#   ./scripts/scaffold-plugin.sh <service-name> <language> [--port PORT]
#
# Example:
#   ./scripts/scaffold-plugin.sh gotify python --port 9158
#   ./scripts/scaffold-plugin.sh synapse typescript --port 3000
#   ./scripts/scaffold-plugin.sh syslog rust --port 3100
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_ROOT="${PLUGIN_TEMPLATES_ROOT:-$HOME/workspace/plugin-templates}"
TEMPLATE_SHARED_ROOT="${TEMPLATE_ROOT}"

render_template() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    echo "Error: template not found: $src" >&2
    exit 1
  fi

  sed \
    -e "s/my-service-mcp-data/${PLUGIN_NAME}-data/g" \
    -e "s/my-service_mcp/${DOCKER_NETWORK}/g" \
    -e "s/my-plugin-mcp/${PLUGIN_NAME}/g" \
    -e "s/my_plugin_mcp/${MODULE_NAME}/g" \
    -e "s/my_plugin/${TOOL_NAME}/g" \
    -e "s/my_service_mcp/${MODULE_NAME}/g" \
    -e "s/MY_SERVICE_MCP/${MCP_ENV_PREFIX}/g" \
    -e "s/MY_SERVICE/${ENV_PREFIX}/g" \
    -e "s/my_service/${TOOL_NAME}/g" \
    -e "s/your-service.example.com/your-${SERVICE}.example.com/g" \
    -e "s/my-service.example.com/${SERVICE}.example.com/g" \
    -e "s/your-service/your-${SERVICE}/g" \
    -e "s/my-service/${SERVICE}/g" \
    -e "s/My Plugin MCP/${DISPLAY_NAME} MCP/g" \
    -e "s/my-plugin/${SERVICE}/g" \
    -e "s/My Plugin/${DISPLAY_NAME}/g" \
    -e "s/MY_PLUGIN/${ENV_PREFIX}/g" \
    -e "s/9000/${PORT}/g" \
    -e "s/YYYY-MM-DD/${TODAY}/g" \
    -e "s/YYYY/${CURRENT_YEAR}/g" \
    -e "s/your-org/jmagar/g" \
    -e "s/Your team/Jacob Magar/g" \
    -e "s/team@example.com/jmagar@users.noreply.github.com/g" \
    "$src" > "$dest"
}

render_claude_plugin_manifest() {
  local src="${TEMPLATE_SHARED_ROOT}/.claude-plugin/plugin.json"
  local dest="${OUT_DIR}/.claude-plugin/plugin.json"

  jq \
    --arg plugin_name "$PLUGIN_NAME" \
    --arg display_name "$DISPLAY_NAME" \
    --arg service "$SERVICE" \
    --arg tool_name "$TOOL_NAME" \
    --arg port "$PORT" \
    --arg mcp_env_prefix "$MCP_ENV_PREFIX" \
    '
    .name = $plugin_name
    | .description = ("Manage " + $display_name + " via MCP tools with HTTP fallback.")
    | .version = "1.0.0"
    | .author_url = "https://github.com/jmagar"
    | .author = {
        name: "Jacob Magar",
        email: "jmagar@users.noreply.github.com"
      }
    | .homepage = ("https://github.com/jmagar/" + $plugin_name)
    | .repository = ("https://github.com/jmagar/" + $plugin_name)
    | .license = "MIT"
    | .userConfig = {
        ($tool_name + "_mcp_url"): {
          type: "string",
          title: ($display_name + " MCP Server URL"),
          description: ("Full MCP endpoint URL including /mcp path (e.g. https://" + $plugin_name + ".example.com/mcp)."),
          default: ("http://localhost:" + $port + "/mcp"),
          sensitive: false
        },
        ($tool_name + "_mcp_token"): {
          type: "string",
          title: "MCP Server Bearer Token",
          description: ("Bearer token for authenticating with the MCP server. Must match " + $mcp_env_prefix + "_TOKEN in .env. Generate with: openssl rand -hex 32"),
          sensitive: false
        },
        ($tool_name + "_url"): {
          type: "string",
          title: ($display_name + " URL"),
          description: ("Base URL of your " + $display_name + " instance, e.g. https://" + $service + ".example.com. No trailing slash."),
          sensitive: true
        },
        ($tool_name + "_api_key"): {
          type: "string",
          title: ($display_name + " API Key"),
          description: ("API key for " + $display_name + ". Found in Settings -> API."),
          sensitive: true
        }
      }
    ' \
    "$src" > "$dest"
}

render_codex_plugin_manifest() {
  local src="${TEMPLATE_SHARED_ROOT}/.codex-plugin/plugin.json"
  local dest="${OUT_DIR}/.codex-plugin/plugin.json"

  jq \
    --arg plugin_name "$PLUGIN_NAME" \
    --arg display_name "$DISPLAY_NAME" \
    --arg service "$SERVICE" \
    '
    .name = $plugin_name
    | .version = "1.0.0"
    | .description = ("Manage " + $display_name + " via MCP tools")
    | .author = {
        name: "Jacob Magar",
        email: "jmagar@users.noreply.github.com"
      }
    | .homepage = ("https://github.com/jmagar/" + $plugin_name)
    | .repository = ("https://github.com/jmagar/" + $plugin_name)
    | .license = "MIT"
    | .keywords = [$service, "homelab", "mcp"]
    | .skills = "./skills/"
    | .mcpServers = "./.mcp.json"
    | .apps = "./.app.json"
    | .interface = {
        displayName: ($display_name + " MCP"),
        shortDescription: ("Manage " + $display_name + " resources via MCP tools"),
        longDescription: ("Full MCP integration for " + $display_name + " with action+subaction pattern, destructive operation gating, and dual-mode skill support."),
        developerName: "Jacob Magar",
        category: "Infrastructure",
        capabilities: ["mcp", "tools", "skills"],
        brandColor: "#4A90D9",
        composerIcon: "./assets/icon.png",
        logo: "./assets/logo.svg",
        screenshots: ["./assets/screenshots/overview.png"]
      }
    ' \
    "$src" > "$dest"
}

render_app_manifest() {
  local src="${TEMPLATE_SHARED_ROOT}/.app.json"
  local dest="${OUT_DIR}/.app.json"

  jq \
    --arg plugin_name "$PLUGIN_NAME" \
    '
    if . == {} then
      {
        apps: [
          {
            name: $plugin_name,
            type: "mcp",
            config: "./.mcp.json"
          }
        ]
      }
    else
      .
    end
    ' \
    "$src" > "$dest"
}

render_mcp_manifest() {
  local src="${TEMPLATE_SHARED_ROOT}/.mcp.json"
  local dest="${OUT_DIR}/.mcp.json"

  jq \
    --arg plugin_name "$PLUGIN_NAME" \
    --arg tool_name "$TOOL_NAME" \
    '
    .mcpServers = {
      ($plugin_name): {
        type: "http",
        url: ("${user_config." + $tool_name + "_mcp_url}"),
        headers: {
          Authorization: ("Bearer ${user_config." + $tool_name + "_mcp_token}")
        }
      }
    }
    ' \
    "$src" > "$dest"
}

# ── Argument parsing ────────────────────────────────────────────────────────

usage() {
  cat >&2 <<EOF
Usage: $0 <service-name> <language> [--port PORT]

Arguments:
  service-name   Lowercase, hyphenated service name (e.g. my-service)
  language       python | typescript | rust

Options:
  --port PORT    MCP server port (default: 9000)
  -h, --help     Show this help

Examples:
  $0 gotify python --port 9158
  $0 synapse typescript --port 3000
  $0 syslog rust --port 3100
EOF
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: $0 <service-name> <language> [--port PORT]

Generates a new MCP server plugin skeleton from the canonical template.

Arguments:
  service-name   Lowercase, hyphenated service name (e.g. my-service)
  language       python | typescript | rust

Options:
  --port PORT    MCP server port (default: 9000)
  -h, --help     Show this help and exit

Examples:
  $0 gotify python --port 9158
  $0 synapse typescript --port 3000
  $0 syslog rust --port 3100

Creates directory ./<service-name>-mcp/ with full plugin structure.
EOF
  exit 0
fi

if [ $# -lt 2 ]; then
  usage
fi

SERVICE="$1"
LANG="$2"
shift 2

PORT=9000

while [ $# -gt 0 ]; do
  case "$1" in
    --port)
      PORT="${2:?--port requires a value}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate language
case "$LANG" in
  python|typescript|rust) ;;
  *)
    echo "Error: language must be python, typescript, or rust (got: $LANG)" >&2
    exit 1
    ;;
esac

case "$LANG" in
  python) LANG_TEMPLATE_DIR="py" ;;
  typescript) LANG_TEMPLATE_DIR="ts" ;;
  rust) LANG_TEMPLATE_DIR="rs" ;;
esac

TEMPLATE_LANG_ROOT="${TEMPLATE_ROOT}/${LANG_TEMPLATE_DIR}"

if [[ ! -d "$TEMPLATE_LANG_ROOT" ]]; then
  echo "Error: language template root not found: $TEMPLATE_LANG_ROOT" >&2
  exit 1
fi

# Validate service name (lowercase, hyphens, no leading/trailing hyphen)
if ! echo "$SERVICE" | grep -qE '^[a-z][a-z0-9-]*[a-z0-9]$'; then
  echo "Error: service name must be lowercase alphanumeric with hyphens (got: $SERVICE)" >&2
  exit 1
fi

# ── Derive all names ────────────────────────────────────────────────────────

PLUGIN_NAME="${SERVICE}-mcp"
TOOL_NAME="$(echo "$SERVICE" | tr '-' '_')"
ENV_PREFIX="$(echo "$SERVICE" | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
MCP_ENV_PREFIX="${ENV_PREFIX}_MCP"
DOCKER_NETWORK="${SERVICE}_mcp"
MODULE_NAME="${TOOL_NAME}_mcp"
DISPLAY_NAME="$(echo "$SERVICE" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')"
CURRENT_YEAR="$(date +%Y)"
TODAY="$(date +%Y-%m-%d)"

OUT_DIR="./${PLUGIN_NAME}"

if [ -d "$OUT_DIR" ]; then
  echo "Error: directory $OUT_DIR already exists" >&2
  exit 1
fi

echo "Scaffolding ${PLUGIN_NAME} (${LANG}) at ${OUT_DIR} ..."

# ── Create directory structure ──────────────────────────────────────────────

mkdir -p "${OUT_DIR}"/{.claude-plugin,.codex-plugin,.github/workflows,assets,hooks/scripts,skills/"${SERVICE}",scripts,tests,logs}

# ── 0. language manifest ────────────────────────────────────────────────────

case "$LANG" in
  python)
    render_template \
      "${TEMPLATE_LANG_ROOT}/pyproject.toml" \
      "${OUT_DIR}/pyproject.toml"
    ;;
  typescript)
    render_template \
      "${TEMPLATE_LANG_ROOT}/package.json" \
      "${OUT_DIR}/package.json"
    ;;
  rust)
    render_template \
      "${TEMPLATE_LANG_ROOT}/Cargo.toml" \
      "${OUT_DIR}/Cargo.toml"
    ;;
esac

# ── 1. core plugin manifests ────────────────────────────────────────────────

render_claude_plugin_manifest
render_codex_plugin_manifest
render_app_manifest
render_mcp_manifest

# ── 5. install-surface assets ──────────────────────────────────────────────

mkdir -p "${OUT_DIR}/assets/screenshots"
cat > "${OUT_DIR}/assets/logo.svg" <<EOFLOGO
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-labelledby="title desc">
  <title>${DISPLAY_NAME} logo</title>
  <desc>Scaffolded ${DISPLAY_NAME} MCP plugin logo</desc>
  <rect width="256" height="256" rx="32" fill="#0f172a"/>
  <rect x="24" y="24" width="208" height="208" rx="24" fill="#1d4ed8"/>
  <path d="M72 88h112v24H72zm0 44h112v24H72zm0 44h72v24H72z" fill="#f8fafc"/>
</svg>
EOFLOGO
base64 -d > "${OUT_DIR}/assets/icon.png" <<'EOFPNG'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6V7WQAAAAASUVORK5CYII=
EOFPNG
cp "${OUT_DIR}/assets/icon.png" "${OUT_DIR}/assets/screenshots/overview.png"

# ── 6. hooks/hooks.json ─────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/hooks/claude/hooks.json" \
  "${OUT_DIR}/hooks/hooks.json"

# ── 7. hooks/scripts/sync-env.sh ───────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/hooks/scripts/sync-env.sh" \
  "${OUT_DIR}/hooks/scripts/sync-env.sh"
chmod +x "${OUT_DIR}/hooks/scripts/sync-env.sh"

# ── 8. hooks/scripts/fix-env-perms.sh ──────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/hooks/scripts/fix-env-perms.sh" \
  "${OUT_DIR}/hooks/scripts/fix-env-perms.sh"
chmod +x "${OUT_DIR}/hooks/scripts/fix-env-perms.sh"

# ── 9. hooks/scripts/ensure-ignore-files.sh ─────────────────────────────────

if [ -f "${TEMPLATE_SHARED_ROOT}/hooks/scripts/ensure-ignore-files.sh" ]; then
  cp "${TEMPLATE_SHARED_ROOT}/hooks/scripts/ensure-ignore-files.sh" "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh"
else
  # Minimal fallback
  cat > "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh" <<'EOFENSURE'
#!/usr/bin/env bash
set -euo pipefail
# Ensure .gitignore and .dockerignore have required patterns.
# Copy the full version from claude-homelab/scripts/ensure-ignore-files.sh
echo "ensure-ignore-files: stub — replace with full script from claude-homelab/scripts/"
EOFENSURE
fi
chmod +x "${OUT_DIR}/hooks/scripts/ensure-ignore-files.sh"

# ── 10. skills/<service>/SKILL.md ───────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/skills/my-plugin/claude/SKILL.md" \
  "${OUT_DIR}/skills/${SERVICE}/SKILL.md"

# ── 11. CLAUDE.md ───────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/CLAUDE.md" \
  "${OUT_DIR}/CLAUDE.md"

# ── 12. AGENTS.md -> CLAUDE.md ──────────────────────────────────────────────

ln -sf CLAUDE.md "${OUT_DIR}/AGENTS.md"

# ── 13. GEMINI.md -> CLAUDE.md ──────────────────────────────────────────────

ln -sf CLAUDE.md "${OUT_DIR}/GEMINI.md"

# ── 14. README.md ───────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/README.md" \
  "${OUT_DIR}/README.md"

# ── 15. CHANGELOG.md ────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/CHANGELOG.md" \
  "${OUT_DIR}/CHANGELOG.md"

# ── 16. LICENSE ─────────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/LICENSE" \
  "${OUT_DIR}/LICENSE"

# ── 17. .gitignore ──────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/.gitignore" \
  "${OUT_DIR}/.gitignore"

# ── 18. .dockerignore ───────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/.dockerignore" \
  "${OUT_DIR}/.dockerignore"

# ── 19. .env.example ────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_SHARED_ROOT}/.env.example" \
  "${OUT_DIR}/.env.example"

# ── 20. hook runner config ──────────────────────────────────────────────────

case "$LANG" in
  python)
    render_template \
      "${TEMPLATE_LANG_ROOT}/.pre-commit-config.yaml" \
      "${OUT_DIR}/.pre-commit-config.yaml"
    ;;
  typescript)
    render_template \
      "${TEMPLATE_LANG_ROOT}/lefthook.yml" \
      "${OUT_DIR}/lefthook.yml"
    ;;
  rust)
    render_template \
      "${TEMPLATE_LANG_ROOT}/lefthook.yml" \
      "${OUT_DIR}/lefthook.yml"
    ;;
esac

# ── 21. Justfile ────────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/Justfile" \
  "${OUT_DIR}/Justfile"

# ── 22. entrypoint.sh ───────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/entrypoint.sh" \
  "${OUT_DIR}/entrypoint.sh"
chmod +x "${OUT_DIR}/entrypoint.sh"

# ── 23. Dockerfile ──────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/Dockerfile" \
  "${OUT_DIR}/Dockerfile"

# ── 24. docker-compose.yaml ─────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/docker-compose.yaml" \
  "${OUT_DIR}/docker-compose.yaml"

# ── 25. tests/test_live.sh ──────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/tests/test_live.sh" \
  "${OUT_DIR}/tests/test_live.sh"
chmod +x "${OUT_DIR}/tests/test_live.sh"

# ── 27. logs/.gitkeep ───────────────────────────────────────────────────────

touch "${OUT_DIR}/logs/.gitkeep"

# ── 27a. runtime source tree ────────────────────────────────────────────────

case "$LANG" in
  python)
    mkdir -p "${OUT_DIR}/${MODULE_NAME}"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/__init__.py" \
      "${OUT_DIR}/${MODULE_NAME}/__init__.py"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/client.py" \
      "${OUT_DIR}/${MODULE_NAME}/client.py"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/server.py" \
      "${OUT_DIR}/${MODULE_NAME}/server.py"
    ;;
  typescript)
    mkdir -p "${OUT_DIR}/${MODULE_NAME}"
    render_template \
      "${TEMPLATE_LANG_ROOT}/tsconfig.json" \
      "${OUT_DIR}/tsconfig.json"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/client.ts" \
      "${OUT_DIR}/${MODULE_NAME}/client.ts"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/index.ts" \
      "${OUT_DIR}/${MODULE_NAME}/index.ts"
    ;;
  rust)
    mkdir -p "${OUT_DIR}/${MODULE_NAME}"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/client.rs" \
      "${OUT_DIR}/${MODULE_NAME}/client.rs"
    render_template \
      "${TEMPLATE_LANG_ROOT}/my_plugin_mcp/main.rs" \
      "${OUT_DIR}/${MODULE_NAME}/main.rs"
    ;;
esac

# ── 28. scripts/ — copy from canonical templates ────────────────────────────

for script in check-docker-security.sh check-no-baked-env.sh; do
  src="${TEMPLATE_SHARED_ROOT}/scripts/${script}"
  if [ -f "$src" ]; then
    render_template "$src" "${OUT_DIR}/scripts/${script}"
    chmod +x "${OUT_DIR}/scripts/${script}"
  else
    echo "Warning: ${src} not found — creating stub" >&2
    cat > "${OUT_DIR}/scripts/${script}" <<EOFSTUB
#!/usr/bin/env bash
set -euo pipefail
echo "TODO: provide ${script} template"
exit 0
EOFSTUB
    chmod +x "${OUT_DIR}/scripts/${script}"
  fi
done

if [ -f "${TEMPLATE_LANG_ROOT}/scripts/check-outdated-deps.sh" ]; then
  render_template \
    "${TEMPLATE_LANG_ROOT}/scripts/check-outdated-deps.sh" \
    "${OUT_DIR}/scripts/check-outdated-deps.sh"
  chmod +x "${OUT_DIR}/scripts/check-outdated-deps.sh"
fi

if [ -f "${TEMPLATE_SHARED_ROOT}/hooks/scripts/ensure-ignore-files.sh" ]; then
  cp "${TEMPLATE_SHARED_ROOT}/hooks/scripts/ensure-ignore-files.sh" "${OUT_DIR}/scripts/ensure-ignore-files.sh"
  chmod +x "${OUT_DIR}/scripts/ensure-ignore-files.sh"
fi

# ── 29. workflows ────────────────────────────────────────────────────────────

render_template \
  "${TEMPLATE_LANG_ROOT}/.github/workflows/ci.yaml" \
  "${OUT_DIR}/.github/workflows/ci.yaml"
render_template \
  "${TEMPLATE_LANG_ROOT}/.github/workflows/publish-image.yaml" \
  "${OUT_DIR}/.github/workflows/publish-image.yaml"
render_template \
  "${TEMPLATE_LANG_ROOT}/.github/workflows/release-on-main.yaml" \
  "${OUT_DIR}/.github/workflows/release-on-main.yaml"

# ── 30. refresh mirrored docs if present ────────────────────────────────────

DOC_SYNC_SCRIPT="${REPO_ROOT}/scripts/update-doc-mirrors.sh"
if [ -x "${DOC_SYNC_SCRIPT}" ] || [ -f "${DOC_SYNC_SCRIPT}" ]; then
  echo
  echo "Refreshing mirrored docs in ${OUT_DIR}/ ..."
  bash "${DOC_SYNC_SCRIPT}" "${OUT_DIR}"
else
  echo "Warning: ${DOC_SYNC_SCRIPT} not found — skipping mirrored doc refresh" >&2
fi

# ── Summary ─────────────────────────────────────────────────────────────────

FILE_COUNT=$(find "${OUT_DIR}" -type f | wc -l)
SYMLINK_COUNT=$(find "${OUT_DIR}" -type l | wc -l)

echo
echo "================================================================"
echo "  Plugin scaffolded: ${PLUGIN_NAME}"
echo "================================================================"
echo
echo "  Directory:   ${OUT_DIR}/"
echo "  Language:    ${LANG}"
echo "  Port:        ${PORT}"
echo "  Tool name:   ${TOOL_NAME}"
echo "  Env prefix:  ${ENV_PREFIX}_* / ${MCP_ENV_PREFIX}_*"
echo "  Network:     ${DOCKER_NETWORK}"
echo
echo "  Files created: ${FILE_COUNT}"
echo "  Symlinks:      ${SYMLINK_COUNT} (AGENTS.md, GEMINI.md)"
echo
echo "Directory structure:"
find "${OUT_DIR}" -type f -o -type l | sort | sed "s|^${OUT_DIR}/|  |"
echo
echo "Next steps:"
echo "  1. cd ${OUT_DIR}"
echo "  2. Review the generated ${LANG} manifest and scaffolded files"
case "$LANG" in
  python)
    echo "  3. Install dependencies and lock the environment:"
    echo "       uv sync"
    ;;
  typescript)
    echo "  3. Install dependencies:"
    echo "       npm install"
    ;;
  rust)
    echo "  3. Fetch dependencies and verify the workspace:"
    echo "       cargo check"
    ;;
esac
echo "  4. cp .env.example .env && chmod 600 .env"
echo "  5. Edit .env with your credentials"
echo "  6. Generate a bearer token: openssl rand -hex 32"
echo "  7. Implement your server in ${MODULE_NAME}/"
echo "  8. git init && git add -A && git commit -m 'feat: initial ${PLUGIN_NAME} scaffold'"
echo "  9. Validate: claude plugin validate ."
echo " 10. Test: just test-live"
echo
