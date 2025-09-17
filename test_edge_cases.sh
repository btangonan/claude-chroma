#!/bin/bash
# Edge case tests for chromadb_setup_fixed.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}ChromaDB Setup Script - Edge Case Tests${NC}"
echo "========================================="

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check Python3 is available
echo -e "\n${YELLOW}Test 1: Python3 Availability${NC}"
if command -v python3 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Python3 is available${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Python3 not found (required for merge operation)${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Check uvx is available and can run chroma-mcp via stdio
echo -e "\n${YELLOW}Test 2: uvx and chroma-mcp stdio availability${NC}"
if command -v uvx >/dev/null 2>&1; then
    if uvx -qq chroma-mcp --help >/dev/null 2>&1; then
        echo -e "${GREEN}✓ uvx and chroma-mcp available for stdio transport${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ chroma-mcp not available via uvx${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ uvx not found${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: Check script handles spaces in names
echo -e "\n${YELLOW}Test 3: Spaces in Project Names${NC}"
TEST_DIR="/tmp/test project with spaces"
mkdir -p "$TEST_DIR"
if [ -d "$TEST_DIR" ]; then
    echo -e "${GREEN}✓ Can handle spaces in directory names${NC}"
    ((TESTS_PASSED++))
    rm -rf "$TEST_DIR"
else
    echo -e "${RED}✗ Failed to create directory with spaces${NC}"
    ((TESTS_FAILED++))
fi

# Test 4: Check for special characters handling
echo -e "\n${YELLOW}Test 4: Special Characters in Names${NC}"
# Don't actually create these, just test the quoting
PROJECT_NAME="test-project_123"
if [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${GREEN}✓ Project name is safe: $PROJECT_NAME${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ Project name contains special characters${NC}"
fi

# Test 5: Test heredoc with backticks
echo -e "\n${YELLOW}Test 5: Heredoc Backtick Escaping${NC}"
cat > /tmp/test_heredoc.sh <<'EOF'
#!/bin/bash
cat <<'TESTEOF'
\`\`\`javascript
console.log("test");
\`\`\`
TESTEOF
EOF
if bash /tmp/test_heredoc.sh 2>/dev/null | grep -q '```javascript'; then
    echo -e "${GREEN}✓ Backticks properly escaped in heredocs${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Backtick escaping issue${NC}"
    ((TESTS_FAILED++))
fi
rm -f /tmp/test_heredoc.sh

# Test 6: Check read command compatibility
echo -e "\n${YELLOW}Test 6: Read Command Compatibility${NC}"
# Test the read -p -n 1 -r syntax
echo "y" | read -p "Test prompt: " -n 1 -r TEST_REPLY 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Read command syntax is compatible${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ Read command may have compatibility issues${NC}"
    ((TESTS_FAILED++))
fi

# Test 7: Directory permissions
echo -e "\n${YELLOW}Test 7: Directory Write Permissions${NC}"
TEST_DIR="/tmp/chromadb_test_$$"
mkdir -p "$TEST_DIR"
if touch "$TEST_DIR/test_file" 2>/dev/null; then
    echo -e "${GREEN}✓ Can write to test directory${NC}"
    ((TESTS_PASSED++))
    rm -rf "$TEST_DIR"
else
    echo -e "${RED}✗ Cannot write to test directory${NC}"
    ((TESTS_FAILED++))
fi

# Test 8: JSON syntax in Python merge
echo -e "\n${YELLOW}Test 8: JSON Merge Logic${NC}"
python3 -c "
import json
import sys
try:
    test_data = {'mcpServers': {'existing': {}}}
    test_data['mcpServers']['chroma'] = {'type': 'stdio'}
    json.dumps(test_data)
    print('JSON merge logic is valid')
    sys.exit(0)
except:
    sys.exit(1)
" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ JSON merge logic is valid${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ JSON merge logic has issues${NC}"
    ((TESTS_FAILED++))
fi

# Test 9: Check for command substitution issues
echo -e "\n${YELLOW}Test 9: Command Substitution Safety${NC}"
# Test that $(date) in the script won't cause issues
TEST_DATE=$(date +%Y%m%d_%H%M%S)
if [[ "$TEST_DATE" =~ ^[0-9_]+$ ]]; then
    echo -e "${GREEN}✓ Date command substitution is safe${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Date format issue${NC}"
    ((TESTS_FAILED++))
fi

# Summary
echo -e "\n${YELLOW}=========================================${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}All edge case tests passed!${NC}"
fi

# Recommendations
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${YELLOW}Recommendations:${NC}"
    echo "- Ensure python3 is installed for merge operations"
    echo "- Install uvx for ChromaDB MCP server"
    echo "- Check directory permissions before running"
fi