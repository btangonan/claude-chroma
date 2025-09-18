#!/bin/bash
# Simple Direct Tests for claude-chroma.sh v3.2
# Avoids SIGPIPE issues by using direct tests

set -u  # Don't use -e as we want to capture exit codes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT="/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh"
TEST_DIR="/tmp/chroma_test_$$"
PASSED=0
FAILED=0

# Cleanup
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Simple test function
test_case() {
    local name="$1"
    local cmd="$2"
    local expect_success="${3:-true}"

    echo -n "Testing: $name ... "

    if eval "$cmd" >/dev/null 2>&1; then
        if [ "$expect_success" = "true" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAIL (should have failed)${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        if [ "$expect_success" = "false" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
}

echo "=========================================="
echo "ChromaDB v3.2 - Simple Test Suite"
echo "=========================================="
echo

# Create test directory
mkdir -p "$TEST_DIR"

# ============================================================================
echo -e "${YELLOW}1. BASIC TESTS${NC}"
# ============================================================================

test_case "Script exists" "test -f '$SCRIPT'"
test_case "Script is executable" "test -x '$SCRIPT'"

# Test version - capture output directly
VERSION=$("$SCRIPT" --version 2>&1 || true)
if [[ "$VERSION" == *"3.2"* ]]; then
    echo -e "Testing: Version check ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Version check ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test help - capture output directly
HELP=$("$SCRIPT" --help 2>&1 || true)
if [[ "$HELP" == *"Usage"* ]]; then
    echo -e "Testing: Help output ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Help output ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
echo -e "\n${YELLOW}2. DRY RUN TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"

# Test dry run - check output directly
DRY_OUTPUT=$(DRY_RUN=1 "$SCRIPT" test-project 2>&1 || true)
if [[ "$DRY_OUTPUT" == *"dry-run"* ]]; then
    echo -e "Testing: Dry run mode output ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Dry run mode output ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Verify no files created
DRY_RUN=1 "$SCRIPT" test-dry 2>&1 >/dev/null || true
if [ ! -f ".mcp.json" ]; then
    echo -e "Testing: Dry run creates no files ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Dry run creates no files ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
echo -e "\n${YELLOW}3. PATH VALIDATION TESTS${NC}"
# ============================================================================

# Test path with spaces - the critical bug fix!
PATH_OUTPUT=$(DRY_RUN=1 "$SCRIPT" test-spaces "/tmp/My Projects" 2>&1 || true)
if [[ "$PATH_OUTPUT" != *"Invalid path"* ]]; then
    echo -e "Testing: Accepts paths with spaces ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Accepts paths with spaces ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test unicode paths
UNICODE_OUTPUT=$(DRY_RUN=1 "$SCRIPT" test-unicode "/tmp/プロジェクト" 2>&1 || true)
if [[ "$UNICODE_OUTPUT" != *"Invalid path"* ]]; then
    echo -e "Testing: Accepts unicode paths ... ${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "Testing: Accepts unicode paths ... ${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test dangerous characters
test_case "Rejects backticks" "DRY_RUN=1 '$SCRIPT' 'test\`cmd\`' 2>&1 | grep -q 'Invalid'" "true"
test_case "Rejects dollar signs" "DRY_RUN=1 '$SCRIPT' 'test\$var' 2>&1 | grep -q 'Invalid'" "true"

# Test project name validation
test_case "Accepts valid project name" "DRY_RUN=1 '$SCRIPT' my-project_123" "true"
test_case "Rejects project with spaces" "DRY_RUN=1 '$SCRIPT' 'my project'" "false"

# ============================================================================
echo -e "\n${YELLOW}4. NON-INTERACTIVE MODE${NC}"
# ============================================================================

cd "$TEST_DIR"
rm -rf test-ni
mkdir -p test-ni
cd test-ni

# Run non-interactive setup
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT" >/dev/null 2>&1 || true

test_case "Creates .mcp.json" "test -f .mcp.json"
test_case "Creates CLAUDE.md" "test -f CLAUDE.md"
test_case "Creates .gitignore" "test -f .gitignore"
test_case "JSON is valid" "jq -e . .mcp.json"

# ============================================================================
echo -e "\n${YELLOW}5. SAFETY TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
rm -rf test-backup
mkdir test-backup
cd test-backup

# Create existing file
echo '{"existing": "data"}' > .mcp.json

# Run setup (should backup)
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT" >/dev/null 2>&1 || true

test_case "Creates backup of existing files" "ls .mcp.json.backup.* 2>/dev/null | grep -q backup"

# ============================================================================
echo -e "\n${YELLOW}6. CURRENT DIRECTORY TEST${NC}"
# ============================================================================

cd "$TEST_DIR"
rm -rf test-current
mkdir test-current
cd test-current

# Test with no project name (current directory)
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT" >/dev/null 2>&1 || true

test_case "Works in current directory" "test -f .mcp.json"

# ============================================================================
# SUMMARY
# ============================================================================

echo
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo "The claude-chroma.sh v3.2 script is working correctly."
    echo
    echo "Key validations:"
    echo "  • Paths with spaces work (main bug fix)"
    echo "  • Dry run mode prevents file creation"
    echo "  • Non-interactive mode works for automation"
    echo "  • Files are backed up before modification"
    echo "  • JSON generation is valid"
    echo "  • Unicode paths are supported"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo "Please review the failures above."
    exit 1
fi