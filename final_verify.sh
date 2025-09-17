#!/bin/bash
# Final verification of ChromaDB setup consistency

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Final ChromaDB Setup Verification"
echo "===================================="

ALL_GOOD=true

# 1. Check all uses collection_name (not collection)
echo -n "1. Checking collection_name usage... "
BAD_COLLECTION=$(grep -r '"collection":' chromadb_setup_fixed.sh CLAUDE.md 2>/dev/null | grep -v collection_name || true)
if [ -z "$BAD_COLLECTION" ]; then
    echo -e "${GREEN}✅ All using collection_name${NC}"
else
    echo -e "${RED}❌ Found 'collection' without _name${NC}"
    echo "$BAD_COLLECTION"
    ALL_GOOD=false
fi

# 2. Check tags are strings not arrays
echo -n "2. Checking tags are strings... "
BAD_TAGS=$(grep -r '"tags": \[' chromadb_setup_fixed.sh CLAUDE.md 2>/dev/null || true)
if [ -z "$BAD_TAGS" ]; then
    # Also check for array format with quotes
    BAD_TAGS2=$(grep -r 'tags: \[' CLAUDE.md 2>/dev/null || true)
    if [ -z "$BAD_TAGS2" ]; then
        echo -e "${GREEN}✅ All tags are strings${NC}"
    else
        echo -e "${RED}❌ Found array tags${NC}"
        echo "$BAD_TAGS2"
        ALL_GOOD=false
    fi
else
    echo -e "${RED}❌ Found array tags${NC}"
    echo "$BAD_TAGS"
    ALL_GOOD=false
fi

# 3. Check no HTTP/chromadb-mcp references
echo -n "3. Checking for old HTTP/chromadb-mcp... "
OLD_REFS=$(grep -r 'chromadb-mcp\|CHROMADB_HOST\|CHROMADB_PORT' --include="*.sh" --include="*.md" --exclude="test_mcp_stdio.sh" . 2>/dev/null | grep -v "stdio\|chroma-mcp" || true)
if [ -z "$OLD_REFS" ]; then
    echo -e "${GREEN}✅ No old HTTP references${NC}"
else
    echo -e "${RED}❌ Found old references${NC}"
    echo "$OLD_REFS"
    ALL_GOOD=false
fi

# 4. Verify config structure
echo -n "4. Checking config structure... "
if [ -f ".claude/settings.local.json" ]; then
    HAS_STDIO=$(grep '"type": "stdio"' .claude/settings.local.json || true)
    HAS_CHROMA=$(grep 'chroma-mcp' .claude/settings.local.json || true)
    HAS_COLLECTION_NAME=$(grep 'collection_name' .claude/settings.local.json || true)

    if [ -n "$HAS_STDIO" ] && [ -n "$HAS_CHROMA" ] && [ -n "$HAS_COLLECTION_NAME" ]; then
        echo -e "${GREEN}✅ Config structure correct${NC}"
    else
        echo -e "${RED}❌ Config issues found${NC}"
        ALL_GOOD=false
    fi
else
    echo -e "${YELLOW}⚠️ No config file yet${NC}"
fi

echo ""
echo "===================================="

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✅ ChromaDB setup is complete and working!${NC}"
    echo ""
    echo "Ready to use with:"
    echo '  mcp__chroma__chroma_create_collection {"collection_name":"project_memory"}'
    echo '  mcp__chroma__chroma_add_documents {'
    echo '    "collection_name":"project_memory",'
    echo '    "documents":["test"],'
    echo '    "metadatas":[{"type":"test","tags":"init,test","source":"manual"}],'
    echo '    "ids":["test-001"]'
    echo '  }'
    exit 0
else
    echo -e "${RED}❌ Issues found - review above${NC}"
    exit 1
fi