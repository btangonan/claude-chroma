#!/bin/bash
# Test script to validate ChromaDB setup

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}ChromaDB Setup Validation${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Test project directory
TEST_DIR="/tmp/chromadb_test_$$"
echo "Creating test project at: $TEST_DIR"

# Run setup script
./chromadb_setup_fixed.sh "test_project" "/tmp/chromadb_test_$$" <<< "n"

# Validate created files
echo -e "\n${YELLOW}Validating setup...${NC}\n"

PROJECT_DIR="$TEST_DIR/test_project"
cd "$PROJECT_DIR"

# Check required files exist
FILES_TO_CHECK=(
    ".chroma"
    ".claude/settings.local.json"
    "CLAUDE.md"
    ".gitignore"
    "claudedocs/INIT_INSTRUCTIONS.md"
)

PASSED=0
FAILED=0

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -e "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $file missing"
        ((FAILED++))
    fi
done

# Validate settings.local.json has chroma config
if grep -q "chroma-mcp" .claude/settings.local.json; then
    echo -e "${GREEN}✓${NC} ChromaDB MCP server configured"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} ChromaDB MCP server not configured"
    ((FAILED++))
fi

# Validate CLAUDE.md has auto-init instructions
if grep -q "AUTO-INITIALIZATION" CLAUDE.md; then
    echo -e "${GREEN}✓${NC} Auto-initialization configured"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Auto-initialization not configured"
    ((FAILED++))
fi

# Check if uvx can run chroma-mcp
if uvx chroma-mcp --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ChromaDB MCP server accessible"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} ChromaDB MCP server not accessible"
    ((FAILED++))
fi

# Summary
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Tests passed: ${GREEN}$PASSED${NC}"
echo -e "Tests failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✅ All validation tests passed!${NC}"
    echo -e "Setup script is working correctly.\n"
else
    echo -e "\n${RED}❌ Some tests failed.${NC}"
    echo -e "Please check the setup script.\n"
fi

# Cleanup
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"