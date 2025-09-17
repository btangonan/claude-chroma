#!/bin/bash

# ChromaDB Quick Start - One-command setup
# Run this from any project directory to add persistent memory

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 ChromaDB Quick Start for Claude Desktop${NC}\n"

# Get the directory where this script is located
CHROMADB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the main setup
echo -e "${BLUE}Setting up ChromaDB for your project...${NC}"
"$CHROMADB_DIR/setup_chromadb.sh"

# If successful, run test
if [ $? -eq 0 ]; then
    echo -e "\n${BLUE}Running validation tests...${NC}"
    "$CHROMADB_DIR/test_chromadb.sh"

    echo -e "\n${GREEN}✨ Setup complete! Your project now has persistent memory.${NC}"
    echo -e "${GREEN}📝 Next: Edit CLAUDE.md to customize your project description${NC}"
    echo -e "${GREEN}🔄 Then: Restart Claude Desktop to activate memory${NC}"
else
    echo -e "\n${RED}Setup failed. Check errors above.${NC}"
    exit 1
fi