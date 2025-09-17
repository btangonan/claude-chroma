#!/bin/bash
# Streamlined ChromaDB setup for Claude projects
# Version 3.0 - Simplified, auto-initialization, Python optional (for JSON merge)

set -euo pipefail

# Non-interactive mode support
YES=${CHROMA_SETUP_YES:-0}
confirm() {
    if [ "$YES" = "1" ]; then
        REPLY="y"
        return 0
    else
        read -p "$1 (y/n): " -n 1 -r
        echo
    fi
}

# Cleanup on exit (rollback support)
CLEANUP_FILES=()
trap cleanup_on_exit EXIT
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ ${#CLEANUP_FILES[@]} -gt 0 ]; then
        print_error "Setup failed. Rolling back changes..."
        for file in "${CLEANUP_FILES[@]}"; do
            if [ -f "$file.backup" ]; then
                mv "$file.backup" "$file" 2>/dev/null
                print_info "Restored: $file"
            fi
        done
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Prerequisite checks
print_header "🔍 Checking Prerequisites"

# Version pin for consistency
CHROMA_MCP_VERSION="chroma-mcp==0.2.0"

# Check for jq (preferred for JSON operations)
HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
    print_status "jq found - will use for JSON operations"
else
    print_info "jq not found - will fallback to Python if available"
fi

# Check for Python3 (fallback for JSON operations)
HAS_PYTHON=false
if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON=true
    print_status "Python3 found - available as fallback"
fi

if [ "$HAS_JQ" = "false" ] && [ "$HAS_PYTHON" = "false" ]; then
    print_error "Neither jq nor Python3 found. Need one for JSON operations."
    print_info "Install jq: brew install jq (Mac) or apt-get install jq (Linux)"
    exit 1
fi

# Check for uvx (required for ChromaDB MCP server)
if ! command -v uvx >/dev/null 2>&1; then
    print_error "uvx is not installed. ChromaDB MCP server requires uvx."
    echo ""
    print_info "To install uvx, choose one of these options:"
    echo ""
    echo "  Option 1: Using pip (recommended):"
    echo "    pip install --user uv"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "  Option 2: Using pipx:"
    echo "    pipx install uv"
    echo ""
    echo "  Option 3: Using Homebrew (macOS/Linux):"
    echo "    brew install uv"
    echo ""
    echo "  Option 4: Direct download:"
    echo "    curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo ""
    print_info "After installing, restart your terminal and run this script again."
    echo ""

    # Ask if they want to try pip installation
    confirm "Would you like to try installing with pip now?"
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        print_info "Installing uv with pip..."
        if pip install --user uv || pip3 install --user uv; then
            # Add to PATH for current session and persist
            export PATH="$HOME/.local/bin:$PATH"

            # Add to shell config for persistence
            SHELL_CONFIG="$HOME/.bashrc"
            [ -f "$HOME/.zshrc" ] && SHELL_CONFIG="$HOME/.zshrc"
            if ! grep -q "HOME/.local/bin" "$SHELL_CONFIG" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
                print_info "Added PATH to $SHELL_CONFIG"
            fi

            # Check if it worked
            if command -v uvx >/dev/null 2>&1; then
                print_status "uvx installed successfully!"
                UVX_PATH=$(command -v uvx)
            else
                print_error "uvx installed but not in PATH. Restart terminal and try again."
                exit 1
            fi
        else
            print_error "Failed to install uv. Please try one of the other methods above."
            exit 1
        fi
    else
        exit 1
    fi
else
    UVX_PATH=$(command -v uvx)
    print_status "uvx found at: $UVX_PATH"
fi

# Check for Claude CLI (optional)
if command -v claude >/dev/null 2>&1; then
    print_status "claude CLI found"
else
    print_info "'claude' CLI not found. Proceeding; config will still be written."
    print_info "Install later if needed: https://claude.ai/download"
fi

# Test that uvx can run chroma-mcp (with version pin)
print_info "Testing ChromaDB MCP server availability..."
if "$UVX_PATH" -qq $CHROMA_MCP_VERSION --help >/dev/null 2>&1; then
    print_status "ChromaDB MCP server v0.2.0 is available"
else
    print_info "Installing ChromaDB MCP server v0.2.0..."
    if ! "$UVX_PATH" install $CHROMA_MCP_VERSION; then
        print_error "Cannot install ChromaDB MCP server"
        print_info "Try manually: $UVX_PATH install $CHROMA_MCP_VERSION"
        exit 1
    fi
    print_status "ChromaDB MCP server installed"
fi

# Get project name and path
if [ -z "${1:-}" ]; then
    if [ "$YES" = "1" ]; then
        PROJECT_NAME=""
    else
        read -p "Enter project name (or press Enter for current directory): " PROJECT_NAME
    fi
else
    PROJECT_NAME="$1"
fi

# Check if PROJECT_NAME is empty (user wants to use current directory)
if [ -z "$PROJECT_NAME" ]; then
    # Use current directory for existing project
    PROJECT_DIR="$(pwd)"
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
    print_header "🚀 Setting up ChromaDB in current directory: $PROJECT_NAME"
    print_info "Using existing project at: $PROJECT_DIR"
else
    # Create new project or navigate to specified project
    if [ -z "${2:-}" ]; then
        DEFAULT_PATH="/Users/bradleytangonan/Desktop/my apps"
        if [ "$YES" = "1" ]; then
            PROJECT_PATH="$DEFAULT_PATH"
        else
            read -p "Enter project path (default: $DEFAULT_PATH): " PROJECT_PATH
            PROJECT_PATH="${PROJECT_PATH:-$DEFAULT_PATH}"
        fi
    else
        PROJECT_PATH="$2"
    fi

    PROJECT_DIR="$PROJECT_PATH/$PROJECT_NAME"
    print_header "🚀 Setting up ChromaDB for: $PROJECT_NAME"

    # Step 1: Create project directory
    print_info "Creating project directory..."
    if [ -d "$PROJECT_DIR" ]; then
        print_info "Directory exists: $PROJECT_DIR"
        confirm "Add ChromaDB to existing project?"
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        mkdir -p "$PROJECT_DIR"
        print_status "Created directory: $PROJECT_DIR"
    fi

    cd "$PROJECT_DIR"
fi

# Step 2: Create minimal directory structure
print_info "Creating directory structure..."
mkdir -p .chroma
mkdir -p .claude
mkdir -p claudedocs
print_status "Created directory structure"

# Step 3: Create Claude settings with MCP server
print_info "Creating Claude configuration..."

# Handle existing settings.local.json
if [ -f ".claude/settings.local.json" ]; then
    print_info "Existing settings.local.json found"

    # Check if it already has chroma MCP server
    if grep -q '"chroma"' .claude/settings.local.json 2>/dev/null; then
        echo -e "${YELLOW}ChromaDB MCP server already configured in settings${NC}"
        confirm "Overwrite existing ChromaDB config?"
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing ChromaDB configuration"
            SKIP_SETTINGS=true
        else
            BACKUP_NAME=".claude/settings.local.json.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up existing settings to $BACKUP_NAME"
            cp .claude/settings.local.json "$BACKUP_NAME"
            SKIP_SETTINGS=false
        fi
    else
        # Has settings but no chroma - needs merge
        echo -e "${YELLOW}Existing settings found without ChromaDB${NC}"
        echo "Options:"
        echo "  1) Merge ChromaDB into existing settings (recommended)"
        echo "  2) Backup and replace with new settings"
        if [ "$YES" = "1" ]; then
            MERGE_OPTION="1"
            print_info "Auto-selecting merge option (1)"
        else
            read -p "Choose option (1-2): " -n 1 -r MERGE_OPTION
            echo
        fi

        if [ "$MERGE_OPTION" = "1" ]; then
            print_info "Merging ChromaDB into existing settings"
            # Create backup first
            BACKUP_NAME=".claude/settings.local.json.backup.$(date +%Y%m%d_%H%M%S)"
            cp .claude/settings.local.json "$BACKUP_NAME"
            CLEANUP_FILES+=(".claude/settings.local.json")

            if [ "$HAS_JQ" = "true" ]; then
                # Use jq for robust JSON merging
                TEMP_FILE=$(mktemp)
                jq --arg uvx "$UVX_PATH" --arg dir "$(pwd)/.chroma" '
                  .mcpServers.chroma = {
                    "type": "stdio",
                    "command": $uvx,
                    "args": ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", $dir],
                    "env": {
                      "ANONYMIZED_TELEMETRY": "FALSE",
                      "PYTHONUNBUFFERED": "1",
                      "TOKENIZERS_PARALLELISM": "False"
                    }
                  } |
                  .instructions = (.instructions // []) + [
                    "After any successful fix, decision, gotcha, or preference, log a memory to Chroma:",
                    "Use mcp__chroma__chroma_add_documents with:",
                    "- collection_name: '"'"'project_memory'"'"' (must exist, create first if needed)",
                    "- documents: [\"1-2 sentences, <300 chars\"]",
                    "- metadatas: [{\"type\":\"decision|fix|tip\",\"tags\":\"k1,k2\",\"source\":\"file:line\"}]",
                    "- ids: [\"stable-id-string\"]",
                    "Always confirm: '"'"'Logged memory: {id}'"'"'"
                  ] | .instructions |= unique
                ' .claude/settings.local.json > "$TEMP_FILE" && mv "$TEMP_FILE" .claude/settings.local.json
                print_status "Merged ChromaDB using jq"
            elif [ "$HAS_PYTHON" = "true" ]; then
                # Fallback to Python
                python3 -c "
import json
with open('.claude/settings.local.json', 'r') as f:
    data = json.load(f)
if 'mcpServers' not in data:
    data['mcpServers'] = {}
data['mcpServers']['chroma'] = {
    'type': 'stdio',
    'command': '$UVX_PATH',
    'args': ['-qq','chroma-mcp','--client-type','persistent','--data-dir','$(pwd)/.chroma'],
    'env': {
        'ANONYMIZED_TELEMETRY': 'FALSE',
        'PYTHONUNBUFFERED': '1',
        'TOKENIZERS_PARALLELISM': 'False'
    }
}
# Add same instructions contract if missing
data.setdefault('instructions', [])
instr = [
  'After any successful fix, decision, gotcha, or preference, log a memory to Chroma:',
  'Use mcp__chroma__chroma_add_documents with:',
  \"- collection_name: 'project_memory' (must exist, create first if needed)\",
  '- documents: [\"1-2 sentences, <300 chars\"]',
  '- metadatas: [{\"type\":\"decision|fix|tip\",\"tags\":\"k1,k2\",\"source\":\"file:line\"}]',
  '- ids: [\"stable-id-string\"]',
  \"Always confirm: 'Logged memory: {id}'\"
]
for s in instr:
  if s not in data['instructions']:
    data['instructions'].append(s)
with open('.claude/settings.local.json', 'w') as f:
    json.dump(data, f, indent=2)
"
                print_status "Merged ChromaDB using Python"
            else
                print_error "Neither jq nor Python available for merge. Falling back to replace."
                SKIP_SETTINGS=false
            fi
            SKIP_SETTINGS=true
        else
            BACKUP_NAME=".claude/settings.local.json.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up to $BACKUP_NAME"
            cp .claude/settings.local.json "$BACKUP_NAME"
            SKIP_SETTINGS=false
        fi
    fi
else
    SKIP_SETTINGS=false
fi

if [ "$SKIP_SETTINGS" != "true" ]; then
    # Create ChromaDB MCP configuration with environment variables:
    # ANONYMIZED_TELEMETRY=FALSE - Disables ChromaDB usage analytics
    # PYTHONUNBUFFERED=1 - Forces unbuffered output for stdio protocol
    # TOKENIZERS_PARALLELISM=false - Prevents tokenizer threading issues
    cat > .claude/settings.local.json <<EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "$UVX_PATH",
      "args": [
        "-qq",
        "chroma-mcp",
        "--client-type",
        "persistent",
        "--data-dir",
        "$(pwd)/.chroma"
      ],
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
    "- documents: [\"1-2 sentences, <300 chars\"]",
    "- metadatas: [{\"type\":\"decision|fix|tip\",\"tags\":\"k1,k2\",\"source\":\"file:line\"}]",
    "- ids: [\"stable-id-string\"]",
    "Always confirm: 'Logged memory: {id}'"
  ]
}
EOF
    print_status "Created .claude/settings.local.json with instructions"
fi

# Step 4: Create enhanced CLAUDE.md
if [ ! -f "CLAUDE.md" ]; then
    # Create new CLAUDE.md
    cat > CLAUDE.md <<'EOF'
# CLAUDE.md — Project Contract

**Purpose**: Follow this in every chat for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

## 🧠 Project Memory (Chroma)

Use server \`chroma\`. Collection \`project_memory\`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: \`{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }\`
- **ids**: stable string if updating the same fact.

Always reply after writes: **Logged memory: <id>**.

Before proposing work, query Chroma for prior facts.

### Chroma Calls
\`\`\`javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query:
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
\`\`\`

## 🧩 Deterministic Reasoning

Default: concise, action oriented.

Auto-propose sequential-thinking when a task has 3+ dependent steps or multiple tradeoffs. Enable for one turn, then disable.

If I say "reason stepwise", enable for one turn, then disable.

## 🌐 Browser Automation

Use playwright to load pages, scrape DOM, run checks, and export screenshots or PDFs.

Save artifacts to \`./backups/\` with timestamped filenames.

Summarize results and list file paths.

## 🐙 GitHub

Use github to fetch files, list and inspect issues and PRs, and draft PR comments.

Never push or merge without explicit approval.

Always show diffs, file paths, or PR numbers before proposing changes.

## 🔧 Additional MCP Servers

- **context7**: library docs search. Example: \`/docs react hooks\`
- **magic**: UI components and small React blocks. Example: \`/ui button\`
- **sequential-thinking**: complex planning mode as above

## 🛠️ Tool Selection Matrix

| Task | Tool |
|------|------|
| Multi-file edits | MultiEdit (if available). Otherwise propose a unified diff per file. |
| Pattern search in repo | Grep MCP (not shell grep). Return matches with file paths and line numbers. |
| UI snippet or component | Magic MCP. Return a self-contained file. |
| Complex analysis or planning | Sequential-thinking for one turn. |
| Docs or library behavior | context7 first. Quote relevant lines, then summarize. |
| Web page check or scrape | Playwright with artifacts saved to \`./backups/\`. |

If a listed tool is missing, state the exact server or tool name that is unavailable and ask to enable it.

## 📋 Spec & Planning (Lite)

For new features, run three phases:

1. \`/specify\` → user stories, functional requirements, acceptance tests
2. \`/plan\` → stack, architecture, constraints, performance and testing goals
3. \`/tasks\` → granular, test-first steps

Log key spec and plan decisions to Chroma as \`type:"decision"\` with tags.

## ✅ Quality Gates

- Every requirement is unambiguous, testable, and bounded
- Prefer tests and unified diffs over prose
- Mark uncertainty with \`[VERIFY]\` and propose checks
- Include simple performance budgets where relevant (e.g., search under 100ms at 10k rows)

## 🔄 Session Lifecycle

- **Start**: Query Chroma for context relevant to the task. List any matches you will rely on.
- **Work**: Log decisions and gotchas as they happen. Keep each memory under 300 chars.
- **Checkpoint**: Every 30 minutes or at a major milestone, summarize progress, open risks, and memories logged.
- **End**: Summarize changes, link artifacts in \`./backups/\`, and list all memories written.

## 🧹 Session Hygiene

- Do not compact long chats
- If context gets heavy, propose pruning to the last 20 turns and continue
- For long outputs, write files to \`./backups/\` and return paths

## 🔍 Retrieval Checklist Before Coding

1. Query Chroma for related memories
2. Check repo files that match the task
3. List open PRs or issues that touch the same area
4. Only then propose changes

## 🏷️ Memory Taxonomy

- **type**: \`decision\`, \`fix\`, \`tip\`, \`preference\`
- **tags**: short domain keywords (e.g., \`video,encode,preview\`)
- **id rule**: stable handle per fact (e.g., \`encode-preview-policy\`)

### Memory Examples
\`\`\`javascript
documents: ["Use NVENC for H.264 previews; fallback x264 if GPU is busy"]
metadatas: [{ "type":"tip","tags":"video,encode,preview","source":"PR#142" }]
ids: ["encode-preview-policy"]

documents: ["Adopt Conventional Commits and run tests on pre-push"]
metadatas: [{ "type":"decision","tags":"repo,workflow,testing","source":"spec" }]
ids: ["repo-commit-policy"]
\`\`\`

## 📁 Output Policy

- For code: return a unified diff or a patchable file set
- For scripts: include exact commands and paths
- Save long outputs in \`./backups/\`. Use readable names. Echo paths in the reply

## 🛡️ Safety

- No secrets in \`.chroma\` or transcripts
- Note licenses and third party terms when adding dependencies
- Respect rate limits. Propose batching if needed

## 🚀 Modes

**Small change**: Skip full spec. Still log key decisions. Still show diffs.

**Feature**: Run the three phases. Enforce quality gates.

## ⚡ Activation

Read this file at chat start.

Acknowledge: **Contract loaded. Using Chroma project_memory.**

If tools are missing, name them and stop before continuing.
EOF
    print_status "Created enhanced CLAUDE.md with complete project contract"
fi

# Step 5: Create .gitignore
print_info "Creating .gitignore..."
cat > .gitignore <<'EOF'
# ChromaDB local database
.chroma/
*.chroma

# Claude local settings (machine-specific; do NOT track)
.claude/settings.local.json

# Memory exports (optional - track for history)
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
EOF
print_status "Created .gitignore"

# Step 6: Create simple initialization instructions
print_info "Creating initialization instructions..."
cat > claudedocs/INIT_INSTRUCTIONS.md <<'EOF'
# ChromaDB Initialization

## Automatic Setup
When you start Claude in this project, it will:
1. Read CLAUDE.md
2. Check if ChromaDB collection exists
3. Create collection if needed
4. Start logging memories

## Manual Commands (if needed)

### Create Collection
```javascript
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }
```

### Test Collection
```javascript
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["test"],
  "n_results": 5
}
```

### Add Memory
```javascript
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Your memory text here"],
  "metadatas": [{
    "type": "tip",
    "tags": "relevant,tags",
    "source": "manual",
    "confidence": 0.8
  }],
  "ids": ["unique-id-001"]
}
```

## Starting Claude
From project root:
```bash
claude chat
```

Claude will automatically:
- Connect to .chroma database
- Initialize if needed
- Start logging memories
EOF
print_status "Created initialization instructions"

# Step 7: Create project launcher script
print_info "Creating project launcher script..."
cat > start-claude-chroma.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Check if config exists
if [[ ! -f ".claude/settings.local.json" ]]; then
    echo "❌ No Claude config found in this directory"
    echo "Run the ChromaDB setup script first"
    exit 1
fi

# Start Claude with ChromaDB MCP config
echo "🚀 Starting Claude with ChromaDB..."
exec claude chat --mcp-config .claude/settings.local.json "$@"
EOF
chmod +x start-claude-chroma.sh
print_status "Created start-claude-chroma.sh launcher"

# Step 8: Optional shell function setup
print_header "🚀 Optional: Smart Shell Function"

print_info "Would you like to add a global 'claude-chroma' function to your shell?"
echo ""
echo -e "${BLUE}This function will:${NC}"
echo "  ✅ Work from any directory in your project tree"
echo "  ✅ Auto-detect ChromaDB config files"
echo "  ✅ Fall back to regular Claude if no config found"
echo "  ✅ Pass through all Claude arguments"
echo ""
echo -e "${YELLOW}This will modify your shell configuration file${NC}"
if [ "$YES" = "1" ]; then
    SHELL_FUNCTION_REPLY="y"
    print_info "Auto-accepting shell function setup"
else
    read -p "Add smart shell function? (y/N): " -n 1 -r SHELL_FUNCTION_REPLY
    echo
fi

if [[ $SHELL_FUNCTION_REPLY =~ ^[Yy]$ ]]; then
    # Detect shell and config file
    detect_shell_config() {
        local shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
        case "$shell_name" in
            bash)
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    echo "$HOME/.bash_profile"
                else
                    echo "$HOME/.bashrc"
                fi
                ;;
            zsh) echo "$HOME/.zshrc" ;;
            fish) echo "$HOME/.config/fish/config.fish" ;;
            *) echo "$HOME/.profile" ;;
        esac
    }

    SHELL_CONFIG=$(detect_shell_config)
    SHELL_NAME=$(basename "$SHELL" 2>/dev/null || echo "bash")

    print_info "Detected shell: $SHELL_NAME"
    print_info "Config file: $SHELL_CONFIG"

    # Check if function already exists (more robust check)
    if [ -f "$SHELL_CONFIG" ] && grep -q "claude-chroma()\|function claude-chroma" "$SHELL_CONFIG" 2>/dev/null; then
        print_info "claude-chroma function already exists in $SHELL_CONFIG"
        echo -e "${YELLOW}Skipping shell function setup${NC}"
    else
        # Create backup
        if [ -f "$SHELL_CONFIG" ]; then
            cp "$SHELL_CONFIG" "$SHELL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backed up existing config"
        fi

        # Add function based on shell type
        if [ "$SHELL_NAME" = "fish" ]; then
            # Fish shell function
            cat >> "$SHELL_CONFIG" <<'FISH_EOF'

# ChromaDB Smart Function - Added by claude-chroma.sh
function claude-chroma --description "Start Claude with auto-detected ChromaDB config"
    set config_file ""
    set search_dir "$PWD"

    # Search upward for .claude/settings.local.json
    while test "$search_dir" != "/"
        if test -f "$search_dir/.claude/settings.local.json"
            set config_file "$search_dir/.claude/settings.local.json"
            break
        end
        set search_dir (dirname "$search_dir")
    end

    if test -n "$config_file"
        echo "Using ChromaDB config: $config_file"
        # Default to 'chat' if no subcommand provided
        if test (count $argv) -eq 0
            claude chat --mcp-config "$config_file"
        else
            claude --mcp-config "$config_file" $argv
        end
    else
        echo "No ChromaDB config found - using regular Claude"
        # Default to 'chat' if no subcommand provided
        if test (count $argv) -eq 0
            claude chat
        else
            claude $argv
        end
    end
end
FISH_EOF
        else
            # Bash/Zsh function
            cat >> "$SHELL_CONFIG" <<'BASH_EOF'

# ChromaDB Smart Function - Added by claude-chroma.sh
claude-chroma() {
    local config_file=""
    local search_dir="$PWD"

    # Search upward for .claude/settings.local.json
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/.claude/settings.local.json" ]]; then
            config_file="$search_dir/.claude/settings.local.json"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    if [[ -n "$config_file" ]]; then
        echo "Using ChromaDB config: $config_file"
        # Default to 'chat' if no arguments provided
        if [[ $# -eq 0 ]]; then
            claude chat --mcp-config "$config_file"
        else
            claude --mcp-config "$config_file" "$@"
        fi
    else
        echo "No ChromaDB config found - using regular Claude"
        # Default to 'chat' if no arguments provided
        if [[ $# -eq 0 ]]; then
            claude chat
        else
            claude "$@"
        fi
    fi
}
BASH_EOF
        fi

        print_status "Added claude-chroma function to $SHELL_CONFIG"

        # Test if function is available in current session
        if type claude-chroma >/dev/null 2>&1 || [[ "$SHELL_NAME" = "fish" ]]; then
            print_info "Function ready to use!"
        else
            print_info "Restart your terminal or run: source $SHELL_CONFIG"
        fi

        echo ""
        print_info "Usage:"
        echo "  claude-chroma          # Start Claude with auto-detected config"
        echo "  claude-chroma chat     # Start chat with ChromaDB"
        echo "  claude-chroma --help   # All Claude options work"
        echo ""
        print_info "To remove later:"
        echo "  Edit $SHELL_CONFIG and delete the ChromaDB Smart Function section"
    fi
else
    print_info "Skipping shell function setup"
    print_info "You can still use the project script: ./start-claude-chroma.sh"
fi

# Final summary
print_header "✨ Setup Complete!"

echo "Project configured at: $PROJECT_DIR"
echo ""
print_status "ChromaDB MCP server configured"
print_status "Auto-initialization configured in CLAUDE.md"
print_status "No Python dependencies required"
echo ""
print_info "Directory structure:"
if command -v tree >/dev/null 2>&1; then
    tree -a -L 2 "$PROJECT_DIR" 2>/dev/null
else
    ls -la "$PROJECT_DIR"
fi

echo ""
print_info "Next steps:"
echo "  1. cd \"$PROJECT_DIR\""
if [[ $SHELL_FUNCTION_REPLY =~ ^[Yy]$ ]] && [ -f "$SHELL_CONFIG" ] && ! grep -q "claude-chroma()\|function claude-chroma" "$SHELL_CONFIG" 2>/dev/null; then
    echo "  2. claude-chroma chat     # Use the smart function"
    echo "     OR: ./start-claude-chroma.sh  # Use project script"
else
    echo "  2. ./start-claude-chroma.sh  # Use project script"
    echo "     OR: claude --mcp-config .claude/settings.local.json chat"
fi
echo "  3. Claude will auto-initialize ChromaDB"
echo ""
print_info "The system will:"
echo "  • Auto-detect if collection exists"
echo "  • Auto-create collection if needed"
echo "  • Auto-log memories during work"
echo "  • Persist knowledge across sessions"
echo ""
print_status "Setup complete! No manual initialization needed."