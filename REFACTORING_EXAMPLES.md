# Concrete Refactoring Examples

## Example 1: Consolidate Memory Discipline Functions

### Before (126 lines total):
```bash
check_global_memory_rules() {
    local readonly GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
    [[ ! -f "$GLOBAL_CLAUDE" ]] && return 2
    [[ ! -r "$GLOBAL_CLAUDE" ]] && return 2
    grep -q "Memory Checkpoint Rules" "$GLOBAL_CLAUDE" 2>/dev/null && return 0 || return 1
}

check_global_settings_memory() {
    local readonly GLOBAL_SETTINGS="$HOME/.claude/settings.local.json"
    [[ ! -f "$GLOBAL_SETTINGS" ]] && return 2
    [[ ! -r "$GLOBAL_SETTINGS" ]] && return 2
    # ... 20 more lines ...
}

ensure_memory_discipline() {
    check_global_memory_rules
    local global_status=$?
    case $global_status in
        0) print_status "✓ Global memory checkpoint rules detected" ;;
        1) create_memory_reminder_doc ;;
        2) create_memory_reminder_doc ;;
    esac
}

ensure_settings_memory_discipline() {
    # Similar pattern, another 32 lines
}
```

### After (35 lines total - 72% reduction):
```bash
# Generic checker for any global config file
check_global_config() {
    local file="$1"
    local pattern="$2"

    [[ ! -f "$file" ]] && return 2
    [[ ! -r "$file" ]] && return 2

    # Special JSON validation for .json files
    if [[ "$file" == *.json ]] && ! jq -e '.' "$file" >/dev/null 2>&1; then
        return 2
    fi

    grep -qi "$pattern" "$file" 2>/dev/null && return 0 || return 1
}

# Single orchestrator for all memory discipline
ensure_memory_config() {
    local config_type="$1"
    local file pattern description create_func

    case "$config_type" in
        claude_md)
            file="$HOME/.claude/CLAUDE.md"
            pattern="Memory Checkpoint Rules"
            description="memory checkpoint rules"
            create_func="create_memory_reminder_doc"
            ;;
        settings)
            file="$HOME/.claude/settings.local.json"
            pattern="memory\|checkpoint\|chroma"
            description="memory instructions"
            create_func="create_project_settings_memory"
            ;;
    esac

    check_global_config "$file" "$pattern"
    case $? in
        0) print_status "✓ Global $description detected" ;;
        *) $create_func ;;
    esac
}

# Usage:
ensure_memory_config "claude_md"
ensure_memory_config "settings"
```

## Example 2: Template Generation Instead of Embedding

### Before (206 lines embedded):
```bash
create_claude_md() {
    local content='# CLAUDE.md — Project Contract

**Purpose**: Follow this in every session for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

## 🧠 Project Memory (Chroma)
... 200 more lines ...
'
    write_file_safe "CLAUDE.md" "$content"
}
```

### After (50 lines with generation):
```bash
# Template components as functions
gen_claude_header() {
    echo "# CLAUDE.md — Project Contract"
    echo ""
    echo "**Purpose**: Follow this in every session for this repo."
}

gen_memory_section() {
    cat <<-'EOF'
    ## 🧠 Project Memory (Chroma)
    Use server chroma, collection project_memory.

    **Schema:**
    - documents: 1-2 sentences, under 300 chars
    - metadatas: { "type":"decision|fix|tip", "tags":"a,b", "source":"file" }
    - ids: stable string for updates
    EOF
}

gen_tool_matrix() {
    echo "## 🛠️ Tool Selection Matrix"
    echo ""
    echo "| Task | Tool |"
    echo "|------|------|"
    local tools=(
        "Multi-file edits|MultiEdit"
        "Pattern search|Grep MCP"
        "UI components|Magic MCP"
    )
    printf '%s\n' "${tools[@]}"
}

create_claude_md() {
    {
        gen_claude_header
        echo ""
        gen_memory_section
        echo ""
        gen_tool_matrix
        echo ""
        echo "## ⚡ Activation"
        echo "Read this file at session start."
        echo "Acknowledge: **Contract loaded. Using Chroma project_memory.**"
    } > CLAUDE.md.tmp

    write_file_safe "CLAUDE.md" "$(<CLAUDE.md.tmp)"
    rm -f CLAUDE.md.tmp
}
```

## Example 3: Prerequisite Checks Modularization

### Before (90 lines in one function):
```bash
check_prerequisites() {
    print_header "🔍 Checking Prerequisites"
    local has_issues=false

    # Check for jq
    if command -v jq >/dev/null 2>&1; then
        local jq_version=$(jq --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        print_status "jq found (version: $jq_version)"
        # ... version checking ...
    else
        print_error "jq is required"
        # ... 10 lines of install instructions ...
        has_issues=true
    fi

    # Check for Python3
    # ... 15 lines ...

    # Check for uvx
    # ... 30 lines with install attempt ...

    # Check Claude CLI
    # ... 10 lines ...

    [[ "$has_issues" == "true" ]] && exit 1
}
```

### After (40 lines with modular checks):
```bash
# Tool check configuration
declare -A TOOLS=(
    [jq]="required|brew install jq|1.5"
    [python3]="optional||3.6"
    [uvx]="required|pip install --user uv|"
    [claude]="optional|https://claude.ai/download|"
)

check_tool() {
    local tool="$1"
    local info="${TOOLS[$tool]}"
    IFS='|' read -r priority install min_version <<< "$info"

    if command -v "$tool" >/dev/null 2>&1; then
        print_status "$tool found"
        [[ -n "$min_version" ]] && check_version "$tool" "$min_version"
        return 0
    else
        [[ "$priority" == "required" ]] && {
            print_error "$tool is required"
            [[ -n "$install" ]] && print_info "Install: $install"
            return 1
        }
        print_info "$tool not found (optional)"
        return 0
    fi
}

check_prerequisites() {
    print_header "🔍 Checking Prerequisites"
    local has_issues=false

    for tool in "${!TOOLS[@]}"; do
        check_tool "$tool" || has_issues=true
    done

    # Special case: try installing uvx if missing
    if ! command -v uvx >/dev/null 2>&1; then
        prompt_yes "Try installing uvx?" && try_install_uvx
    fi

    [[ "$has_issues" == "true" ]] && exit 1
}
```

## Example 4: Shell Function Deduplication

### Before (90+ lines, defined 3 times):
```bash
# In setup function (lines 1507-1539)
function_content='
claude-chroma() {
    # ... 30 lines ...
}'

# In fish setup (lines 1473-1505)
function_content='
function claude-chroma
    # ... 30 lines ...
end'

# In migration (lines 1616-1648)
function_content='
claude-chroma() {
    # ... exact same 30 lines ...
}'
```

### After (40 lines total):
```bash
# Define once as templates
readonly BASH_CLAUDE_FUNC='claude-chroma() {
    local config_file="" search_dir="$PWD"
    while [[ "$search_dir" != "/" ]]; do
        [[ -f "$search_dir/.mcp.json" ]] && {
            config_file="$search_dir/.mcp.json"
            break
        }
        search_dir=$(dirname "$search_dir")
    done

    if [[ -n "$config_file" ]]; then
        cd "$(dirname "$config_file")"
        claude ${@:-chat}
    else
        echo "No ChromaDB config found"
        claude ${@:-chat}
    fi
}'

get_shell_function() {
    case "$(basename "${SHELL:-/bin/bash}")" in
        fish) convert_to_fish "$BASH_CLAUDE_FUNC" ;;
        *)    echo "$BASH_CLAUDE_FUNC" ;;
    esac
}

# Use in all three places:
write_shell_function() {
    local target="$1"
    echo "$(get_shell_function)" >> "$target"
}
```

## Summary of Improvements

| Area | Before | After | Reduction |
|------|--------|-------|-----------|
| Memory functions | 126 lines | 35 lines | 72% |
| CLAUDE.md template | 206 lines | 50 lines | 76% |
| Prerequisites | 90 lines | 40 lines | 56% |
| Shell functions | 90 lines | 40 lines | 56% |
| **Total Example** | **512 lines** | **165 lines** | **68%** |

Applying these patterns throughout would reduce the script from 1,846 to approximately 900-1,000 lines while improving maintainability and preserving self-containment.