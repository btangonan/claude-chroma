#!/usr/bin/env bash
# ChromaDB + Claude MCP Setup (v4 + rollback)
# Clean, idempotent, CI-friendly, with automatic rollback on failure.
# Usage:
#   CHROMA_SETUP_YES=1 ./chromadb_setup_v4_rollback.sh "<ProjectName>" "<ParentPath>"
#   CHROMA_SETUP_ADD_SHELL_FN=1 to auto-install shell function without prompting
#   CHROMA_MCP_VERSION=0.1.7 to pin chroma-mcp

set -euo pipefail

# ---------- Config ----------
: "${CHROMA_SETUP_YES:=0}"                 # 1 = non-interactive "yes to all"
: "${CHROMA_SETUP_ADD_SHELL_FN:=0}"        # 1 = install shell function without prompting
: "${CHROMA_MCP_VERSION:=}"                # e.g. "0.1.7". Empty = latest
: "${DEFAULT_PARENT_PATH:=$HOME/Projects}"

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'

ok(){ echo "${GREEN}✓${NC} $*"; }
info(){ echo "${BLUE}ℹ${NC} $*"; }
warn(){ echo "${YELLOW}!${NC} $*"; }
err(){ echo "${RED}✗${NC} $*"; }
header(){ printf "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${YELLOW}%s${NC}\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n" "$1"; }

ask(){
  local prompt="${1:-Proceed?}"
  if [[ "$CHROMA_SETUP_YES" == "1" ]]; then
    REPLY="y"
    return 0
  fi
  read -p "$prompt (y/n): " -n 1 -r
  echo
  [[ "$REPLY" =~ ^[Yy]$ ]]
}

# ---------- Lightweight rollback manager ----------
BACKUP_ROOT=""
BACKUP_DIR=""
ROLLBACK_ITEMS=()

start_backups(){
  BACKUP_ROOT="${TMPDIR:-/tmp}"
  BACKUP_DIR="$BACKUP_ROOT/chroma_rollback_$(date +%Y%m%d_%H%M%S)_$$"
  mkdir -p "$BACKUP_DIR"
  info "Rollback enabled. Backup dir: $BACKUP_DIR"
}

backup_file(){
  # $1 = path to file to back up if it exists
  local p="$1"
  if [[ -f "$p" ]]; then
    local rel="${p#./}"
    local dest="$BACKUP_DIR/${rel//\//__}"
    cp "$p" "$dest"
    ROLLBACK_ITEMS+=("$p:$dest")
    info "Backed up: $p -> $dest"
  fi
}

do_rollback(){
  if [[ -n "${ROLLBACK_ITEMS[*]:-}" ]]; then
    warn "Rolling back ${#ROLLBACK_ITEMS[@]} file(s)"
    for pair in "${ROLLBACK_ITEMS[@]}"; do
      local orig="${pair%%:*}"
      local bak="${pair##*:}"
      if [[ -f "$bak" ]]; then
        cp "$bak" "$orig"
        info "Restored: $orig"
      fi
    done
  fi
}

cleanup_backups(){
  if [[ -d "$BACKUP_DIR" ]]; then
    rm -rf "$BACKUP_DIR" || true
  fi
}

trap 'err "Setup failed"; do_rollback; exit 1' ERR
trap 'cleanup_backups' EXIT

start_backups

# ---------- Prereqs ----------
header "Checking prerequisites"

# uvx
if ! command -v uvx >/dev/null 2>&1; then
  warn "uvx not found. Will attempt to install uv."
  if ask "Install uv to get uvx now"; then
    if command -v pipx >/dev/null 2>&1; then
      pipx install uv || true
    fi
    if ! command -v uvx >/dev/null 2>&1; then
      if command -v pip >/dev/null 2>&1; then
        pip install --user uv || true
      elif command -v pip3 >/dev/null 2>&1; then
        pip3 install --user uv || true
      fi
      export PATH="$HOME/.local/bin:$PATH"
    fi
    if ! command -v uvx >/dev/null 2>&1; then
      err "uvx still not found. Install instructions: https://docs.astral.sh/uv/"
      echo "Quick install: curl -LsSf https://astral.sh/uv/install.sh | sh"
      exit 1
    fi
  else
    exit 1
  fi
fi
UVX_PATH="$(command -v uvx)"
ok "uvx found at: $UVX_PATH"

# Optional tools
CLAUDE_CLI_FOUND=0
if command -v claude >/dev/null 2>&1; then
  CLAUDE_CLI_FOUND=1; ok "claude CLI found"
else
  info "claude CLI not found. You can install later: https://claude.ai/download"
fi

JQ_FOUND=0
if command -v jq >/dev/null 2>&1; then JQ_FOUND=1; fi

PYTHON_FOUND=0
if command -v python3 >/dev/null 2>&1; then PYTHON_FOUND=1; fi

# ---------- Ensure chroma-mcp ----------
header "Ensuring chroma-mcp availability"
if ! "$UVX_PATH" -qq chroma-mcp --help >/dev/null 2>&1; then
  info "Installing chroma-mcp"
  if [[ -n "$CHROMA_MCP_VERSION" ]]; then
    "$UVX_PATH" install "chroma-mcp==${CHROMA_MCP_VERSION}"
  else
    "$UVX_PATH" install chroma-mcp
  fi
fi
ok "chroma-mcp is available"

# ---------- Resolve project dir ----------
PROJECT_NAME="${1:-}"
PARENT_PATH="${2:-}"

if [[ -z "$PROJECT_NAME" ]]; then
  if [[ "$CHROMA_SETUP_YES" == "1" ]]; then
    PROJECT_DIR="$(pwd)"
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
  else
    read -p "Enter project name (blank = current directory): " PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
      PROJECT_DIR="$(pwd)"
      PROJECT_NAME="$(basename "$PROJECT_DIR")"
    else
      if [[ -z "$PARENT_PATH" ]]; then
        read -p "Enter project parent path (default: $DEFAULT_PARENT_PATH): " PARENT_PATH
        PARENT_PATH="${PARENT_PATH:-$DEFAULT_PARENT_PATH}"
      fi
      PROJECT_DIR="$PARENT_PATH/$PROJECT_NAME"
    fi
  fi
else
  if [[ -z "$PARENT_PATH" ]]; then
    PARENT_PATH="$DEFAULT_PARENT_PATH"
  fi
  PROJECT_DIR="$PARENT_PATH/$PROJECT_NAME"
fi

header "Configuring project: $PROJECT_NAME"
info "Directory: $PROJECT_DIR"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ---------- Create structure ----------
mkdir -p .chroma .claude claudedocs
ok "Directories ready: .chroma .claude claudedocs"

# ---------- Write/merge .claude/settings.local.json ----------
SETTINGS_PATH=".claude/settings.local.json"
ABS_DATA_DIR="$(pwd)/.chroma"

CONFIG_JSON=$(cat <<JSON
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "$UVX_PATH",
      "args": ["-qq","chroma-mcp","--client-type","persistent","--data-dir","$ABS_DATA_DIR"],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False"
      }
    }
  },
  "instructions": [
    "After any successful fix, decision, gotcha, or preference, log a memory to Chroma:",
    "Use mcp__chroma__chroma_add_documents with:",
    "- collection_name: 'project_memory' (must exist, create first if needed)",
    "- documents: [\\\"1-2 sentences, <300 chars\\\"]",
    "- metadatas: [{\\\"type\\\":\\\"decision|fix|tip\\\",\\\"tags\\\":\\\"k1,k2\\\",\\\"source\\\":\\\"file:line\\\"}]",
    "- ids: [\\\"stable-id-string\\\"]",
    "Always confirm: 'Logged memory: {id}'"
  ]
}
JSON
)

header "Configuring Claude MCP settings"
backup_file "$SETTINGS_PATH"
backup_and_merge_settings(){
  local path="$1"
  local tmp="${path}.tmp.$$"
  if [[ -f "$path" ]]; then
    if [[ "$JQ_FOUND" == "1" ]]; then
      jq --argjson NEW "$CONFIG_JSON" '
        . as $orig
        | ($orig.mcpServers // {}) as $m
        | ($orig.instructions // []) as $i
        | {
            mcpServers: ($m + {chroma: $NEW.mcpServers.chroma}),
            instructions: ($i + $NEW.instructions | unique)
          }
      ' "$path" > "$tmp"
    elif [[ "$PYTHON_FOUND" == "1" ]]; then
      python3 - "$path" "$tmp" <<'PY'
import json, sys
src, out = sys.argv[1], sys.argv[2]
NEW = json.loads(sys.stdin.read())
with open(src,'r') as f: data = json.load(f)
data.setdefault('mcpServers',{})
data['mcpServers']['chroma'] = NEW['mcpServers']['chroma']
ins = data.get('instructions',[])
for s in NEW['instructions']:
    if s not in ins: ins.append(s)
data['instructions']=ins
with open(out,'w') as f: json.dump(data, f, indent=2)
PY
      python3 - "$SETTINGS_PATH" "$tmp" <<<"$CONFIG_JSON"
    else
      warn "Neither jq nor python3 available. Replacing settings file."
      printf "%s\n" "$CONFIG_JSON" > "$tmp"
    fi
  else
    printf "%s\n" "$CONFIG_JSON" > "$tmp"
  fi
  mv "$tmp" "$path"
  ok "Settings written: $path"
}
backup_and_merge_settings "$SETTINGS_PATH"

# ---------- CLAUDE.md block (idempotent) ----------
header "Updating CLAUDE.md"
CLAUDE_MD="CLAUDE.md"
BEGIN_TAG="<!-- BEGIN:CHROMA-AUTOINIT -->"
END_TAG="<!-- END:CHROMA-AUTOINIT -->"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

BLOCK="$BEGIN_TAG
## ChromaDB Memory System — Auto Init

At session start:
1) List collections. If \`project_memory\` is missing, create it. Then log an init memory.

\`\`\`javascript
mcp__chroma__chroma_create_collection { \"collection_name\": \"project_memory\" }
mcp__chroma__chroma_add_documents {
  \"collection_name\": \"project_memory\",
  \"documents\": [\"Project initialized with Chroma memory\"],
  \"metadatas\": [{\"type\":\"decision\",\"tags\":\"setup,chroma,memory\",\"source\":\"init\",\"timestamp\":\"$TS\"}],
  \"ids\": [\"decision-setup-001\"]
}
\`\`\`
$END_TAG"

backup_file "$CLAUDE_MD"
touch "$CLAUDE_MD"
if grep -q "$BEGIN_TAG" "$CLAUDE_MD"; then
  awk -v b="$BEGIN_TAG" -v e="$END_TAG" -v r="$BLOCK" '
    $0 ~ b {print r; skip=1; next}
    $0 ~ e {skip=0; next}
    !skip {print}
  ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
  ok "Updated ChromaDB block in CLAUDE.md"
else
  printf "\n%s\n" "$BLOCK" >> "$CLAUDE_MD"
  ok "Added ChromaDB block to CLAUDE.md"
fi

# ---------- .gitignore (idempotent block) ----------
header "Updating .gitignore"
GITIGNORE=".gitignore"
GI_BEGIN="# BEGIN:CHROMA-CLAUDE"
GI_END="# END:CHROMA-CLAUDE"
GI_BLOCK="$GI_BEGIN
# ChromaDB local database
.chroma/
*.chroma

# Claude local settings (machine-specific; do NOT track)
.claude/settings.local.json

# Memory exports
claudedocs/*.md

# Python
__pycache__/
*.py[cod]
.pytest_cache/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
$GI_END"

backup_file "$GITIGNORE"
touch "$GITIGNORE"
if grep -q "$GI_BEGIN" "$GITIGNORE"; then
  awk -v b="$GI_BEGIN" -v e="$GI_END" -v r="$GI_BLOCK" '
    $0 ~ b {print r; skip=1; next}
    $0 ~ e {skip=0; next}
    !skip {print}
  ' "$GITIGNORE" > "${GITIGNORE}.tmp" && mv "${GITIGNORE}.tmp" "$GITIGNORE"
  ok ".gitignore block updated"
else
  printf "\n%s\n" "$GI_BLOCK" >> "$GITIGNORE"
  ok ".gitignore block added"
fi

# ---------- Starter launcher script ----------
header "Creating start script"
LAUNCH="./start-claude-chroma.sh"
backup_file "$LAUNCH"
cat > "$LAUNCH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
CONF=".claude/settings.local.json"
if [[ ! -f "$CONF" ]]; then
  echo "Missing $CONF. Run setup first."
  exit 1
fi
if command -v claude >/dev/null 2>&1; then
  exec claude --mcp-config "$CONF" chat
else
  echo "Claude CLI not found. Install: https://claude.ai/download"
  exit 1
fi
SH
chmod +x "$LAUNCH"
ok "Launcher ready: $LAUNCH"

# ---------- Optional shell function ----------
header "Shell function (optional)"
install_shell_fn(){
  local sh_name="$(basename "${SHELL:-bash}")"
  local cfg
  case "$sh_name" in
    bash) cfg="$HOME/.bashrc";;
    zsh)  cfg="$HOME/.zshrc";;
    fish) cfg="$HOME/.config/fish/config.fish";;
    *)    cfg="$HOME/.profile";;
  esac
  info "Detected shell: $sh_name"
  info "Config file: $cfg"

  mkdir -p "$(dirname "$cfg")"
  backup_file "$cfg"

  if [[ "$sh_name" == "fish" ]]; then
    local begin="# BEGIN:CLAUDE-CHROMA-FN"
    local end="# END:CLAUDE-CHROMA-FN"
    local block="$begin
function claude-chroma --description \"Start Claude with auto-detected Chroma config\"
    set config_file \"\"
    set search_dir \"$PWD\"
    while test \"\$search_dir\" != \"/\"
        if test -f \"\$search_dir/.claude/settings.local.json\"
            set config_file \"\$search_dir/.claude/settings.local.json\"
            break
        end
        set search_dir (dirname \"\$search_dir\")
    end
    if test -n \"\$config_file\"
        echo \"Using ChromaDB config: \$config_file\"
        claude --mcp-config \"\$config_file\" \$argv
    else
        echo \"No ChromaDB config found. Starting regular Claude.\"
        claude \$argv
    end
end
$end"
    touch "$cfg"
    if grep -q "$begin" "$cfg"; then
      awk -v b="$begin" -v e="$end" -v r="$block" '
        $0 ~ b {print r; skip=1; next}
        $0 ~ e {skip=0; next}
        !skip {print}
      ' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
      ok "Updated claude-chroma function in $cfg"
    else
      printf "\n%s\n" "$block" >> "$cfg"
      ok "Added claude-chroma function to $cfg"
    fi
  else
    local begin="# BEGIN:CLAUDE-CHROMA-FN"
    local end="# END:CLAUDE-CHROMA-FN"
    local block="$begin
claude-chroma() {
  local config_file=\"\"
  local search_dir=\"\$PWD\"
  while [[ \"\$search_dir\" != \"/\" ]]; do
    if [[ -f \"\$search_dir/.claude/settings.local.json\" ]]; then
      config_file=\"\$search_dir/.claude/settings.local.json\"
      break
    fi
    search_dir=\$(dirname \"\$search_dir\")
  done
  if [[ -n \"\$config_file\" ]]; then
    echo \"Using ChromaDB config: \$config_file\"
    claude --mcp-config \"\$config_file\" \"\$@\"
  else
    echo \"No ChromaDB config found. Starting regular Claude.\"
    claude \"\$@\"
  fi
}
$end"
    touch "$cfg"
    if grep -q "$begin" "$cfg"; then
      awk -v b="$begin" -v e="$end" -v r="$block" '
        $0 ~ b {print r; skip=1; next}
        $0 ~ e {skip=0; next}
        !skip {print}
      ' "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
      ok "Updated claude-chroma function in $cfg"
    else
      printf "\n%s\n" "$block" >> "$cfg"
      ok "Added claude-chroma function to $cfg"
    fi
  fi
  info "Reload your shell config or open a new terminal to use claude-chroma"
}

if [[ "$CHROMA_SETUP_ADD_SHELL_FN" == "1" ]]; then
  install_shell_fn
else
  if ask "Add a global claude-chroma shell function"; then
    install_shell_fn
  else
    info "Skipping shell function"
  fi
fi

# ---------- Summary ----------
header "Setup complete"
echo "Project:   $PROJECT_NAME"
echo "Location:  $PROJECT_DIR"
echo
ok "Chroma MCP configured"
ok "CLAUDE.md auto-init block in place"
ok ".gitignore updated"
ok "Launcher created: $LAUNCH"
echo
info "Next:"
echo "  cd \"$PROJECT_DIR\""
if [[ "$CLAUDE_CLI_FOUND" == "1" ]]; then
  echo "  ./start-claude-chroma.sh"
  echo "  or: claude --mcp-config .claude/settings.local.json chat"
else
  echo "  Install the Claude CLI, then run ./start-claude-chroma.sh"
fi

# Try to show tree or fallback
if command -v tree >/dev/null 2>&1; then
  echo
  info "Project layout:"
  tree -a -L 2 "$PROJECT_DIR"
else
  echo
  info "Project contents:"
  ls -la
fi
