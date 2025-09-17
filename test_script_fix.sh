#!/bin/bash
# Test script to verify the fix works correctly

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Testing ChromaDB Setup Script Fix${NC}"
echo "======================================"

# Test 1: Simulate existing project (empty input)
echo -e "\n${YELLOW}Test 1: Existing Project (press Enter)${NC}"
echo "Current directory: $(pwd)"
echo "Expected: Should use current directory"
echo "Command: ./chromadb_setup_fixed.sh"
echo "  Enter project name: [ENTER]"
echo ""
echo "Expected behavior:"
echo "  ✓ Uses current directory as PROJECT_DIR"
echo "  ✓ Extracts folder name as PROJECT_NAME"
echo "  ✓ Creates .claude/ and .chroma/ in current directory"

# Test 2: New project with name
echo -e "\n${YELLOW}Test 2: New Project with Name${NC}"
echo "Command: ./chromadb_setup_fixed.sh test-project"
echo ""
echo "Expected behavior:"
echo "  ✓ Creates new folder 'test-project'"
echo "  ✓ Sets up ChromaDB inside test-project/"

# Test 3: Existing project from another directory
echo -e "\n${YELLOW}Test 3: Run from Different Directory${NC}"
echo "Command: cd /tmp && /path/to/chromadb_setup_fixed.sh"
echo "  Enter project name: [ENTER]"
echo ""
echo "Expected behavior:"
echo "  ✓ Uses /tmp as PROJECT_DIR"
echo "  ✓ Creates .claude/ and .chroma/ in /tmp"

echo -e "\n${GREEN}Fix Summary:${NC}"
echo "1. Added prompt text: '(or press Enter for current directory)'"
echo "2. Check if PROJECT_NAME is empty after input"
echo "3. If empty: use pwd as PROJECT_DIR, basename as PROJECT_NAME"
echo "4. If not empty: use original logic (construct path)"

echo -e "\n${GREEN}How to test manually:${NC}"
echo "1. cd to any existing project"
echo "2. Run: ./chromadb_setup_fixed.sh"
echo "3. Press Enter when asked for project name"
echo "4. Verify files created in current directory, not parent"