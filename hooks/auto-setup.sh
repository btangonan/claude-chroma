#!/usr/bin/env bash
# SessionStart hook for claude-chroma plugin
# Automatically sets up ChromaDB MCP server if not configured

set -euo pipefail

# Get current working directory (project root)
PROJECT_ROOT="${PWD}"
CHROMA_DIR="${PROJECT_ROOT}/.chroma"
MCP_CONFIG="${PROJECT_ROOT}/.mcp.json"

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

# Function to setup ChromaDB
setup_chromadb() {
    echo "🔧 ChromaDB not configured. Setting up automatically..."

    # Create .chroma directory
    mkdir -p "$CHROMA_DIR"

    # Create or update .mcp.json
    if [ -f "$MCP_CONFIG" ]; then
        # Merge with existing config
        # Check if mcpServers key exists
        if grep -q '"mcpServers"' "$MCP_CONFIG"; then
            # Add chroma server to existing mcpServers
            # Use python to merge JSON properly
            python3 -c "
import json
import sys

with open('$MCP_CONFIG', 'r') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['chroma'] = {
    'type': 'stdio',
    'command': 'uvx',
    'args': [
        '-qq',
        'chroma-mcp',
        '--client-type',
        'persistent',
        '--data-dir',
        '$CHROMA_DIR'
    ],
    'env': {
        'ANONYMIZED_TELEMETRY': 'FALSE',
        'PYTHONUNBUFFERED': '1',
        'TOKENIZERS_PARALLELISM': 'False',
        'CHROMA_SERVER_KEEP_ALIVE': '0',
        'CHROMA_CLIENT_TIMEOUT': '0'
    },
    'initializationOptions': {
        'timeout': 0,
        'keepAlive': True,
        'retryAttempts': 5
    }
}

with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || {
                # Python failed, create simple config
                cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "-qq",
        "chroma-mcp",
        "--client-type",
        "persistent",
        "--data-dir",
        "${CHROMA_DIR}"
      ],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {
        "timeout": 0,
        "keepAlive": true,
        "retryAttempts": 5
      }
    }
  }
}
EOF
            }
        else
            # No mcpServers key, create from scratch
            cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "-qq",
        "chroma-mcp",
        "--client-type",
        "persistent",
        "--data-dir",
        "$CHROMA_DIR"
      ],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {
        "timeout": 0,
        "keepAlive": true,
        "retryAttempts": 5
      }
    }
  }
}
EOF
        fi
    else
        # Create new .mcp.json
        cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "chroma": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "-qq",
        "chroma-mcp",
        "--client-type",
        "persistent",
        "--data-dir",
        "$CHROMA_DIR"
      ],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "False",
        "CHROMA_SERVER_KEEP_ALIVE": "0",
        "CHROMA_CLIENT_TIMEOUT": "0"
      },
      "initializationOptions": {
        "timeout": 0,
        "keepAlive": true,
        "retryAttempts": 5
      }
    }
  }
}
EOF
    fi

    # Create .claude directory structure
    mkdir -p "${PROJECT_ROOT}/.claude"

    # Create CLAUDE.md if it doesn't exist
    if [ ! -f "${PROJECT_ROOT}/.claude/CLAUDE.md" ]; then
        cat > "${PROJECT_ROOT}/.claude/CLAUDE.md" << 'CLAUDEMD'
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

## ⚡ Activation
Read this file at session start.
Announce: **Contract loaded. Using Chroma project_memory.**

## 🧹 Session Hygiene
Prune to last 20 turns if context gets heavy. Save long outputs in `./backups/` and echo paths.

## 📁 Output Policy
For code, return unified diff or patchable files. For scripts, include exact commands and paths.

## 🛡️ Safety
No secrets in `.chroma` or transcripts. Respect rate limits. Propose batching if needed.
CLAUDEMD
    fi

    # Create settings.local.json if it doesn't exist
    if [ ! -f "${PROJECT_ROOT}/.claude/settings.local.json" ]; then
        cat > "${PROJECT_ROOT}/.claude/settings.local.json" << 'SETTINGS'
{
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
  }
}
SETTINGS
    fi

    echo "✅ ChromaDB configured successfully!"
    echo "   Data directory: $CHROMA_DIR"
    echo "   MCP config: $MCP_CONFIG"
    echo "   Claude config: ${PROJECT_ROOT}/.claude/CLAUDE.md"
    echo "   Settings: ${PROJECT_ROOT}/.claude/settings.local.json"
    echo ""
    echo "📝 CLAUDE.md instructs Claude to use ChromaDB for project memory."
    echo "   Collection: project_memory"
    echo ""
    echo "You can now use /chroma:validate, /chroma:migrate, and /chroma:stats commands."
}

# Main logic
if is_chromadb_configured; then
    # Already configured, exit silently
    exit 0
else
    # Not configured, run setup
    setup_chromadb
fi

exit 0
