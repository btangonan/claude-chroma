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

    echo "✅ ChromaDB configured successfully!"
    echo "   Data directory: $CHROMA_DIR"
    echo "   MCP config: $MCP_CONFIG"
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
