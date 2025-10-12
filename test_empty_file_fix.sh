#!/bin/bash
# Test script to verify empty CLAUDE.md bug fix

set -euo pipefail

readonly TEST_DIR="/tmp/test-empty-claudemd-$$"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_PATH="$SCRIPT_DIR/claude-chroma.sh"

cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

trap cleanup EXIT

echo "🧪 Testing Empty CLAUDE.md Fix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Normal operation - should succeed
echo ""
echo "Test 1: Normal operation with valid template"
mkdir -p "$TEST_DIR/test1"
cd "$TEST_DIR/test1"

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$SCRIPT_PATH" >/dev/null 2>&1; then
    if [[ -f "CLAUDE.md" ]] && [[ -s "CLAUDE.md" ]]; then
        size=$(wc -c < "CLAUDE.md")
        echo "✅ PASS: CLAUDE.md created with $size bytes"
    else
        echo "❌ FAIL: CLAUDE.md is empty or missing"
        exit 1
    fi
else
    echo "❌ FAIL: Script failed unexpectedly"
    exit 1
fi

# Test 2: Empty template - should be auto-seeded (not a failure)
echo ""
echo "Test 2: Empty template should be auto-seeded with minimal template"
mkdir -p "$TEST_DIR/test2/templates"
cd "$TEST_DIR/test2"
touch templates/CLAUDE.md.tpl  # Create empty template

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$SCRIPT_PATH" >/dev/null 2>&1; then
    if [[ -f "CLAUDE.md" ]] && [[ -s "CLAUDE.md" ]]; then
        echo "✅ PASS: Script auto-seeded minimal template and created valid CLAUDE.md"
    else
        echo "❌ FAIL: Script should have auto-seeded template"
        exit 1
    fi
else
    echo "❌ FAIL: Script failed unexpectedly"
    exit 1
fi

# Test 3: Verify main guard allows sourcing without execution
echo ""
echo "Test 3: Script can be sourced without running main()"
mkdir -p "$TEST_DIR/test3"
cd "$TEST_DIR/test3"

# Try sourcing - should not execute main
if (source "$SCRIPT_PATH" 2>&1 | grep -q "🚀 Setting up ChromaDB"); then
    echo "❌ FAIL: Script ran main() when sourced"
    exit 1
else
    echo "✅ PASS: Script can be sourced without executing main()"
fi

# Test 4: Existing CLAUDE.md preservation
echo ""
echo "Test 4: Existing CLAUDE.md is backed up"
mkdir -p "$TEST_DIR/test4"
cd "$TEST_DIR/test4"
echo "# Original content" > CLAUDE.md

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$SCRIPT_PATH" >/dev/null 2>&1; then
    if [[ -f "CLAUDE.md.original" ]] && grep -q "Original content" "CLAUDE.md.original"; then
        echo "✅ PASS: Existing CLAUDE.md backed up correctly"
    else
        echo "❌ FAIL: Existing CLAUDE.md not backed up"
        exit 1
    fi
else
    echo "❌ FAIL: Script failed with existing CLAUDE.md"
    exit 1
fi

# Test 5: Whitespace-only template content
echo ""
echo "Test 5: Whitespace-only template should be caught"
mkdir -p "$TEST_DIR/test5/templates"
cd "$TEST_DIR/test5"
# Create template with only whitespace
printf "   \n\t\n   \n" > templates/CLAUDE.md.tpl

# Run script, capture output, then grep (avoid pipefail issues)
env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$SCRIPT_PATH" > /tmp/test5-output.log 2>&1 || true
if grep -q "whitespace-only content" /tmp/test5-output.log; then
    echo "✅ PASS: Whitespace-only template detected and rejected"
else
    echo "❌ FAIL: Whitespace-only template should have been caught"
    echo "Last 10 lines of output:"
    tail -10 /tmp/test5-output.log
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed! CLAUDE.md validation is robust."
echo ""
echo "📝 Known Limitation:"
echo "   envsubst removes undefined variables (replaces with empty string)"
echo "   Placeholder typos like \${PROJECT_COLLCETION_TYPO} become blank"
echo "   This cannot be detected by the current validation approach"
echo "   Mitigation: Template is version-controlled and tested manually"
