#!/usr/bin/env bash
# SessionStart hook for claude-chroma plugin
# Automatically sets up ChromaDB MCP server if not configured
# Non-destructive: safely merges with existing CLAUDE.md and settings.local.json

set -euo pipefail

# Get current working directory (project root)
PROJECT_ROOT="${PWD}"
CHROMA_DIR="${PROJECT_ROOT}/.chroma"
MCP_CONFIG="${PROJECT_ROOT}/.mcp.json"

# ==============================================================================
# Detection Functions
# ==============================================================================

detect_chromadb_in_claudemd() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"

    [ ! -f "$claudemd" ] && return 1

    # Check for ChromaDB markers
    if grep -q "## 🧠 Project Memory (Chroma)" "$claudemd" 2>/dev/null || \
       grep -q "mcp__chroma__chroma_create_collection" "$claudemd" 2>/dev/null || \
       grep -q "ChromaDB Plugin Configuration" "$claudemd" 2>/dev/null; then
        return 0  # ChromaDB section exists
    fi

    return 1  # No ChromaDB section found
}

detect_chromadb_in_settings() {
    local settings_path="${PROJECT_ROOT}/.claude/settings.local.json"

    [ ! -f "$settings_path" ] && return 1

    # Check if chroma is configured
    if grep -q '"chroma"' "$settings_path" 2>/dev/null && \
       grep -q '"enabledMcpjsonServers"' "$settings_path" 2>/dev/null; then
        return 0  # ChromaDB configured
    fi

    return 1  # ChromaDB not configured
}

# Function to check if ChromaDB is already configured
is_chromadb_configured() {
    # Check if .chroma directory exists
    if [ ! -d "$CHROMA_DIR" ]; then
        return 1
    fi

    # Check if .mcp.json exists and has chroma server configured
    if [ -f "$MCP_CONFIG" ]; then
        if grep -q '"chroma"' "$MCP_CONFIG" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

# ==============================================================================
# Path Update Detection (for when user moves project folder)
# ==============================================================================

needs_path_update() {
    # Only check if .mcp.json exists
    [ ! -f "$MCP_CONFIG" ] && return 1

    # Extract current data-dir path from .mcp.json
    local current_path=$(python3 -c "
import json
import sys
try:
    with open('$MCP_CONFIG', 'r') as f:
        config = json.load(f)
    chroma = config.get('mcpServers', {}).get('chroma', {})
    args = chroma.get('args', [])
    for i, arg in enumerate(args):
        if arg == '--data-dir' and i+1 < len(args):
            print(args[i+1])
            sys.exit(0)
except:
    pass
" 2>/dev/null)

    # Check if path exists and matches current expected path
    if [ -n "$current_path" ] && [ "$current_path" != "$CHROMA_DIR" ]; then
        # Only update if path was project-relative (ends with /.chroma)
        if [[ "$current_path" == *"/.chroma" ]]; then
            return 0  # Path mismatch detected, needs update
        fi
    fi

    return 1  # No update needed
}

update_mcp_path() {
    # Extract old path for display
    local old_path=$(python3 -c "
import json
import sys
try:
    with open('$MCP_CONFIG', 'r') as f:
        config = json.load(f)
    chroma = config.get('mcpServers', {}).get('chroma', {})
    args = chroma.get('args', [])
    for i, arg in enumerate(args):
        if arg == '--data-dir' and i+1 < len(args):
            print(args[i+1])
            sys.exit(0)
except:
    pass
" 2>/dev/null)

    echo "📍 Project path change detected:"
    echo "   Old: $old_path"
    echo "   New: $CHROMA_DIR"

    # Create backup
    local backup_path="${MCP_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$MCP_CONFIG" "$backup_path"
    echo "   📦 Backup created: $(basename "$backup_path")"

    # Update path using Python
    python3 -c "
import json
with open('$MCP_CONFIG', 'r') as f:
    config = json.load(f)

# Update data-dir argument
if 'mcpServers' in config and 'chroma' in config['mcpServers']:
    args = config['mcpServers']['chroma'].get('args', [])
    for i, arg in enumerate(args):
        if arg == '--data-dir' and i+1 < len(args):
            args[i+1] = '$CHROMA_DIR'
            break
    config['mcpServers']['chroma']['args'] = args

with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null

    echo "   ✅ Updated .mcp.json with new path"
    echo "   ⚠️  IMPORTANT: Restart Claude Code to apply changes"
    echo ""
}

# ==============================================================================
# .mcp.json Setup (existing logic - already works well)
# ==============================================================================

setup_mcp_json() {
    # Create or update .mcp.json
    if [ -f "$MCP_CONFIG" ]; then
        # Merge with existing config
        if grep -q '"mcpServers"' "$MCP_CONFIG"; then
            # Add chroma server to existing mcpServers using Python
            python3 -c "
import json
with open('$MCP_CONFIG', 'r') as f:
    config = json.load(f)
if 'mcpServers' not in config:
    config['mcpServers'] = {}
config['mcpServers']['chroma'] = {
    'type': 'stdio',
    'command': 'uvx',
    'args': ['-qq', 'chroma-mcp', '--client-type', 'persistent', '--data-dir', '$CHROMA_DIR'],
    'env': {
        'ANONYMIZED_TELEMETRY': 'FALSE',
        'PYTHONUNBUFFERED': '1',
        'TOKENIZERS_PARALLELISM': 'False',
        'CHROMA_SERVER_KEEP_ALIVE': '0',
        'CHROMA_CLIENT_TIMEOUT': '0'
    },
    'initializationOptions': {'timeout': 0, 'keepAlive': True, 'retryAttempts': 5}
}
with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || {
                # Python failed, create simple config
                cat > "$MCP_CONFIG" <<EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", "$CHROMA_DIR"],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {"timeout": 0, "keepAlive": true, "retryAttempts": 5}
    }
  }
}
EOF
            }
        else
            # No mcpServers key, create from scratch
            cat > "$MCP_CONFIG" <<EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", "$CHROMA_DIR"],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {"timeout": 0, "keepAlive": true, "retryAttempts": 5}
    }
  }
}
EOF
        fi
    else
        # Create new .mcp.json
        cat > "$MCP_CONFIG" <<EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", "$CHROMA_DIR"],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {"timeout": 0, "keepAlive": true, "retryAttempts": 5}
    }
  }
}
EOF
    fi
}

# ==============================================================================
# CLAUDE.md Merge Logic
# ==============================================================================

merge_claudemd_chromadb() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"

    # If file doesn't exist, create from template
    if [ ! -f "$claudemd" ]; then
        create_claudemd_from_template
        return 0
    fi

    # Detect if ChromaDB already configured
    if detect_chromadb_in_claudemd; then
        echo "   ℹ️  CLAUDE.md already has ChromaDB configuration"
        return 0
    fi

    # Create backup before modification
    local backup_path="${claudemd}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$claudemd" "$backup_path"
    echo "   📦 Backup created: $(basename "$backup_path")"

    # Append ChromaDB section with clear marker
    cat >> "$claudemd" << 'CHROMADB_SECTION'

# ═══════════════════════════════════════════════════════════
# ChromaDB Plugin Configuration (auto-added by claude-chroma)
# ═══════════════════════════════════════════════════════════

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query (start with 5; escalate only if <3 strong hits):
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

## 🔍 Retrieval Checklist Before Coding
1. Query Chroma for related memories.
2. Check repo files that match the task.
3. List open PRs or issues that touch the same area.
4. Only then propose changes.

## 📝 Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, pause and check:
- Did I discover new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve tricky problems or learn about architecture?

If yes → Log memory IMMEDIATELY using the schema above.

**During long sessions (>10 interactions)**:
- Stop and review: Have I logged recent learnings?
- Check for unrecorded decisions or fixes
- Remember: Each memory helps future sessions

## ⚡ ChromaDB Activation
At session start, after reading this file:
- Query existing memories: `mcp__chroma__chroma_query_documents`
- Announce: **Contract loaded. Using Chroma project_memory.**

CHROMADB_SECTION

    echo "   ✅ Appended ChromaDB configuration to CLAUDE.md"
}

create_claudemd_from_template() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"

    cat > "$claudemd" << 'CLAUDEMD_FULL'
# CLAUDE.md — Project Memory Contract

**Purpose**: Follow this in every session for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query (start with 5; escalate only if <3 strong hits):
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

## 🔍 Retrieval Checklist Before Coding
1. Query Chroma for related memories.
2. Check repo files that match the task.
3. List open PRs or issues that touch the same area.
4. Only then propose changes.

## 📝 Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, pause and check:
- Did I discover new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve tricky problems or learn about architecture?

If yes → Log memory IMMEDIATELY using the schema above.

**During long sessions (>10 interactions)**:
- Stop and review: Have I logged recent learnings?
- Check for unrecorded decisions or fixes
- Remember: Each memory helps future sessions

## ⚡ Activation
Read this file at session start.
Announce: **Contract loaded. Using Chroma project_memory.**

## 🧹 Session Hygiene
Prune to last 20 turns if context gets heavy. Save long outputs in `./backups/` and echo paths.

## 📁 Output Policy
For code, return unified diff or patchable files. For scripts, include exact commands and paths.

## 🛡️ Safety
No secrets in `.chroma` or transcripts. Respect rate limits. Propose batching if needed.
CLAUDEMD_FULL

    echo "   ✅ Created CLAUDE.md from template"
}

# ==============================================================================
# settings.local.json Merge Logic
# ==============================================================================

merge_settings_json() {
    local settings_path="${PROJECT_ROOT}/.claude/settings.local.json"

    # Ensure .claude directory exists
    mkdir -p "${PROJECT_ROOT}/.claude"

    # If doesn't exist, create from template
    if [ ! -f "$settings_path" ]; then
        create_settings_from_template "$settings_path"
        return 0
    fi

    # Detect if ChromaDB already configured
    if detect_chromadb_in_settings; then
        echo "   ℹ️  settings.local.json already has ChromaDB configuration"
        return 0
    fi

    # Merge using Python (pass settings_path as environment variable)
    SETTINGS_PATH="$settings_path" python3 <<'PYTHON_MERGE'
import json
import sys
import os
from datetime import datetime
import shutil

settings_path = os.environ['SETTINGS_PATH']

try:
    # Load existing settings
    with open(settings_path, 'r') as f:
        settings = json.load(f)

    modified = False

    # 1. Merge enabledMcpjsonServers
    if 'enabledMcpjsonServers' not in settings:
        settings['enabledMcpjsonServers'] = []
        modified = True

    if 'chroma' not in settings['enabledMcpjsonServers']:
        settings['enabledMcpjsonServers'].append('chroma')
        modified = True

    # 2. Merge mcpServers.chroma config
    if 'mcpServers' not in settings:
        settings['mcpServers'] = {}
        modified = True

    if 'chroma' not in settings['mcpServers']:
        settings['mcpServers']['chroma'] = {
            'alwaysAllow': [
                'chroma_list_collections',
                'chroma_create_collection',
                'chroma_add_documents',
                'chroma_query_documents',
                'chroma_get_documents'
            ]
        }
        modified = True

    # 3. Merge instructions array
    chromadb_instructions = [
        'IMPORTANT: This project uses ChromaDB for persistent memory',
        'Every 5 interactions, check if you have logged recent learnings',
        'After solving problems or making decisions, immediately log to ChromaDB',
        'Use mcp__chroma__chroma_add_documents to preserve discoveries',
        'Query existing memories at session start with mcp__chroma__chroma_query_documents',
        'Each memory should be under 300 chars with appropriate metadata',
        'Log architecture decisions, user preferences, fixes, and patterns'
    ]

    if 'instructions' not in settings:
        settings['instructions'] = []
        modified = True

    # Add ChromaDB instructions if not already present (fuzzy match)
    for instruction in chromadb_instructions:
        found = False
        for existing in settings.get('instructions', []):
            # Simple fuzzy match
            if 'ChromaDB' in instruction and 'ChromaDB' in existing:
                found = True
                break
            elif 'logged recent learnings' in instruction and 'logged recent learnings' in existing:
                found = True
                break
            elif 'mcp__chroma__chroma_add_documents' in instruction and 'mcp__chroma__chroma_add_documents' in existing:
                found = True
                break

        if not found:
            settings['instructions'].append(instruction)
            modified = True

    if modified:
        # Create backup
        backup_path = f"{settings_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(settings_path, backup_path)
        print(f"   📦 Backup created: {backup_path.split('/')[-1]}", file=sys.stderr)

        # Write merged settings
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)

        print("   ✅ Merged ChromaDB config into settings.local.json", file=sys.stderr)
    else:
        print("   ℹ️  settings.local.json unchanged (already configured)", file=sys.stderr)

except Exception as e:
    print(f"ERROR:{str(e)}", file=sys.stderr)
    sys.exit(1)
PYTHON_MERGE

    if [ $? -ne 0 ]; then
        echo "   ⚠️  Failed to merge settings.local.json (Python error)"
        echo "   → Manual merge required"
        return 1
    fi
}

create_settings_from_template() {
    local settings_path="$1"

    cat > "$settings_path" << 'SETTINGS_TEMPLATE'
{
  "enabledMcpjsonServers": [
    "chroma"
  ],
  "mcpServers": {
    "chroma": {
      "alwaysAllow": [
        "chroma_list_collections",
        "chroma_create_collection",
        "chroma_add_documents",
        "chroma_query_documents",
        "chroma_get_documents"
      ]
    }
  },
  "instructions": [
    "IMPORTANT: This project uses ChromaDB for persistent memory",
    "Every 5 interactions, check if you have logged recent learnings",
    "After solving problems or making decisions, immediately log to ChromaDB",
    "Use mcp__chroma__chroma_add_documents to preserve discoveries",
    "Query existing memories at session start with mcp__chroma__chroma_query_documents",
    "Each memory should be under 300 chars with appropriate metadata",
    "Log architecture decisions, user preferences, fixes, and patterns"
  ]
}
SETTINGS_TEMPLATE

    echo "   ✅ Created settings.local.json from template"
}

# ==============================================================================
# Main Logic
# ==============================================================================

# Track if anything was modified
MODIFIED=false

# 0. Check for path update needed (project was moved)
if needs_path_update; then
    update_mcp_path
    MODIFIED=true
fi

# 1. Check and setup .chroma directory if needed
if [ ! -d "$CHROMA_DIR" ]; then
    mkdir -p "$CHROMA_DIR"
    MODIFIED=true
fi

# 2. Check and setup .mcp.json if needed
if ! is_chromadb_configured; then
    if [ "$MODIFIED" = false ]; then
        echo "🔧 Setting up ChromaDB MCP server..."
    fi
    setup_mcp_json
    MODIFIED=true
fi

# 3. Check and setup/merge CLAUDE.md (always run, it handles detection internally)
if ! detect_chromadb_in_claudemd; then
    if [ "$MODIFIED" = false ]; then
        echo "🔧 Configuring ChromaDB for existing project..."
    fi
    echo ""
    echo "📝 Configuring CLAUDE.md..."
    merge_claudemd_chromadb
    MODIFIED=true
fi

# 4. Check and setup/merge settings.local.json (always run, it handles detection internally)
if ! detect_chromadb_in_settings; then
    if [ "$MODIFIED" = false ]; then
        echo "🔧 Configuring ChromaDB for existing project..."
    fi
    echo ""
    echo "⚙️  Configuring settings.local.json..."
    merge_settings_json
    MODIFIED=true
fi

# Final output if anything was modified
if [ "$MODIFIED" = true ]; then
    echo ""
    echo "✅ ChromaDB configured successfully!"
    echo "   Data directory: $CHROMA_DIR"
    echo "   MCP config: $MCP_CONFIG"
    echo "   Claude config: ${PROJECT_ROOT}/CLAUDE.md"
    echo "   Settings: ${PROJECT_ROOT}/.claude/settings.local.json"
    echo ""
    echo "📝 CLAUDE.md instructs Claude to use ChromaDB for project memory."
    echo "   Collection: project_memory"
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code to activate the ChromaDB MCP server."
    echo ""
    echo "After restart, you can use /chroma:validate, /chroma:migrate, and /chroma:stats commands."
fi

exit 0
