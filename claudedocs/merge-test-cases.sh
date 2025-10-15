#!/usr/bin/env bash
# Test cases for auto-setup.sh merge functionality
# Run this script to validate non-destructive merge behavior

set -euo pipefail

TEST_BASE="/tmp/chromadb-merge-tests"
PLUGIN_ROOT="/Users/bradleytangonan/Desktop/my apps/chromadb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
success() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

failure() {
    echo -e "${RED}✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

setup_test_dir() {
    local test_name="$1"
    local test_dir="${TEST_BASE}/${test_name}"
    
    # Clean up existing test directory
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
    
    echo "$test_dir"
}

run_auto_setup() {
    local test_dir="$1"
    cd "$test_dir"
    bash "${PLUGIN_ROOT}/hooks/auto-setup.sh"
}

# ==============================================================================
# Test Case 1: Fresh Project (No Existing Files)
# ==============================================================================
test_fresh_project() {
    info "Test 1: Fresh project with no existing files"
    
    local test_dir=$(setup_test_dir "test1-fresh")
    
    # Run auto-setup
    run_auto_setup "$test_dir"
    
    # Verify CLAUDE.md created
    if [ -f "$test_dir/CLAUDE.md" ]; then
        success "CLAUDE.md created"
    else
        failure "CLAUDE.md not created"
    fi
    
    # Verify settings.local.json created
    if [ -f "$test_dir/.claude/settings.local.json" ]; then
        success "settings.local.json created"
    else
        failure "settings.local.json not created"
    fi
    
    # Verify .mcp.json created
    if [ -f "$test_dir/.mcp.json" ]; then
        success ".mcp.json created"
    else
        failure ".mcp.json not created"
    fi
    
    # Verify ChromaDB section in CLAUDE.md
    if grep -q "## 🧠 Project Memory (Chroma)" "$test_dir/CLAUDE.md"; then
        success "CLAUDE.md contains ChromaDB section"
    else
        failure "CLAUDE.md missing ChromaDB section"
    fi
}

# ==============================================================================
# Test Case 2: Existing CLAUDE.md Without ChromaDB
# ==============================================================================
test_existing_claudemd_no_chroma() {
    info "Test 2: Existing CLAUDE.md without ChromaDB configuration"
    
    local test_dir=$(setup_test_dir "test2-claudemd-no-chroma")
    
    # Create existing CLAUDE.md
    cat > "$test_dir/CLAUDE.md" << 'EXISTING'
# CLAUDE.md — Project Guidelines

## Project Conventions
- Use TypeScript for all new code
- Follow ESLint configuration
- Write unit tests for all features

## Code Style
- Prefer functional programming
- Use meaningful variable names
EXISTING
    
    # Run auto-setup
    run_auto_setup "$test_dir"
    
    # Verify original content preserved
    if grep -q "## Project Conventions" "$test_dir/CLAUDE.md"; then
        success "Original CLAUDE.md content preserved"
    else
        failure "Original CLAUDE.md content lost"
    fi
    
    # Verify ChromaDB section appended
    if grep -q "## 🧠 Project Memory (Chroma)" "$test_dir/CLAUDE.md"; then
        success "ChromaDB section appended to existing CLAUDE.md"
    else
        failure "ChromaDB section not appended"
    fi
    
    # Verify backup created
    if ls "$test_dir/CLAUDE.md.backup."* 1>/dev/null 2>&1; then
        success "Backup created before modification"
    else
        failure "No backup created"
    fi
}

# ==============================================================================
# Test Case 3: CLAUDE.md Already Has ChromaDB (Idempotency Test)
# ==============================================================================
test_idempotency_claudemd() {
    info "Test 3: CLAUDE.md already has ChromaDB (idempotency)"
    
    local test_dir=$(setup_test_dir "test3-idempotent")
    
    # Create CLAUDE.md with ChromaDB
    cat > "$test_dir/CLAUDE.md" << 'WITH_CHROMA'
# CLAUDE.md

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.
WITH_CHROMA
    
    # Get original checksum
    local original_checksum=$(md5 -q "$test_dir/CLAUDE.md")
    
    # Run auto-setup twice
    run_auto_setup "$test_dir"
    run_auto_setup "$test_dir"
    
    # Get new checksum
    local new_checksum=$(md5 -q "$test_dir/CLAUDE.md")
    
    # Verify file unchanged
    if [ "$original_checksum" = "$new_checksum" ]; then
        success "CLAUDE.md unchanged (idempotent)"
    else
        failure "CLAUDE.md modified when it shouldn't be"
    fi
}

# ==============================================================================
# Test Case 4: Existing settings.local.json Without ChromaDB
# ==============================================================================
test_existing_settings_no_chroma() {
    info "Test 4: Existing settings.local.json without ChromaDB"
    
    local test_dir=$(setup_test_dir "test4-settings-no-chroma")
    mkdir -p "$test_dir/.claude"
    
    # Create existing settings.local.json
    cat > "$test_dir/.claude/settings.local.json" << 'EXISTING_SETTINGS'
{
  "enabledMcpjsonServers": [
    "sequential-thinking",
    "context7"
  ],
  "instructions": [
    "Use TypeScript for all code",
    "Follow project conventions"
  ]
}
EXISTING_SETTINGS
    
    # Run auto-setup
    run_auto_setup "$test_dir"
    
    # Verify chroma added to enabledMcpjsonServers
    if grep -q '"chroma"' "$test_dir/.claude/settings.local.json"; then
        success "chroma added to enabledMcpjsonServers"
    else
        failure "chroma not added to enabledMcpjsonServers"
    fi
    
    # Verify existing servers preserved
    if grep -q '"sequential-thinking"' "$test_dir/.claude/settings.local.json" && \
       grep -q '"context7"' "$test_dir/.claude/settings.local.json"; then
        success "Existing MCP servers preserved"
    else
        failure "Existing MCP servers lost"
    fi
    
    # Verify ChromaDB instructions added
    if grep -q "ChromaDB for persistent memory" "$test_dir/.claude/settings.local.json"; then
        success "ChromaDB instructions added"
    else
        failure "ChromaDB instructions not added"
    fi
    
    # Verify backup created
    if ls "$test_dir/.claude/settings.local.json.backup."* 1>/dev/null 2>&1; then
        success "Backup created for settings.local.json"
    else
        failure "No backup created for settings.local.json"
    fi
}

# ==============================================================================
# Test Case 5: settings.local.json Idempotency
# ==============================================================================
test_idempotency_settings() {
    info "Test 5: settings.local.json already has ChromaDB (idempotency)"
    
    local test_dir=$(setup_test_dir "test5-settings-idempotent")
    mkdir -p "$test_dir/.claude"
    
    # Create settings with ChromaDB
    cat > "$test_dir/.claude/settings.local.json" << 'WITH_CHROMA'
{
  "enabledMcpjsonServers": ["chroma"],
  "mcpServers": {
    "chroma": {
      "alwaysAllow": ["chroma_list_collections"]
    }
  },
  "instructions": [
    "IMPORTANT: This project uses ChromaDB for persistent memory"
  ]
}
WITH_CHROMA
    
    # Get original checksum
    local original_checksum=$(md5 -q "$test_dir/.claude/settings.local.json")
    
    # Run auto-setup twice
    run_auto_setup "$test_dir"
    run_auto_setup "$test_dir"
    
    # Get new checksum
    local new_checksum=$(md5 -q "$test_dir/.claude/settings.local.json")
    
    # Verify file unchanged
    if [ "$original_checksum" = "$new_checksum" ]; then
        success "settings.local.json unchanged (idempotent)"
    else
        failure "settings.local.json modified when it shouldn't be"
    fi
}

# ==============================================================================
# Test Case 6: Mixed State (CLAUDE.md has ChromaDB, settings.local.json doesn't)
# ==============================================================================
test_mixed_state() {
    info "Test 6: Mixed state - CLAUDE.md has ChromaDB, settings.local.json doesn't"
    
    local test_dir=$(setup_test_dir "test6-mixed")
    mkdir -p "$test_dir/.claude"
    
    # Create CLAUDE.md with ChromaDB
    cat > "$test_dir/CLAUDE.md" << 'WITH_CHROMA'
# CLAUDE.md

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.
WITH_CHROMA
    
    # Create settings without ChromaDB
    cat > "$test_dir/.claude/settings.local.json" << 'NO_CHROMA'
{
  "enabledMcpjsonServers": ["sequential-thinking"]
}
NO_CHROMA
    
    # Run auto-setup
    run_auto_setup "$test_dir"
    
    # Verify CLAUDE.md unchanged
    local claudemd_lines=$(wc -l < "$test_dir/CLAUDE.md")
    if [ "$claudemd_lines" -eq 5 ]; then
        success "CLAUDE.md unchanged (already has ChromaDB)"
    else
        failure "CLAUDE.md modified unnecessarily"
    fi
    
    # Verify settings.local.json updated
    if grep -q '"chroma"' "$test_dir/.claude/settings.local.json"; then
        success "settings.local.json updated with ChromaDB"
    else
        failure "settings.local.json not updated"
    fi
}

# ==============================================================================
# Test Case 7: No Duplicate Instructions
# ==============================================================================
test_no_duplicate_instructions() {
    info "Test 7: Ensure no duplicate instructions after multiple runs"
    
    local test_dir=$(setup_test_dir "test7-no-duplicates")
    
    # Run auto-setup three times
    run_auto_setup "$test_dir"
    run_auto_setup "$test_dir"
    run_auto_setup "$test_dir"
    
    # Count ChromaDB instruction occurrences
    local count=$(grep -o "ChromaDB for persistent memory" "$test_dir/.claude/settings.local.json" | wc -l | tr -d ' ')
    
    if [ "$count" -eq 1 ]; then
        success "No duplicate instructions (found $count occurrence)"
    else
        failure "Duplicate instructions found ($count occurrences)"
    fi
}

# ==============================================================================
# Test Case 8: Edge Case - Empty settings.local.json
# ==============================================================================
test_empty_settings() {
    info "Test 8: Edge case - empty settings.local.json"
    
    local test_dir=$(setup_test_dir "test8-empty-settings")
    mkdir -p "$test_dir/.claude"
    
    # Create empty settings
    echo "{}" > "$test_dir/.claude/settings.local.json"
    
    # Run auto-setup
    run_auto_setup "$test_dir"
    
    # Verify valid JSON
    if python3 -m json.tool "$test_dir/.claude/settings.local.json" > /dev/null 2>&1; then
        success "Valid JSON after merging into empty object"
    else
        failure "Invalid JSON after merge"
    fi
    
    # Verify ChromaDB configured
    if grep -q '"chroma"' "$test_dir/.claude/settings.local.json"; then
        success "ChromaDB added to empty settings"
    else
        failure "ChromaDB not added to empty settings"
    fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "=========================================="
echo "ChromaDB Auto-Setup Merge Test Suite"
echo "=========================================="
echo ""

test_fresh_project
echo ""

test_existing_claudemd_no_chroma
echo ""

test_idempotency_claudemd
echo ""

test_existing_settings_no_chroma
echo ""

test_idempotency_settings
echo ""

test_mixed_state
echo ""

test_no_duplicate_instructions
echo ""

test_empty_settings
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed ✗${NC}"
    exit 1
fi
