#!/bin/bash
# ChromaDB MCP stdio transport validation script
# Tests that the setup script creates valid stdio configuration

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}ChromaDB MCP stdio Transport Validation${NC}"
echo "========================================"

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check uvx and chroma-mcp availability
echo -e "\n${YELLOW}Test 1: MCP Server Availability${NC}"
if command -v uvx >/dev/null 2>&1; then
    if uvx -qq chroma-mcp --help >/dev/null 2>&1; then
        echo -e "${GREEN}✓ chroma-mcp available via uvx for stdio transport${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ chroma-mcp not available via uvx${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ uvx not found${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Validate stdio configuration format
echo -e "\n${YELLOW}Test 2: stdio Configuration Validation${NC}"
if [ -f ".claude/settings.local.json" ]; then
    if grep -q '"type": "stdio"' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Configuration uses stdio transport${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Configuration missing stdio transport${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for correct package name
    if grep -q 'chroma-mcp' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Using correct package: chroma-mcp${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Incorrect package name (should be chroma-mcp)${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for quiet mode
    if grep -q '"-qq"' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Quiet mode enabled (-qq flag)${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing -qq flag for quiet mode${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for telemetry disabled
    if grep -q '"ANONYMIZED_TELEMETRY": "FALSE"' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Telemetry disabled${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Telemetry not disabled${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for .chroma data directory
    if grep -q '.chroma' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Using .chroma data directory${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing or incorrect data directory${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for instructions
    if grep -q '"instructions"' .claude/settings.local.json; then
        echo -e "${GREEN}✓ Memory logging instructions included${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing memory logging instructions${NC}"
        ((TESTS_FAILED++))
    fi

else
    echo -e "${RED}✗ settings.local.json not found${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: Check for HTTP transport artifacts in MCP config (should not exist)
echo -e "\n${YELLOW}Test 3: No HTTP Transport Artifacts${NC}"
if [ -f ".claude/settings.local.json" ]; then
    # Check specifically in mcpServers section for HTTP transport artifacts
    if ! grep -A 20 '"mcpServers"' .claude/settings.local.json | grep -q '8000\|"type": "http"\|HttpClient'; then
        echo -e "${GREEN}✓ No HTTP transport artifacts in MCP config${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ HTTP transport artifacts detected in MCP config${NC}"
        echo -e "${YELLOW}   Found in mcpServers:${NC}"
        grep -A 20 '"mcpServers"' .claude/settings.local.json | grep -n '8000\|"type": "http"\|HttpClient' || true
        ((TESTS_FAILED++))
    fi
fi

# Test 4: Validate JSON syntax
echo -e "\n${YELLOW}Test 4: JSON Syntax Validation${NC}"
if [ -f ".claude/settings.local.json" ]; then
    if python3 -m json.tool .claude/settings.local.json >/dev/null 2>&1; then
        echo -e "${GREEN}✓ JSON syntax is valid${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Invalid JSON syntax${NC}"
        ((TESTS_FAILED++))
    fi
fi

# Test 5: Check CLAUDE.md for correct collection operations
echo -e "\n${YELLOW}Test 5: CLAUDE.md Collection Operations${NC}"
if [ -f "CLAUDE.md" ]; then
    if grep -q 'mcp__chroma__chroma_list_collections' CLAUDE.md; then
        echo -e "${GREEN}✓ Uses correct collection listing command${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing or incorrect collection listing command${NC}"
        ((TESTS_FAILED++))
    fi

    if grep -q 'mcp__chroma__chroma_create_collection' CLAUDE.md; then
        echo -e "${GREEN}✓ Uses correct collection creation command${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing or incorrect collection creation command${NC}"
        ((TESTS_FAILED++))
    fi

    # Check for correct parameter name (collection not collection_name)
    if grep -q '"collection":' CLAUDE.md; then
        echo -e "${GREEN}✓ Uses correct parameter: collection${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Missing or uses incorrect parameter${NC}"
        ((TESTS_FAILED++))
    fi
fi

# Summary
echo -e "\n========================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "\n${RED}❌ stdio transport validation failed${NC}"
    echo -e "${YELLOW}Run the hardened setup script to fix issues${NC}"
    exit 1
else
    echo -e "${GREEN}All stdio transport tests passed!${NC}"
    echo -e "\n${GREEN}✅ Configuration ready for Claude CLI with --mcp-config flag${NC}"
    exit 0
fi