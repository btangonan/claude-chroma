#!/bin/bash
# Apply ChromaDB v3.5.0 patches - Project Isolation & Enhancements
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    ChromaDB v3.5.0 Upgrade - Project Isolation    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo

# Check we're in the right directory
if [[ ! -f "claude-chroma.sh" ]]; then
    echo -e "${RED}Error: claude-chroma.sh not found${NC}"
    echo "Please run this from the ChromaDB project directory"
    exit 1
fi

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
cp claude-chroma.sh claude-chroma.sh.backup.$(date +%Y%m%d_%H%M%S)

# Apply patches
echo -e "${YELLOW}Applying patches...${NC}"
echo

# Check if patches directory exists
if [[ ! -d "patches" ]]; then
    echo -e "${RED}Error: patches directory not found${NC}"
    exit 1
fi

# Apply each patch
for patch in patches/*.patch; do
    if [[ -f "$patch" ]]; then
        echo -e "${BLUE}Applying $(basename "$patch")...${NC}"
        patch -p1 < "$patch" || {
            echo -e "${RED}Failed to apply $(basename "$patch")${NC}"
            echo "You may need to apply changes manually"
        }
    fi
done

# Create bin directory and add chroma-stats.py
echo -e "${YELLOW}Installing chroma-stats.py...${NC}"
mkdir -p bin
if [[ -f "patches/chroma-stats.py" ]]; then
    cp patches/chroma-stats.py bin/
    chmod +x bin/chroma-stats.py
fi

# Install enhanced launcher
if [[ -f "patches/start-claude-chroma-enhanced.sh" ]]; then
    echo -e "${YELLOW}Installing enhanced launcher...${NC}"
    cp patches/start-claude-chroma-enhanced.sh start-claude-chroma.sh
    chmod +x start-claude-chroma.sh
fi

echo
echo -e "${GREEN}✓ Upgrade complete!${NC}"
echo
echo -e "${BLUE}Key improvements in v3.5.0:${NC}"
echo "  • Project-specific collections (no cross-contamination)"
echo "  • Context directory for always-loaded references"
echo "  • Memory statistics on activation"
echo "  • Project registry for tracking all ChromaDB projects"
echo "  • Enhanced launcher with session tracking"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test with: ./claude-chroma.sh test-project /tmp/test"
echo "2. Check new features work correctly"
echo "3. Update existing projects by re-running setup"
echo
echo -e "${GREEN}Happy coding with isolated project memories!${NC}"