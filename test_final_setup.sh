#!/bin/bash
# Final smoke test for ChromaDB setup
# Tests that everything is properly configured

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 ChromaDB Setup Smoke Test"
echo "============================"

# 1. Check uvx exists
echo -n "Checking uvx installation... "
if UVX_PATH=$(command -v uvx); then
    echo -e "${GREEN}✓${NC} Found at: $UVX_PATH"
else
    echo -e "${RED}✗${NC} Not found"
    exit 1
fi

# 2. Test chroma-mcp availability
echo -n "Testing chroma-mcp availability... "
if "$UVX_PATH" -qq chroma-mcp --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  Try: $UVX_PATH install chroma-mcp"
    exit 1
fi

# 3. Check for settings file
echo -n "Checking for .claude/settings.local.json... "
if [ -f ".claude/settings.local.json" ]; then
    echo -e "${GREEN}✓${NC}"

    # Verify it has chroma configured
    if grep -q '"chroma"' .claude/settings.local.json; then
        echo -e "  ${GREEN}✓${NC} ChromaDB configured"
    else
        echo -e "  ${RED}✗${NC} ChromaDB not in config"
    fi

    # Verify absolute paths
    if grep -q "$UVX_PATH" .claude/settings.local.json; then
        echo -e "  ${GREEN}✓${NC} Using absolute uvx path"
    else
        echo -e "  ${YELLOW}⚠${NC} Not using absolute uvx path"
    fi

    # Verify data-dir is absolute
    if grep -q "$(pwd)/.chroma" .claude/settings.local.json; then
        echo -e "  ${GREEN}✓${NC} Using absolute data-dir path"
    else
        echo -e "  ${YELLOW}⚠${NC} Not using absolute data-dir path"
    fi

    # Verify instructions are present
    if grep -q '"instructions"' .claude/settings.local.json; then
        echo -e "  ${GREEN}✓${NC} Instructions present"
    else
        echo -e "  ${YELLOW}⚠${NC} Instructions missing"
    fi
else
    echo -e "${RED}✗${NC} Not found"
    echo "  Run: ./chromadb_setup_fixed.sh"
    exit 1
fi

# 4. Check CLAUDE.md
echo -n "Checking CLAUDE.md... "
if [ -f "CLAUDE.md" ]; then
    echo -e "${GREEN}✓${NC}"

    # Check for idempotent tags
    if grep -q "BEGIN:CHROMA-AUTOINIT" CLAUDE.md; then
        echo -e "  ${GREEN}✓${NC} Using idempotent tags"
    else
        echo -e "  ${YELLOW}⚠${NC} Not using idempotent tags"
    fi
else
    echo -e "${YELLOW}⚠${NC} Not found (will be created on setup)"
fi

# 5. Non-interactive mode test
echo -n "Testing non-interactive mode support... "
if grep -q 'YES=${CHROMA_SETUP_YES:-0}' chromadb/chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} Not found in script"
fi

echo ""
echo "📋 Test Commands for Claude:"
echo "=============================="
echo ""
echo "1. Create collection:"
echo '   mcp__chroma__chroma_create_collection {"collection_name":"project_memory"}'
echo ""
echo "2. Add memory:"
echo '   mcp__chroma__chroma_add_documents {'
echo '     "collection":"project_memory",'
echo '     "documents":["Setup test successful"],'
echo '     "metadatas":[{"type":"test","tags":["init","smoke"],"source":"test"}],'
echo '     "ids":["test-001"]'
echo '   }'
echo ""
echo "3. Query memory:"
echo '   mcp__chroma__chroma_query_documents {'
echo '     "collection":"project_memory",'
echo '     "query_texts":["test"],'
echo '     "n_results":1'
echo '   }'
echo ""
echo -e "${GREEN}✅ Ready to use!${NC}"
echo ""
echo "Start Claude with:"
echo "  claude --mcp-config .claude/settings.local.json"
echo ""
echo "Or use the smart function (if installed):"
echo "  claude-chroma"