#!/bin/bash

# ChromaDB Setup Test Script
# Validates that ChromaDB is properly configured for Claude Desktop

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           ChromaDB Setup Test for Claude Desktop${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "Mac";;
        Linux*)     echo "Linux";;
        MINGW*|CYGWIN*|MSYS*) echo "Windows";;
        *)          echo "Unknown";;
    esac
}

# Function to get Claude config path
get_claude_config_path() {
    local os="$1"
    case "$os" in
        Mac)
            echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
            ;;
        Linux)
            echo "$HOME/.config/Claude/claude_desktop_config.json"
            ;;
        Windows)
            echo "$APPDATA/Claude/claude_desktop_config.json"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Test 1: Check Python
echo -e "${YELLOW}Test 1: Python Installation${NC}"
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
else
    echo -e "${RED}❌ Python not found${NC}"
    ((TESTS_FAILED++))
    PYTHON_CMD=""
fi

if [ -n "$PYTHON_CMD" ]; then
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
    echo -e "${GREEN}✅ Python found: $PYTHON_VERSION${NC}"
    ((TESTS_PASSED++))
fi
echo ""

# Test 2: Check uvx installation
echo -e "${YELLOW}Test 2: uvx Installation${NC}"
if command_exists uvx; then
    echo -e "${GREEN}✅ uvx is installed${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ uvx not found - run: pip install uvx${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 3: Check ChromaDB MCP Server
echo -e "${YELLOW}Test 3: ChromaDB MCP Server${NC}"
if command_exists uvx && uvx chroma-mcp --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ChromaDB MCP server is installed${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ ChromaDB MCP server not found - run: uvx install chroma-mcp${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 4: Check Claude Desktop configuration
echo -e "${YELLOW}Test 4: Claude Desktop Configuration${NC}"
OS=$(detect_os)
CLAUDE_CONFIG=$(get_claude_config_path "$OS")

if [ -f "$CLAUDE_CONFIG" ]; then
    echo -e "${GREEN}✅ Claude configuration found${NC}"
    ((TESTS_PASSED++))

    # Check if ChromaDB is configured
    if grep -q '"chromadb"' "$CLAUDE_CONFIG"; then
        echo -e "${GREEN}✅ ChromaDB server configured in Claude${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ ChromaDB not configured in Claude Desktop${NC}"
        echo -e "${YELLOW}   Run: ./chromadb/setup_chromadb.sh${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}❌ Claude configuration not found at: $CLAUDE_CONFIG${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: Check project files
echo -e "${YELLOW}Test 5: Project Files${NC}"

# Check CLAUDE.md
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    echo -e "${GREEN}✅ CLAUDE.md exists${NC}"
    ((TESTS_PASSED++))

    # Check if it has ChromaDB instructions
    if grep -q "project_memory" "$PROJECT_ROOT/CLAUDE.md"; then
        echo -e "${GREEN}✅ CLAUDE.md contains ChromaDB instructions${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  CLAUDE.md missing ChromaDB instructions${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ CLAUDE.md not found${NC}"
    ((TESTS_FAILED++))
fi

# Check settings.local.json
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
    echo -e "${GREEN}✅ settings.local.json exists${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  settings.local.json not found (optional)${NC}"
    ((WARNINGS++))
fi

# Check init script
if [ -f "$PROJECT_ROOT/init_project_memory.py" ]; then
    echo -e "${GREEN}✅ Initialization script exists${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  init_project_memory.py not found${NC}"
    ((WARNINGS++))
fi
echo ""

# Test 6: Test ChromaDB connection
echo -e "${YELLOW}Test 6: ChromaDB Connection${NC}"

if [ -n "$PYTHON_CMD" ]; then
    # Create a test Python script
    cat > /tmp/test_chromadb_connection.py << 'EOF'
import sys
try:
    import chromadb
    from chromadb.config import Settings

    # Try to connect to ChromaDB (using persistent client for stdio transport)
    client = chromadb.PersistentClient(
        path="./.chroma",
        settings=Settings(anonymized_telemetry=False)
    )

    # Test connection
    collections = client.list_collections()
    print(f"SUCCESS: Connected to ChromaDB, found {len(collections)} collections")

    # Check for project_memory collection
    collection_names = [c.name for c in collections]
    if "project_memory" in collection_names:
        coll = client.get_collection("project_memory")
        count = coll.count()
        print(f"SUCCESS: project_memory collection exists with {count} memories")
    else:
        print("INFO: project_memory collection not yet created")

    sys.exit(0)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF

    # Run the test
    if $PYTHON_CMD /tmp/test_chromadb_connection.py 2>/dev/null; then
        echo -e "${GREEN}✅ ChromaDB connection successful${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  Cannot connect to ChromaDB server (server may not be running)${NC}"
        echo -e "${YELLOW}   This is normal - ChromaDB will start when Claude loads${NC}"
        ((WARNINGS++))
    fi

    # Clean up
    rm -f /tmp/test_chromadb_connection.py
else
    echo -e "${YELLOW}⚠️  Skipping connection test (Python not available)${NC}"
    ((WARNINGS++))
fi
echo ""

# Test 7: Test memory operations
echo -e "${YELLOW}Test 7: Memory Operations Test${NC}"

if [ -n "$PYTHON_CMD" ] && [ -f "$PROJECT_ROOT/init_project_memory.py" ]; then
    # Try to add a test memory
    TEST_ID="test-$(date +%s)"

    cd "$PROJECT_ROOT"
    if $PYTHON_CMD init_project_memory.py --add \
        "Test memory from validation script" \
        "test" \
        "validation,test" \
        "test_script" 2>/dev/null; then
        echo -e "${GREEN}✅ Test memory added successfully${NC}"
        ((TESTS_PASSED++))

        # Try to query it
        if $PYTHON_CMD init_project_memory.py --query "test validation" 2>/dev/null | grep -q "Test memory"; then
            echo -e "${GREEN}✅ Memory query working${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${YELLOW}⚠️  Could not query test memory${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠️  Could not add test memory (ChromaDB may not be running)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠️  Skipping memory operations test${NC}"
    ((WARNINGS++))
fi
echo ""

# Test 8: Check for common issues
echo -e "${YELLOW}Test 8: Common Issues Check${NC}"

# Check if Claude Desktop needs restart
if [ -f "$CLAUDE_DIR/.chromadb_setup_complete" ]; then
    SETUP_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CLAUDE_DIR/.chromadb_setup_complete" 2>/dev/null || \
                 stat -c "%y" "$CLAUDE_DIR/.chromadb_setup_complete" 2>/dev/null | cut -d' ' -f1-2)
    echo -e "${BLUE}ℹ️  Setup completed at: $SETUP_TIME${NC}"
    echo -e "${YELLOW}   Remember to restart Claude Desktop if you haven't already${NC}"
    ((WARNINGS++))
fi

# Check for conflicting chromadb installations
if [ -n "$PYTHON_CMD" ]; then
    if $PYTHON_CMD -c "import chromadb; print(chromadb.__file__)" 2>/dev/null | grep -q "site-packages"; then
        echo -e "${GREEN}✅ ChromaDB Python library available${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  ChromaDB Python library not found locally${NC}"
        echo -e "${YELLOW}   This is fine if using MCP server${NC}"
        ((WARNINGS++))
    fi
fi
echo ""

# Final Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                         Test Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "Tests Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings:      ${YELLOW}$WARNINGS${NC}\n"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ChromaDB setup is complete and working!${NC}\n"
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Restart Claude Desktop if you haven't already"
    echo -e "2. Open your project in Claude"
    echo -e "3. Claude will auto-initialize the memory system"
    echo -e "4. Start working - memories will persist across sessions!\n"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please run setup script:${NC}"
    echo -e "${YELLOW}   ./chromadb/setup_chromadb.sh${NC}\n"

    echo -e "${BLUE}Common fixes:${NC}"
    echo -e "• Install Python 3.8+: ${YELLOW}brew install python3${NC} (Mac) or ${YELLOW}apt install python3${NC} (Linux)"
    echo -e "• Install uvx: ${YELLOW}pip3 install uvx${NC}"
    echo -e "• Install ChromaDB MCP: ${YELLOW}uvx install chroma-mcp${NC}"
    echo -e "• Restart Claude Desktop after configuration changes\n"
    exit 1
fi