#!/usr/bin/env bash
# Claude-Chroma One-Click Setup for macOS
# Just double-click this file to set up ChromaDB for this directory!
# Version: 3.5.3-oneclick

set -euo pipefail

# Get the directory where this script is located (where user double-clicked)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Create temporary directory for extraction
TEMP_DIR="$(mktemp -d)"
trap "rm -rf '$TEMP_DIR'" EXIT

clear
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🚀 Claude-Chroma One-Click Setup${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Setting up ChromaDB for:${NC}"
echo "  📁 Project: $PROJECT_NAME"
echo "  📍 Location: $PROJECT_DIR"
echo ""
echo "Please wait while we configure everything..."
echo ""

# Extract embedded claude-chroma.sh to temp directory
echo -e "${BLUE}Extracting setup files...${NC}"
cat > "$TEMP_DIR/claude-chroma.sh" << 'EMBEDDED_SCRIPT'
$(cat claude-chroma.sh)
EMBEDDED_SCRIPT
chmod +x "$TEMP_DIR/claude-chroma.sh"

# Create templates directory and extract template
mkdir -p "$PROJECT_DIR/templates"
cat > "$PROJECT_DIR/templates/CLAUDE.md.tpl" << 'EMBEDDED_TEMPLATE'
$(cat templates/CLAUDE.md.tpl)
EMBEDDED_TEMPLATE

echo -e "${GREEN}✓${NC} Files extracted"
echo ""

# Run the setup script in non-interactive mode
echo -e "${BLUE}Configuring ChromaDB...${NC}"
cd "$PROJECT_DIR"
export NON_INTERACTIVE=1
export ASSUME_YES=1

# Run the actual setup
if "$TEMP_DIR/claude-chroma.sh"; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}ChromaDB has been configured for this project!${NC}"
    echo ""

    # Try to launch Claude
    if command -v claude >/dev/null 2>&1; then
        echo -e "${BLUE}Launching Claude...${NC}"
        echo ""
        echo "Claude will start with ChromaDB memory enabled."
        echo "You can close this terminal window."
        echo ""

        # Give user time to read the message
        sleep 2

        # Launch Claude in background and exit
        claude &

        # Success message
        echo -e "${GREEN}Claude is starting...${NC}"
    else
        echo -e "${YELLOW}Claude CLI not found.${NC}"
        echo ""
        echo "To start using ChromaDB:"
        echo "  1. Install Claude from: https://claude.ai/download"
        echo "  2. Open Terminal in this directory"
        echo "  3. Run: claude"
        echo ""
        echo "Or use the launcher script:"
        echo "  ./start-claude-chroma.sh"
    fi
else
    echo ""
    echo -e "${YELLOW}Setup encountered an issue.${NC}"
    echo "Please check the output above for details."
    echo ""
    echo "To run setup manually:"
    echo "  1. Download claude-chroma.sh"
    echo "  2. Run: ./claude-chroma.sh"
fi

echo ""
echo "Press Enter to close this window..."
read -r

# The trap will clean up temp files on exit