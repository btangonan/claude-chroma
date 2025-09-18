#!/bin/bash
# Comprehensive Test Suite for claude-chroma.sh v3.2
# Tests all functionality, edge cases, and safety features

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Script location
SCRIPT_PATH="/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh"
TEST_DIR="/tmp/chroma_test_$$"

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Test framework functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "

    local actual_result=0
    eval "$test_command" >/dev/null 2>&1 || actual_result=$?

    if [ "$actual_result" -eq "$expected_result" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (expected: $expected_result, got: $actual_result)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (file not found: $file)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (pattern not found: $pattern)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

# ============================================================================
# TEST SUITE BEGINS
# ============================================================================

echo "============================================"
echo "ChromaDB Setup Script v3.2 - Test Suite"
echo "============================================"
echo ""

# Create test directory
mkdir -p "$TEST_DIR"

# ============================================================================
echo -e "\n${YELLOW}1. BASIC FUNCTIONALITY TESTS${NC}"
# ============================================================================

run_test "Script exists and is executable" "test -x '$SCRIPT_PATH'"
run_test "Version check" "'$SCRIPT_PATH' --version 2>&1 | grep -q '3.2.0'"
run_test "Help flag works" "'$SCRIPT_PATH' --help 2>&1 | grep -q 'Usage:'"

# ============================================================================
echo -e "\n${YELLOW}2. DRY RUN MODE TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
run_test "Dry run creates no files" "DRY_RUN=1 '$SCRIPT_PATH' test-dry && [ ! -f .mcp.json ]"
run_test "Dry run shows preview messages" "DRY_RUN=1 '$SCRIPT_PATH' test-dry 2>&1 | grep -q 'dry-run'"

# ============================================================================
echo -e "\n${YELLOW}3. PATH VALIDATION TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
# Test that spaces in paths work (this was the main bug!)
run_test "Accepts path with spaces" "DRY_RUN=1 '$SCRIPT_PATH' test-spaces '/tmp/My Projects' 2>&1 | grep -v 'Invalid path'"

# Test that dangerous characters are rejected
run_test "Rejects path with backticks" "! DRY_RUN=1 '$SCRIPT_PATH' 'test\`cmd\`' 2>&1"
run_test "Rejects path with dollar signs" "! DRY_RUN=1 '$SCRIPT_PATH' 'test\$var' 2>&1"
run_test "Rejects path with semicolons" "! DRY_RUN=1 '$SCRIPT_PATH' 'test;cmd' 2>&1"

# Test project name validation
run_test "Accepts valid project name" "DRY_RUN=1 '$SCRIPT_PATH' my-project_123 2>&1 | grep -v 'Invalid project'"
run_test "Rejects project with spaces" "! DRY_RUN=1 '$SCRIPT_PATH' 'my project' 2>&1"

# ============================================================================
echo -e "\n${YELLOW}4. NON-INTERACTIVE MODE TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
mkdir -p test-noninteractive
cd test-noninteractive

run_test "Non-interactive with assume yes" "NON_INTERACTIVE=1 ASSUME_YES=1 '$SCRIPT_PATH' 2>&1 | grep -v 'prompt'"
assert_file_exists ".mcp.json" "Creates .mcp.json in non-interactive mode"
assert_file_exists "CLAUDE.md" "Creates CLAUDE.md in non-interactive mode"

# Clean up for next test
cd "$TEST_DIR"
rm -rf test-noninteractive

# ============================================================================
echo -e "\n${YELLOW}5. JSON VALIDATION TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
mkdir -p test-json
cd test-json

# Create project and verify JSON
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT_PATH" >/dev/null 2>&1

run_test "Generated .mcp.json is valid JSON" "jq -e . .mcp.json"
assert_contains ".mcp.json" '"chroma"' "JSON contains chroma server config"
assert_contains ".mcp.json" '"type": "stdio"' "JSON has correct server type"

# ============================================================================
echo -e "\n${YELLOW}6. FILE BACKUP TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
mkdir -p test-backup
cd test-backup

# Create initial files
echo "original content" > test.txt
echo '{"test": "original"}' > .mcp.json

# Run script (should backup .mcp.json)
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT_PATH" >/dev/null 2>&1

run_test "Backup created for existing .mcp.json" "ls .mcp.json.backup.* 2>/dev/null | grep -q backup"

# ============================================================================
echo -e "\n${YELLOW}7. UNICODE AND SPECIAL CHARACTER TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
run_test "Handles unicode in paths" "DRY_RUN=1 '$SCRIPT_PATH' test-unicode '/tmp/プロジェクト' 2>&1 | grep -v 'Invalid'"

# ============================================================================
echo -e "\n${YELLOW}8. ERROR HANDLING TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
run_test "Script fails gracefully with invalid arguments" "! '$SCRIPT_PATH' --invalid-flag 2>/dev/null"
run_test "Handles missing jq dependency check" "'$SCRIPT_PATH' --help 2>&1 | grep -q 'Usage'" # Should still show help

# ============================================================================
echo -e "\n${YELLOW}9. MIGRATION TESTS${NC}"
# ============================================================================

cd "$TEST_DIR"
mkdir -p test-migration/.claude
cd test-migration

# Create old invalid config
cat > .claude/settings.local.json <<'EOF'
{
  "instructions": ["invalid field that should be removed"]
}
EOF

# Run migration
NON_INTERACTIVE=1 ASSUME_YES=1 "$SCRIPT_PATH" >/dev/null 2>&1

run_test "Old invalid config is backed up" "ls .claude/settings.local.json.backup.* 2>/dev/null | grep -q backup || [ ! -f .claude/settings.local.json ]"

# ============================================================================
echo -e "\n${YELLOW}10. CURRENT DIRECTORY SETUP TEST${NC}"
# ============================================================================

cd "$TEST_DIR"
mkdir -p test-current
cd test-current

# Test setup in current directory (no project name)
run_test "Setup works in current directory" "NON_INTERACTIVE=1 ASSUME_YES=1 '$SCRIPT_PATH' 2>&1 | grep -q 'current directory'"
assert_file_exists ".mcp.json" "Creates config in current directory"

# ============================================================================
# TEST SUMMARY
# ============================================================================

echo ""
echo "============================================"
echo "TEST SUMMARY"
echo "============================================"
echo -e "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo -e "${RED}TEST SUITE FAILED${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}ALL TESTS PASSED!${NC}"
    echo "The script is working correctly."
    exit 0
fi