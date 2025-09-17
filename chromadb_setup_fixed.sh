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

# Step 4: Create/Update CLAUDE.md with auto-initialization (idempotent)
print_info "Creating/updating CLAUDE.md with auto-initialization..."

# Insert or replace a tagged block so reruns don't duplicate
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
BEGIN_TAG="<!-- BEGIN:CHROMA-AUTOINIT -->"
END_TAG="<!-- END:CHROMA-AUTOINIT -->"
BLOCK="$BEGIN_TAG
## ChromaDB Memory System - AUTO-INITIALIZATION

At session start:
1) Try query. If collection missing, create it.

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

if [ -f "CLAUDE.md" ]; then
  if grep -q "$BEGIN_TAG" CLAUDE.md; then
    # Replace existing block
    awk -v b="$BEGIN_TAG" -v e="$END_TAG" -v r="$BLOCK" '
      BEGIN{p=1} $0~b{print r; p=0} p{print} $0~e{p=1; next}
    ' CLAUDE.md > CLAUDE.md.tmp && mv CLAUDE.md.tmp CLAUDE.md
    print_status "Updated existing ChromaDB section in CLAUDE.md"
  else
    # Append new block
    printf "\n%s\n" "$BLOCK" >> CLAUDE.md
    print_status "Added ChromaDB section to CLAUDE.md"
  fi
else
  # Create new file with block
  printf "%s\n" "$BLOCK" > CLAUDE.md
  print_status "Created CLAUDE.md with ChromaDB section"
fi

# Create new CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    # Create new CLAUDE.md
    cat > CLAUDE.md <<'EOF'
# CLAUDE.md — Project Configuration

**Acknowledgment**: Contract loaded. Initializing ChromaDB.

## ChromaDB Memory System - AUTO-INITIALIZATION

### Session Start Protocol
When this file is loaded, IMMEDIATELY:

1. **Test if collection exists** by listing:
\`\`\`javascript
mcp__chroma__chroma_list_collections
\`\`\`

2. **If project_memory not in list**, create it:
\`\`\`javascript
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }
\`\`\`

3. **Log initial memory** if collection was just created:
\`\`\`javascript
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Project initialized with ChromaDB memory system"],
  "metadatas": [{
    "type": "setup",
    "tags": "init,chroma",
    "source": "CLAUDE.md",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "confidence": 1.0
  }],
  "ids": ["init-001"]
}
\`\`\`

### Memory Schema
\`\`\`javascript
{
  "documents": ["Concise description <300 chars"],
  "metadatas": [{
    "type": "decision|fix|tip|pattern",
    "tags": "tag1,tag2",
    "source": "filename:line",
    "timestamp": "ISO8601",
    "confidence": 0.0-1.0
  }],
  "ids": ["type-component-YYYYMMDD-seq"]
}
\`\`\`

### Automatic Memory Logging
Log memories automatically when:
- ✅ Bug fixed → Log solution
- 🔧 Configuration changed → Log decision
- ⚡ Performance improved → Log optimization
- 🏗️ Architecture decision → Log pattern
- 📦 Dependencies changed → Log reasoning

### Memory Operations

**After each memory write**, confirm with:
\`\`\`
💾 Logged memory: {id}
\`\`\`

**Query relevant memories** before major changes:
\`\`\`javascript
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["relevant", "keywords"],
  "n_results": 10
}
\`\`\`

### Confidence Levels
- \`0.3-0.5\` = Hypothesis (untested)
- \`0.6-0.8\` = Validated (tested)
- \`0.9-1.0\` = Proven (production-verified)

## Project Rules
1. Keep memories concise (<300 chars)
2. Use consistent ID format
3. Update confidence as patterns prove reliable
4. Query before solving similar problems
5. Log both successes and failures

## Tool Preferences
- Multi-file edits → MultiEdit
- Search → Grep (not bash grep)
- File patterns → Glob (not find)

## Output Policy
- Concise responses
- Unified diffs
- No verbose explanations unless requested
EOF
    print_status "Created CLAUDE.md with auto-initialization"
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

# Step 7: Optional shell function setup
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

# ChromaDB Smart Function - Added by chromadb_setup_fixed.sh
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
        claude --mcp-config "$config_file" $argv
    else
        echo "No ChromaDB config found - using regular Claude"
        claude $argv
    end
end
FISH_EOF
        else
            # Bash/Zsh function
            cat >> "$SHELL_CONFIG" <<'BASH_EOF'

# ChromaDB Smart Function - Added by chromadb_setup_fixed.sh
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
        claude --mcp-config "$config_file" "$@"
    else
        echo "No ChromaDB config found - using regular Claude"
        claude "$@"
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