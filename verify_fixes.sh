#!/bin/bash
# Verification script for chromadb_setup_fixed.sh fixes

echo "🔍 Verifying all 10 fixes in chromadb_setup_fixed.sh"
echo "================================================="

SCRIPT="chromadb_setup_fixed.sh"
PASS=0
FAIL=0

# 1. Check for duplicate uvx check removal
echo -n "1. Duplicate uvx check removed... "
DUP_COUNT=$(grep -c "if ! command -v uvx" "$SCRIPT")
if [ "$DUP_COUNT" -eq 1 ]; then
    echo "✅ Pass (only 1 check)"
    ((PASS++))
else
    echo "❌ Fail (found $DUP_COUNT checks)"
    ((FAIL++))
fi

# 2. Check YES=1 handling in confirm function
echo -n "2. YES=1 works in confirm()... "
if grep -q 'if \[ "$YES" = "1" \]; then.*REPLY="y".*return 0' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 3. Check PATH export persistence
echo -n "3. PATH persistence after pip install... "
if grep -q 'echo.*export PATH=.*HOME/.local/bin.*>> "$SHELL_CONFIG"' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 4. Check for jq preference over Python
echo -n "4. jq preferred for JSON operations... "
if grep -q 'HAS_JQ=.*\|if.*"$HAS_JQ" = "true".*jq --arg' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 5. Check TOKENIZERS_PARALLELISM value
echo -n "5. TOKENIZERS_PARALLELISM set to 'False'... "
FALSE_COUNT=$(grep -c '"TOKENIZERS_PARALLELISM": "False"' "$SCRIPT")
false_COUNT=$(grep -c '"TOKENIZERS_PARALLELISM": "false"' "$SCRIPT")
if [ "$FALSE_COUNT" -gt 0 ] && [ "$false_COUNT" -eq 0 ]; then
    echo "✅ Pass (all 'False')"
    ((PASS++))
else
    echo "❌ Fail (found 'false')"
    ((FAIL++))
fi

# 6. Check dead CLAUDE.md code removed
echo -n "6. Dead 'if false' block removed... "
if grep -q "^if false; then" "$SCRIPT"; then
    echo "❌ Fail (still present)"
    ((FAIL++))
else
    echo "✅ Pass"
    ((PASS++))
fi

# 7. Check rollback/cleanup on failure
echo -n "7. Rollback cleanup on exit... "
if grep -q "trap cleanup_on_exit EXIT" "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 8. Check chroma-mcp version pinning
echo -n "8. chroma-mcp version pinned... "
if grep -q 'CHROMA_MCP_VERSION="chroma-mcp==0.2.0"' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 9. Check tree command handling
echo -n "9. Tree command graceful fallback... "
if grep -q 'if command -v tree.*tree -a -L 2.*else.*ls -la' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

# 10. Check shell function duplication prevention
echo -n "10. Shell function duplication check... "
if grep -q 'grep -q "claude-chroma()\\|function claude-chroma"' "$SCRIPT"; then
    echo "✅ Pass"
    ((PASS++))
else
    echo "❌ Fail"
    ((FAIL++))
fi

echo ""
echo "================================================="
echo "Results: $PASS/10 passed, $FAIL/10 failed"

if [ "$PASS" -eq 10 ]; then
    echo "🎉 All fixes successfully applied!"
    exit 0
else
    echo "⚠️ Some fixes are missing or incorrect"
    exit 1
fi