#!/bin/bash

# ChromaDB Project Memory Setup Script
# Automated setup for Claude Desktop with persistent memory

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}       ChromaDB Project Memory Setup for Claude Desktop${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    OS="Mac";;
        Linux*)     OS="Linux";;
        MINGW*|CYGWIN*|MSYS*) OS="Windows";;
        *)          OS="Unknown";;
    esac
    echo "$OS"
}

# Function to get Claude config path
get_claude_config_path() {
    local os="$1"
    case "$os" in
        Mac)
            echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
            ;;
        Linux)
            echo "$HOME/.config/Claude/claude_desktop_config.json"
            ;;
        Windows)
            echo "$APPDATA/Claude/claude_desktop_config.json"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Step 1: Check Python
echo -e "${YELLOW}Step 1: Checking Python installation...${NC}"
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
else
    echo -e "${RED}❌ Python not found. Please install Python 3.8+ first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python found: $($PYTHON_CMD --version)${NC}\n"

# Step 2: Check/Install uvx
echo -e "${YELLOW}Step 2: Checking uvx installation...${NC}"
if ! command_exists uvx; then
    echo "Installing uvx..."
    if command_exists pip3; then
        pip3 install --user uvx
    elif command_exists pip; then
        pip install --user uvx
    else
        echo -e "${RED}❌ pip not found. Please install pip first.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ uvx is installed${NC}\n"

# Step 3: Install ChromaDB MCP Server
echo -e "${YELLOW}Step 3: Installing ChromaDB MCP Server...${NC}"
if uvx chroma-mcp --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ChromaDB MCP server already installed${NC}\n"
else
    echo "Installing chroma-mcp..."
    uvx install chroma-mcp
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ChromaDB MCP server installed successfully${NC}\n"
    else
        echo -e "${RED}❌ Failed to install ChromaDB MCP server${NC}"
        exit 1
    fi
fi

# Step 4: Configure Claude Desktop
echo -e "${YELLOW}Step 4: Configuring Claude Desktop...${NC}"
OS=$(detect_os)
CLAUDE_CONFIG=$(get_claude_config_path "$OS")

if [ -z "$CLAUDE_CONFIG" ]; then
    echo -e "${RED}❌ Could not determine Claude config path for $OS${NC}"
    echo "Please manually add ChromaDB configuration to your Claude Desktop config"
    exit 1
fi

# Create config directory if it doesn't exist
CONFIG_DIR=$(dirname "$CLAUDE_CONFIG")
mkdir -p "$CONFIG_DIR"

# Check if config exists and has chromadb configured
if [ -f "$CLAUDE_CONFIG" ]; then
    if grep -q '"chromadb"' "$CLAUDE_CONFIG"; then
        echo -e "${GREEN}✅ ChromaDB already configured in Claude Desktop${NC}\n"
    else
        echo "Adding ChromaDB to existing Claude config..."
        # Backup existing config
        cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

        # Add ChromaDB configuration using Python for proper JSON handling
        $PYTHON_CMD << EOF
import json
import sys

config_path = "$CLAUDE_CONFIG"

try:
    with open(config_path, 'r') as f:
        config = json.load(f)
except:
    config = {}

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['chromadb'] = {
    "command": "uvx",
    "args": ["-qq", "chroma-mcp", "--data-dir", "./.chroma"],
    "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "false"
    }
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print("✅ ChromaDB configuration added to Claude Desktop")
EOF
    fi
else
    echo "Creating new Claude Desktop config..."
    cat > "$CLAUDE_CONFIG" << 'EOF'
{
  "mcpServers": {
    "chromadb": {
      "command": "uvx",
      "args": ["-qq", "chroma-mcp", "--data-dir", "./.chroma"],
      "env": {
        "ANONYMIZED_TELEMETRY": "FALSE",
        "PYTHONUNBUFFERED": "1",
        "TOKENIZERS_PARALLELISM": "false"
      }
    }
  }
}
EOF
    echo -e "${GREEN}✅ Claude Desktop configuration created${NC}\n"
fi

# Step 5: Create .claude directory
echo -e "${YELLOW}Step 5: Setting up project structure...${NC}"
mkdir -p "$CLAUDE_DIR"
echo -e "${GREEN}✅ Created .claude directory${NC}\n"

# Step 6: Copy template files
echo -e "${YELLOW}Step 6: Copying template files...${NC}"

# Copy CLAUDE.md template
if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md.template" "$PROJECT_ROOT/CLAUDE.md"
    echo -e "${GREEN}✅ Created CLAUDE.md${NC}"
else
    echo -e "${YELLOW}⚠️  CLAUDE.md already exists, skipping${NC}"
fi

# Copy settings.local.json
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
    cp "$SCRIPT_DIR/settings.local.json.template" "$CLAUDE_DIR/settings.local.json"
    echo -e "${GREEN}✅ Created settings.local.json${NC}"
else
    echo -e "${YELLOW}⚠️  settings.local.json already exists, skipping${NC}"
fi

# Copy init script
cp "$SCRIPT_DIR/init_project_memory.py" "$PROJECT_ROOT/"
echo -e "${GREEN}✅ Copied initialization script${NC}\n"

# Step 7: Initialize project memory
echo -e "${YELLOW}Step 7: Initializing project memory...${NC}"
cd "$PROJECT_ROOT"
if $PYTHON_CMD init_project_memory.py; then
    echo -e "${GREEN}✅ Project memory initialized${NC}\n"
else
    echo -e "${YELLOW}⚠️  Could not initialize memory (ChromaDB server may not be running)${NC}"
    echo -e "${YELLOW}   Memory will auto-initialize when Claude starts${NC}\n"
fi

# Step 8: Get project name for customization
echo -e "${YELLOW}Step 8: Project customization...${NC}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
echo -e "Project detected: ${BLUE}$PROJECT_NAME${NC}"
echo -e "${YELLOW}Remember to update the project description in CLAUDE.md${NC}\n"

# Final summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ChromaDB Project Memory Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Edit ${BLUE}CLAUDE.md${NC} to add your project description"
echo -e "2. Restart Claude Desktop to load the MCP server"
echo -e "3. Open your project in Claude - memory will auto-initialize"
echo -e "4. Run ${BLUE}./chromadb/test_chromadb.sh${NC} to verify setup\n"

echo -e "${GREEN}Your project now has persistent memory across Claude sessions!${NC}"

# Create a marker file to indicate successful setup
echo "$(date): ChromaDB setup completed" > "$CLAUDE_DIR/.chromadb_setup_complete"

exit 0