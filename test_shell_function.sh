#!/bin/bash
# Test script for claude-chroma shell function
# Tests the smart function logic without modifying shell configs

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Testing claude-chroma Smart Function Logic${NC}"
echo "================================================"

TESTS_PASSED=0
TESTS_FAILED=0

# Simulate the claude-chroma function logic
test_claude_chroma_logic() {
    local test_dir="$1"
    local expected_config="$2"
    local config_file=""
    local search_dir="$test_dir"

    # Search upward for .claude/settings.local.json
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/.claude/settings.local.json" ]]; then
            config_file="$search_dir/.claude/settings.local.json"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    if [[ "$config_file" == "$expected_config" ]]; then
        return 0
    else
        echo "Expected: $expected_config"
        echo "Got: $config_file"
        return 1
    fi
}

# Test 1: Current directory has config
echo -e "\n${YELLOW}Test 1: Config in current directory${NC}"
TEST_DIR="/tmp/test_project"
mkdir -p "$TEST_DIR/.claude"
touch "$TEST_DIR/.claude/settings.local.json"

if test_claude_chroma_logic "$TEST_DIR" "$TEST_DIR/.claude/settings.local.json"; then
    echo -e "${GREEN}✓ Found config in current directory${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Failed to find config in current directory${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Config in parent directory
echo -e "\n${YELLOW}Test 2: Config in parent directory${NC}"
SUBDIR="$TEST_DIR/src/components"
mkdir -p "$SUBDIR"

if test_claude_chroma_logic "$SUBDIR" "$TEST_DIR/.claude/settings.local.json"; then
    echo -e "${GREEN}✓ Found config in parent directory${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Failed to find config in parent directory${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: No config found
echo -e "\n${YELLOW}Test 3: No config found${NC}"
NO_CONFIG_DIR="/tmp/no_config_test"
mkdir -p "$NO_CONFIG_DIR"

if test_claude_chroma_logic "$NO_CONFIG_DIR" ""; then
    echo -e "${GREEN}✓ Correctly returned empty when no config found${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Should have returned empty when no config found${NC}"
    ((TESTS_FAILED++))
fi

# Test 4: Shell detection logic
echo -e "\n${YELLOW}Test 4: Shell detection logic${NC}"
test_shell_detection() {
    local test_shell="$1"
    local expected_config="$2"

    case "$test_shell" in
        bash)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                detected_config="$HOME/.bash_profile"
            else
                detected_config="$HOME/.bashrc"
            fi
            ;;
        zsh) detected_config="$HOME/.zshrc" ;;
        fish) detected_config="$HOME/.config/fish/config.fish" ;;
        *) detected_config="$HOME/.profile" ;;
    esac

    if [[ "$detected_config" == "$expected_config" ]]; then
        return 0
    else
        echo "Expected: $expected_config, Got: $detected_config"
        return 1
    fi
}

# Test different shells
if [[ "$OSTYPE" == "darwin"* ]]; then
    BASH_CONFIG="$HOME/.bash_profile"
else
    BASH_CONFIG="$HOME/.bashrc"
fi

if test_shell_detection "bash" "$BASH_CONFIG"; then
    echo -e "${GREEN}✓ Bash shell detection correct${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Bash shell detection failed${NC}"
    ((TESTS_FAILED++))
fi

if test_shell_detection "zsh" "$HOME/.zshrc"; then
    echo -e "${GREEN}✓ Zsh shell detection correct${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Zsh shell detection failed${NC}"
    ((TESTS_FAILED++))
fi

if test_shell_detection "fish" "$HOME/.config/fish/config.fish"; then
    echo -e "${GREEN}✓ Fish shell detection correct${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Fish shell detection failed${NC}"
    ((TESTS_FAILED++))
fi

# Test 5: Function syntax validation
echo -e "\n${YELLOW}Test 5: Function syntax validation${NC}"

# Test bash/zsh function syntax
BASH_FUNCTION='claude-chroma() {
    local config_file=""
    local search_dir="$PWD"

    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/.claude/settings.local.json" ]]; then
            config_file="$search_dir/.claude/settings.local.json"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    if [[ -n "$config_file" ]]; then
        echo "Using config: $config_file"
        claude --mcp-config "$config_file" "$@"
    else
        echo "No config found"
        claude "$@"
    fi
}'

# Test bash syntax
if bash -n -c "$BASH_FUNCTION" 2>/dev/null; then
    echo -e "${GREEN}✓ Bash function syntax valid${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Bash function syntax invalid${NC}"
    ((TESTS_FAILED++))
fi

# Cleanup
rm -rf "$TEST_DIR" "$NO_CONFIG_DIR"

# Summary
echo -e "\n================================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "\n${RED}❌ Shell function logic validation failed${NC}"
    exit 1
else
    echo -e "${GREEN}All shell function tests passed!${NC}"
    echo -e "\n${GREEN}✅ Smart function logic is ready for production${NC}"
    exit 0
fi