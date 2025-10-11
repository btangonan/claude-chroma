#!/bin/bash
# Test script to verify empty CLAUDE.md bug fix

set -euo pipefail

readonly TEST_DIR="/tmp/test-empty-claudemd-$$"
readonly SCRIPT_PATH="./claude-chroma.sh"

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

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$OLDPWD/$SCRIPT_PATH" >/dev/null 2>&1; then
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

# Test 2: Empty template - should fail gracefully
echo ""
echo "Test 2: Empty template should be caught"
mkdir -p "$TEST_DIR/test2/templates"
cd "$TEST_DIR/test2"
touch templates/CLAUDE.md.tpl  # Create empty template

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$OLDPWD/$SCRIPT_PATH" 2>&1 | grep -q "Template expansion failed"; then
    if [[ ! -f "CLAUDE.md" ]] || [[ ! -s "CLAUDE.md" ]]; then
        echo "✅ PASS: Empty template prevented, no empty CLAUDE.md created"
    else
        echo "❌ FAIL: Empty CLAUDE.md was created despite validation"
        exit 1
    fi
else
    echo "❌ FAIL: Script should have detected empty template"
    exit 1
fi

# Test 3: write_file_safe with empty content - should fail
echo ""
echo "Test 3: write_file_safe rejects empty content"
mkdir -p "$TEST_DIR/test3"
cd "$TEST_DIR/test3"

# Source the script functions
source "$OLDPWD/$SCRIPT_PATH" 2>/dev/null || true

# Try to write empty content
if (
    DRY_RUN=0
    write_file_safe "test.txt" "" 2>&1 || true
) | grep -q "Attempted to write empty content"; then
    echo "✅ PASS: write_file_safe rejected empty content"
else
    echo "❌ FAIL: write_file_safe should reject empty content"
    exit 1
fi

# Test 4: Existing CLAUDE.md preservation
echo ""
echo "Test 4: Existing CLAUDE.md is backed up"
mkdir -p "$TEST_DIR/test4"
cd "$TEST_DIR/test4"
echo "# Original content" > CLAUDE.md

if env NON_INTERACTIVE=1 ASSUME_YES=1 bash "$OLDPWD/$SCRIPT_PATH" >/dev/null 2>&1; then
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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed! Empty CLAUDE.md bug is fixed."
