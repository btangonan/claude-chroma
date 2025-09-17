#!/bin/bash
# Verify ChromaDB setup consistency

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 ChromaDB Consistency Check"
echo "================================"

ISSUES=0

# 1. Check all uses collection_name (not collection)
echo -n "Checking parameter consistency... "
if grep -q '"collection":' chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${RED}✗${NC} Found 'collection' parameter (should be collection_name)"
    grep -n '"collection":' chromadb_setup_fixed.sh || true
    ((ISSUES++))
else
    echo -e "${GREEN}✓${NC} All using collection_name"
fi

# 2. Check tags are strings not arrays
echo -n "Checking tags format... "
if grep -q '"tags": \[' chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${RED}✗${NC} Found array tags (should be strings)"
    grep -n '"tags": \[' chromadb_setup_fixed.sh || true
    ((ISSUES++))
else
    echo -e "${GREEN}✓${NC} All tags are comma-separated strings"
fi

# 3. Check for $UVX_PATH usage
echo -n "Checking UVX_PATH usage... "
UVX_COUNT=$(grep -c '\$UVX_PATH' chromadb_setup_fixed.sh 2>/dev/null || echo 0)
BARE_UVX=$(grep -c 'uvx ' chromadb_setup_fixed.sh 2>/dev/null || echo 0)
if [ "$UVX_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Using \$UVX_PATH ($UVX_COUNT times)"
    if [ "$BARE_UVX" -gt 2 ]; then  # Allow some in comments/help text
        echo -e "  ${YELLOW}⚠${NC} Also found bare 'uvx' ($BARE_UVX times)"
    fi
else
    echo -e "${RED}✗${NC} Not using \$UVX_PATH"
    ((ISSUES++))
fi

# 4. Check for idempotent CLAUDE.md handling
echo -n "Checking idempotent CLAUDE.md handling... "
if grep -q 'BEGIN:CHROMA-AUTOINIT' chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Using idempotent tags"
else
    echo -e "${RED}✗${NC} Not using idempotent tags"
    ((ISSUES++))
fi

# 5. Check for non-interactive mode support
echo -n "Checking non-interactive mode... "
if grep -q 'YES=\${CHROMA_SETUP_YES:-0}' chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Non-interactive mode supported"
else
    echo -e "${RED}✗${NC} Non-interactive mode not supported"
    ((ISSUES++))
fi

# 6. Check instructions format
echo -n "Checking instructions format... "
if grep -q 'collection_name.*must exist, create first if needed' chromadb_setup_fixed.sh 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Instructions use collection_name"
else
    echo -e "${YELLOW}⚠${NC} Instructions format unclear"
fi

echo ""
echo "================================"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "The setup script is consistent with:"
    echo "  • collection_name for all operations"
    echo "  • Tags as comma-separated strings"
    echo "  • \$UVX_PATH usage throughout"
    echo "  • Idempotent CLAUDE.md updates"
    echo "  • Non-interactive mode support"
else
    echo -e "${RED}❌ Found $ISSUES issues${NC}"
    echo ""
    echo "Run the following to fix:"
    echo '  perl -0777 -pe '\''s/"collection": "project_memory"/"collection_name": "project_memory"/g'\'' -i chromadb_setup_fixed.sh'
    echo '  perl -0777 -pe '\''s/"tags": \[([^\]]+)\]/"tags": "$1"/g; s/", "/, /g'\'' -i chromadb_setup_fixed.sh'
fi