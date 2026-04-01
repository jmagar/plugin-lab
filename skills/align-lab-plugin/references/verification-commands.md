# Verification Commands Reference

Concrete shell commands for each check type used during plugin alignment. Run these after making changes to confirm correctness. Organized by check type with example output shown.

---

## Manifest Validation

### JSON well-formedness

```bash
jq . .claude-plugin/plugin.json
```

**Example good output:**
```json
{
  "name": "my-plugin",
  "version": "1.2.0",
  "mcp_version": "1.0",
  "description": "Does something useful"
}
```

**Example bad output:**
```
parse error (Invalid numeric literal at line 4, column 12)
```

### Required fields present

```bash
jq '{name, version, mcp_version, description} | to_entries[] | select(.value == null) | .key' \
  .claude-plugin/plugin.json
```

**Good output:** *(empty — all required fields are present)*

**Bad output:**
```
"mcp_version"
```

---

## Version Sync

### Cross-file version check

```bash
grep -rn '"version"' \
  .claude-plugin/plugin.json \
  package.json \
  pyproject.toml \
  Cargo.toml \
  2>/dev/null
```

**Example good output:**
```
.claude-plugin/plugin.json:3:  "version": "1.2.0",
package.json:4:  "version": "1.2.0",
```

**Example bad output (drift):**
```
.claude-plugin/plugin.json:3:  "version": "0.1.0",
package.json:4:  "version": "1.2.0",
```

### Git tag alignment

```bash
git describe --tags --abbrev=0
jq -r .version .claude-plugin/plugin.json
```

Both commands should produce the same version string (e.g., `1.2.0`).

### CHANGELOG header

```bash
head -5 CHANGELOG.md
```

The most recent version header should match the manifest version.

---

## Shell Syntax Checks

### Single script

```bash
bash -n entrypoint.sh
```

**Good output:** *(empty — no syntax errors)*

**Bad output:**
```
entrypoint.sh: line 14: syntax error near unexpected token `fi'
```

### All shell scripts in the repo

```bash
find . -name '*.sh' -not -path './.git/*' | while read f; do
  bash -n "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

**Good output:**
```
OK: ./entrypoint.sh
OK: ./hooks/scripts/fix-env-perms.sh
OK: ./hooks/scripts/check-no-baked-env.sh
```

### Strict mode check

```bash
head -3 entrypoint.sh
```

Should contain `set -euo pipefail` (or equivalent).

---

## JSON / TOML / YAML Parsing

### JSON files

```bash
for f in $(find . -name '*.json' -not -path './.git/*'); do
  jq empty "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

### YAML files (requires `yamllint`)

```bash
yamllint .github/workflows/ci.yaml
```

**Good output:** *(empty)*

**Bad output:**
```
.github/workflows/ci.yaml
  8:3      error    wrong indentation: expected 4 but found 2  (indentation)
```

### All YAML files

```bash
find . -name '*.yaml' -o -name '*.yml' | grep -v '.git' | while read f; do
  yamllint "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

### TOML files (requires `taplo` or Python `tomllib`)

```bash
# Using Python (3.11+)
python3 -c "import tomllib; tomllib.load(open('Cargo.toml','rb'))" && echo "OK"

# Using taplo if available
taplo check Cargo.toml
```

### Docker Compose config

```bash
docker compose config --quiet
```

**Good output:** *(empty — config is valid)*

**Bad output:**
```
validating /path/to/docker-compose.yaml: services.my-plugin.healthcheck.interval must be a duration
```

---

## Env Var Coverage

### Vars in entrypoint not documented in `.env.example`

```bash
comm -23 \
  <(grep -oE '\brequire[d]?\s+"?[A-Z_][A-Z0-9_]+"?' entrypoint.sh \
    | grep -oE '[A-Z_][A-Z0-9_]+' | sort -u) \
  <(grep -oE '^[A-Z_][A-Z0-9_]+' .env.example | sort -u)
```

**Good output:** *(empty — all vars are documented)*

**Bad output:**
```
SECRET_API_TOKEN
MISSING_CONFIG_VAR
```

### Vars in `.env.example` not used in application code

```bash
while IFS= read -r var; do
  grep -rq "$var" --include='*.py' --include='*.ts' --include='*.rs' \
    --include='*.sh' . 2>/dev/null \
    || echo "UNUSED in code: $var"
done < <(grep -oE '^[A-Z_][A-Z0-9_]+' .env.example)
```

---

## Test Commands

### Run live tests (requires running container)

```bash
just up
just test
echo "exit code: $?"
```

### Health endpoint probe

```bash
curl -sf http://localhost:8080/health && echo "healthy" || echo "FAILED"
```

**Good output:**
```
healthy
```

**Bad output:**
```
curl: (7) Failed to connect to localhost port 8080: Connection refused
FAILED
```

### Check container is running

```bash
docker compose ps
```

**Good output:**
```
NAME          IMAGE              COMMAND        SERVICE     CREATED    STATUS         PORTS
my-plugin-1   my-plugin:1.2.0   "/entrypoint"  my-plugin   5s ago     Up 4s (healthy)  0.0.0.0:8080->8080/tcp
```

---

## Hook Config Checks

### All hook scripts exist

```bash
# For hooks.json (Claude hooks format)
jq -r '.hooks[].command' hooks/claude/hooks.json | awk '{print $1}' | while read script; do
  [[ -f "$script" ]] && echo "OK: $script" || echo "MISSING: $script"
done
```

### All hook scripts are executable

```bash
find hooks/scripts/ -name '*.sh' ! -executable -print
# Good output: (empty)
```

### hooks.json is valid JSON

```bash
jq . hooks/claude/hooks.json > /dev/null && echo "OK"
```

---

## Dockerfile Checks

### Multi-stage build present

```bash
grep -c '^FROM' Dockerfile
# Should be >= 2
```

### Non-root user set in runtime stage

```bash
grep -n '^USER' Dockerfile
# Should appear at least once, in the runtime stage
```

### No latest-tagged base images

```bash
grep '^FROM' Dockerfile | grep ':latest'
# Good output: (empty)
```

### No secrets in ENV instructions

```bash
grep -iE '^ENV.*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL)' Dockerfile
# Good output: (empty)
```
