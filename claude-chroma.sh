#!/bin/bash
# ChromaDB setup for Claude projects - Production-ready version
# Version 3.4.5 - Remove 'chat' command to prevent auto-typing bug
# v3.4.5 Changes:
# - Removed all 'claude' references - just use 'claude' command
# - Prevents Claude from auto-typing 'chat' and going on coding sprees
# v3.4.4 Changes:
# - CRITICAL FIX: Fixed ERR trap causing .mcp.json and CLAUDE.md to be deleted
# - The ERR trap was firing during expected non-zero returns, causing rollback
# - Now properly disables both 'set -e' AND the ERR trap when checking global files
# v3.4.3 Changes:
# - Added READ-ONLY detection of global settings.local.json memory instructions
# - NEVER modifies global ~/.claude/settings.local.json (safety guaranteed)
# - Creates/updates project .claude/settings.local.json with memory instructions
# - Merges memory instructions with existing project settings if present
# v3.4.2 Changes:
# - Added READ-ONLY detection of global memory checkpoint rules
# - NEVER modifies global ~/.claude/CLAUDE.md (safety guaranteed)
# - Creates local MEMORY_CHECKPOINT_REMINDER.md if global lacks rules
# - Ensures memory discipline without touching global configuration
# v3.4.1 Changes:
# - Restored memory checkpoint rules that were accidentally removed in 3.4.0
# - Added explicit reminders for long coding sessions (>10 interactions)
# - Enhanced activation section with memory internalization steps
# v3.4.0 Changes:
# - Replaced basic ChromaDB-only template with comprehensive project contract
# - Added tool selection matrix, additional MCP servers, session lifecycle
# - Includes browser automation, GitHub workflow, quality gates
# v3.3.6 Changes:
# - Added instruction to query existing memories at session start
# - Claude now automatically reviews project context when starting
# - Better continuity between sessions
# v3.3.5 Changes:
# - Updated CLAUDE.md to handle ChromaDB returning None on success
# - Changed memory logging instruction to not expect ID back
# - Clearer success confirmation without showing 'None' result
# v3.3.4 Changes:
# - Fixed CLAUDE.md causing Claude to auto-type 'chat'
# - Changed 'Read this file at chat start' to 'Read this file at session start'
# - Changed 'Follow this in every chat' to 'Follow this in every session'
# v3.3.3 Changes:
# - Previously used 'claude chat' but removed to prevent auto-typing bug
# - Added explicit note to prevent users from typing 'chat' after starting claude
# - Improved launcher script messaging
# v3.3.2 Changes:
# - Improved CLAUDE.md handling to preserve existing user instructions
# - Creates CLAUDE.md.original backup for easy reference
# - No longer prompts to overwrite, automatically backs up existing content
# - Adds clear messaging about where original instructions are preserved
# v3.3.1 Changes:
# - Relaxed character validation to allow apostrophes, brackets, parentheses
# - Now only blocks backticks and $ for command substitution prevention
# - Fixes support for paths like "John's Documents" and "Files [2025]"
# v3.3.0 Changes:
# - Added infinite timeout settings to prevent session disconnections
# - Auto-detect and fix broken shell functions from older versions
# - Validate and update existing .mcp.json files without timeout settings
# - Made script fully self-contained for portable deployments
# Previous v3.2 features:
# - Fixed path validation to allow spaces
# - Added comprehensive input sanitization
# - Atomic writes with automatic backups
# - Safe JSON generation and validation
# - Proper rollback on failure
# - Dry-run mode support

# ============================================================================
# SAFETY RAILS
# ============================================================================
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

# ============================================================================
# GLOBALS
# ============================================================================
readonly SCRIPT_VERSION="3.5.2"
readonly CHROMA_MCP_VERSION="chroma-mcp==0.2.0"

# Environment flags
DRY_RUN="${DRY_RUN:-0}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
DEBUG="${DEBUG:-0}"

# Track files for rollback
TOUCHED_FILES=()
CLEANUP_FILES=()

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# ERROR HANDLING & CLEANUP
# ============================================================================
on_err() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "Setup failed (exit code: $exit_code). Rolling back changes..."
        rollback_changes
    fi
}

rollback_changes() {
    if [[ ${#TOUCHED_FILES[@]} -gt 0 ]]; then
        for file in "${TOUCHED_FILES[@]}"; do
            if compgen -G "$file.backup.*" >/dev/null; then
                local latest_backup
                latest_backup=$(ls -t "$file.backup."* 2>/dev/null | head -1 || true)
                [[ -n "$latest_backup" ]] && mv -f "$latest_backup" "$file" 2>/dev/null && \
                    print_info "Restored: $file" || true
            else
                rm -f "$file" 2>/dev/null && \
                    print_info "Removed: $file" || true
            fi
        done
    fi

    if [[ ${#CLEANUP_FILES[@]} -gt 0 ]]; then
        for temp_file in "${CLEANUP_FILES[@]}"; do
            rm -f "$temp_file" 2>/dev/null || true
        done
    fi
}

cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        on_err
    fi

    # Clean temporary files regardless of exit status
    if [[ ${#CLEANUP_FILES[@]} -gt 0 ]]; then
        for temp_file in "${CLEANUP_FILES[@]}"; do
            rm -f "$temp_file" 2>/dev/null || true
        done
    fi
}

trap cleanup_on_exit EXIT
trap on_err ERR

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

debug_log() {
    [[ "$DEBUG" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $1" >&2 || true
}

# ============================================================================
# PATH SAFETY FUNCTIONS
# ============================================================================
require_realpath() {
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - <<'PY' "$1"
import os,sys; print(os.path.realpath(sys.argv[1]))
PY
    else
        echo "$(cd "$(dirname "$1")" 2>/dev/null && pwd)/$(basename "$1")"
    fi
}

assert_within() {
    local child="$(require_realpath "$1")"
    local parent="$(require_realpath "$2")"
    case "$child" in
        "$parent"/*|"$parent") ;;
        *)
            print_error "Path escapes project"
            print_info "Child: $child"
            print_info "Root: $parent"
            exit 1
            ;;
    esac
}

# ============================================================================
# INPUT VALIDATION & SANITIZATION
# ============================================================================
# Security Model:
# - We only block characters that enable command execution (backticks, $)
# - Apostrophes, quotes, brackets, parentheses are SAFE when properly quoted
# - The script uses proper quoting everywhere: "$VAR" in shell, jq --arg for JSON
# - This allows legitimate paths like "John's Documents" or "Files [2025]"
#
# Previous overly-strict pattern that blocked too many valid characters:
# readonly dangerous_char_class='[`$(){}[\]<>|&;"]'
#
# Minimal pattern - blocks only command substitution risks:
readonly dangerous_char_class='[`$]'
# Note: Could be even more permissive with just '[`]' if $ in paths needed

sanitize_input() {
    # Strips traversal attempts and dangerous characters
    local input="${1:-}"

    # Remove directory traversal attempts
    input="${input//..\/}"
    input="${input//\/..\//\/}"

    # Remove dangerous metacharacters but keep spaces
    input="${input//[$dangerous_char_class]/}"

    printf '%s' "$input"
}

validate_path() {
    local path="${1:-}"

    # Allow spaces but forbid truly dangerous metacharacters
    if [[ "$path" =~ [$dangerous_char_class] ]]; then
        print_error "Invalid path: contains command execution characters"
        print_info "Path: $path"
        print_info "Remove these characters: \` \$ (backtick and dollar sign)"
        print_info "These enable command substitution and must be blocked for security"
        return 1
    fi

    # Check for directory traversal
    if [[ "$path" =~ \.\. ]]; then
        print_error "Invalid path: contains directory traversal"
        return 1
    fi

    return 0
}

validate_project_name() {
    local name="${1:-}"

    # Project names should be simple
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        print_error "Invalid project name: $name"
        print_info "Use only letters, numbers, dots, underscores, and hyphens"
        print_info "Must start with a letter or number"
        return 1
    fi

    return 0
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="$file.backup.$(date +%Y%m%d_%H%M%S)"
        if [[ "$DRY_RUN" == "1" ]]; then
            print_info "[dry-run] Would backup $file to $backup_name"
        else
            cp -p "$file" "$backup_name" && \
                debug_log "Backed up: $file → $backup_name"
            # Prune old backups (keep last 5)
            prune_backups "$file"
        fi
    fi
}

# Prune old backups keeping only the last N
prune_backups() {
    local file="$1"
    local keep="${BACKUP_KEEP:-5}"

    if [[ "$DRY_RUN" == "1" ]]; then
        debug_log "[dry-run] Would prune backups for $file (keeping $keep)"
        return
    fi

    # List backups sorted by time, remove oldest if > $keep
    local count=0
    ls -t "${file}.backup."* 2>/dev/null | while read -r backup; do
        ((count++))
        if [[ $count -gt $keep ]]; then
            debug_log "Removing old backup: $backup"
            rm -f "$backup"
        fi
    done
}

# Special backup for CLAUDE.md that preserves user content clearly
backup_claude_md() {
    if [[ -f "CLAUDE.md" ]]; then
        # Create timestamped backup for safety
        local timestamped_backup="CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"

        if [[ "$DRY_RUN" == "1" ]]; then
            print_info "[dry-run] Would backup CLAUDE.md to:"
            print_info "  → $timestamped_backup (timestamped safety backup)"
            print_info "  → CLAUDE.md.original (for easy reference)"
        else
            # Create timestamped backup
            cp -p "CLAUDE.md" "$timestamped_backup" && \
                debug_log "Created timestamped backup: $timestamped_backup"

            # Also create/update .original for easy user reference
            cp -p "CLAUDE.md" "CLAUDE.md.original" && \
                debug_log "Created reference copy: CLAUDE.md.original"

            print_info "📁 Preserved your existing CLAUDE.md:"
            print_info "  → CLAUDE.md.original (your custom instructions)"
            print_info "  → $timestamped_backup (timestamped backup)"
        fi
        return 0
    fi
    return 1
}

# ============================================================================
# MEMORY DISCIPLINE CHECKS (READ-ONLY for global files)
# ============================================================================
# These functions NEVER modify global ~/.claude/CLAUDE.md
# They only read to check status and create local project reminders if needed

check_global_memory_rules() {
    # READ-ONLY check if global CLAUDE.md has memory checkpoint rules
    # Returns: 0 if rules exist, 1 if not, 2 if file doesn't exist

    local readonly GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.claude}"
    local readonly GLOBAL_CLAUDE="$GLOBAL_DIR/CLAUDE.md"

    # Check if global file exists (READ-ONLY)
    if [[ ! -f "$GLOBAL_CLAUDE" ]]; then
        debug_log "Global CLAUDE.md not found at $GLOBAL_CLAUDE"
        return 2
    fi

    # Check if file is readable (no modification attempt)
    if [[ ! -r "$GLOBAL_CLAUDE" ]]; then
        debug_log "Global CLAUDE.md exists but not readable"
        return 2
    fi

    # READ-ONLY grep check for memory checkpoint rules
    if grep -q "Memory Checkpoint Rules" "$GLOBAL_CLAUDE" 2>/dev/null; then
        debug_log "Memory checkpoint rules found in global CLAUDE.md"
        return 0
    else
        debug_log "Memory checkpoint rules NOT found in global CLAUDE.md"
        return 1
    fi
}

create_memory_reminder_doc() {
    # Creates a LOCAL project file with memory reminders
    # Never touches global files

    print_info "Creating local memory reminder document..."

    local content='# 📝 MEMORY CHECKPOINT REMINDER

**IMPORTANT**: Your global CLAUDE.md may not have memory checkpoint rules.
This local reminder ensures you maintain memory discipline in this project.

## Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, pause and check:
- Did I discover new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve tricky problems or learn about architecture?

If yes → Log memory IMMEDIATELY:
```javascript
mcp__chroma__chroma_add_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "documents": ["<discovery under 300 chars>"],
  "metadatas": [{"type":"decision|fix|tip|preference","tags":"relevant,tags","source":"file"}],
  "ids": ["<unique-id>"]
}
```

**During long sessions (>10 interactions)**:
- Stop and review: Have I logged recent learnings?
- Check for unrecorded decisions or fixes
- Remember: Each memory helps future sessions

## At Session Start

Always query existing memories first:
```javascript
mcp__chroma__chroma_query_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "query_texts": ["project decisions preferences fixes patterns"],
  "n_results": 5  // raise to 10 only if <3 strong hits
}
```

---
*This file was created because memory checkpoint rules were not detected in global CLAUDE.md*
*To add them globally (optional): Add the rules to ~/.claude/CLAUDE.md manually*'

    write_file_safe "MEMORY_CHECKPOINT_REMINDER.md" "$content"
    print_status "Created MEMORY_CHECKPOINT_REMINDER.md"
    print_info "💡 This ensures memory discipline for this project"
}

ensure_memory_discipline() {
    # Orchestrates memory discipline setup
    # NEVER modifies global files, only creates local supplements

    print_info "Checking memory discipline configuration..."

    # READ-ONLY check of global configuration
    # Must disable both error exit AND the ERR trap to prevent rollback
    set +e  # Temporarily disable exit on error
    trap - ERR  # Temporarily disable the ERR trap
    check_global_memory_rules
    local global_status=$?
    set -e  # Re-enable exit on error
    trap on_err ERR  # Re-enable the ERR trap

    case $global_status in
        0)
            print_status "✓ Global memory checkpoint rules detected"
            print_info "Memory discipline is configured globally"
            ;;
        1)
            print_warning "Memory checkpoint rules not found in global CLAUDE.md"
            print_info "Creating local reminder to ensure memory discipline..."
            create_memory_reminder_doc
            print_info "💡 Consider adding memory rules to ~/.claude/CLAUDE.md for all projects"
            ;;
        2)
            print_info "Global CLAUDE.md not accessible"
            print_info "Creating local memory reminder for this project..."
            create_memory_reminder_doc
            ;;
    esac

    # Always ensure project CLAUDE.md has memory rules (already handled in create_claude_md)
    return 0
}

# ============================================================================
# SETTINGS.LOCAL.JSON MEMORY CHECKS (READ-ONLY for global files)
# ============================================================================
# These functions NEVER modify global ~/.claude/settings.local.json
# They only read to check status and create local project settings if needed

check_global_settings_memory() {
    # READ-ONLY check if global settings.local.json has memory instructions
    # Returns: 0 if has memory instructions, 1 if not, 2 if file doesn't exist or invalid

    local readonly GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.claude}"
    local readonly GLOBAL_SETTINGS="$GLOBAL_DIR/settings.local.json"

    # Check if global file exists (READ-ONLY)
    if [[ ! -f "$GLOBAL_SETTINGS" ]]; then
        debug_log "Global settings.local.json not found at $GLOBAL_SETTINGS"
        return 2
    fi

    # Check if file is readable (no modification attempt)
    if [[ ! -r "$GLOBAL_SETTINGS" ]]; then
        debug_log "Global settings.local.json exists but not readable"
        return 2
    fi

    # Validate JSON structure (READ-ONLY)
    if ! jq -e '.' "$GLOBAL_SETTINGS" >/dev/null 2>&1; then
        debug_log "Global settings.local.json has invalid JSON"
        return 2
    fi

    # READ-ONLY check for memory-related instructions
    # Extract instructions array and check for memory keywords
    # Note: jq without -e to handle missing instructions field gracefully
    local instructions_content
    instructions_content=$(jq -r '.instructions[]?' "$GLOBAL_SETTINGS" 2>/dev/null || echo "")

    if [[ -n "$instructions_content" ]] && echo "$instructions_content" | \
       grep -qi 'memory\|checkpoint\|chroma\|interactions\|discoveries' 2>/dev/null; then
        debug_log "Memory instructions found in global settings.local.json"
        return 0
    else
        debug_log "Memory instructions NOT found in global settings.local.json"
        return 1
    fi
}

create_project_settings_memory() {
    # Creates/updates LOCAL project .claude/settings.local.json with memory instructions
    # Never touches global settings files

    print_info "Configuring project settings with memory instructions..."

    local project_settings_dir=".claude"
    local project_settings_file="$project_settings_dir/settings.local.json"

    # Create .claude directory if it doesn't exist
    if [[ ! -d "$project_settings_dir" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            print_info "[dry-run] Would create directory: $project_settings_dir"
        else
            mkdir -p "$project_settings_dir"
            touch_track "$project_settings_dir"
        fi
    fi

    # Memory discipline instructions
    local memory_instructions='[
        "IMPORTANT: This project uses ChromaDB for persistent memory",
        "Every 5 interactions, check if you have logged recent learnings",
        "After solving problems or making decisions, immediately log to ChromaDB",
        "Use mcp__chroma__chroma_add_documents to preserve discoveries",
        "Query existing memories at session start with mcp__chroma__chroma_query_documents",
        "Each memory should be under 300 chars with appropriate metadata",
        "Log architecture decisions, user preferences, fixes, and patterns"
    ]'

    local new_settings=""

    # Check if project settings already exists
    if [[ -f "$project_settings_file" ]]; then
        print_info "Existing project settings.local.json found"

        if [[ "$DRY_RUN" == "1" ]]; then
            print_info "[dry-run] Would merge memory instructions into existing settings"
        else
            # Backup existing file
            backup_if_exists "$project_settings_file"

            # Check if it has instructions already
            local has_instructions=$(jq -e '.instructions' "$project_settings_file" 2>/dev/null && echo "yes" || echo "no")

            if [[ "$has_instructions" == "yes" ]]; then
                # Merge memory instructions with existing
                new_settings=$(jq \
                    --argjson mem_inst "$memory_instructions" \
                    '.instructions = (.instructions + $mem_inst | unique)' \
                    "$project_settings_file")
            else
                # Add instructions field
                new_settings=$(jq \
                    --argjson mem_inst "$memory_instructions" \
                    '. + {instructions: $mem_inst}' \
                    "$project_settings_file")
            fi
        fi
    else
        # Create new settings file with memory instructions
        if [[ "$DRY_RUN" == "1" ]]; then
            print_info "[dry-run] Would create project settings with memory instructions"
        else
            new_settings=$(jq -n \
                --argjson mem_inst "$memory_instructions" \
                '{
                    instructions: $mem_inst,
                    permissions: {
                        allow: [],
                        deny: [],
                        ask: []
                    }
                }')
        fi
    fi

    if [[ "$DRY_RUN" != "1" ]] && [[ -n "$new_settings" ]]; then
        write_file_safe "$project_settings_file" "$new_settings"
        print_status "Project settings configured with memory instructions"
    fi

    print_info "💡 Project .claude/settings.local.json ensures memory discipline"
}

ensure_settings_memory_discipline() {
    # Orchestrates settings.json memory discipline setup
    # NEVER modifies global files, only creates/updates project settings

    print_info "Checking settings.json memory configuration..."

    # READ-ONLY check of global settings
    # Must disable both error exit AND the ERR trap to prevent rollback
    set +e  # Temporarily disable exit on error
    trap - ERR  # Temporarily disable the ERR trap
    check_global_settings_memory
    local global_settings_status=$?
    set -e  # Re-enable exit on error
    trap on_err ERR  # Re-enable the ERR trap

    case $global_settings_status in
        0)
            print_status "✓ Global settings.json has memory instructions"
            print_info "Creating project settings to reinforce memory discipline..."
            create_project_settings_memory
            ;;
        1)
            print_warning "Memory instructions not found in global settings.json"
            print_info "Creating project settings with memory instructions..."
            create_project_settings_memory
            print_info "💡 Consider adding memory instructions to ~/.claude/settings.local.json"
            ;;
        2)
            print_info "Global settings.json not accessible or invalid"
            print_info "Creating project settings with memory instructions..."
            create_project_settings_memory
            ;;
    esac

    return 0
}

atomic_write() {
    # Write content atomically using temp file and rename
    local dest="$1"
    local content="$2"

    # Create temp file in same directory as destination
    local temp_file
    temp_file="$(mktemp "${dest}.XXXXXX")"
    CLEANUP_FILES+=("$temp_file")

    # Write content
    printf '%s' "$content" > "$temp_file"

    # Atomic rename
    mv -f "$temp_file" "$dest"

    # Remove from cleanup since it's been renamed
    CLEANUP_FILES=("${CLEANUP_FILES[@]/$temp_file/}")
}

write_file_safe() {
    local dest="$1"
    local content="$2"

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[dry-run] Would write $dest (${#content} bytes)"
        debug_log "[dry-run] First 100 chars: ${content:0:100}..."
        return 0
    fi

    backup_if_exists "$dest"
    atomic_write "$dest" "$content"
    touch_track "$dest"
}

touch_track() {
    # Track file for potential rollback
    local file="$1"
    TOUCHED_FILES+=("$file")
    debug_log "Tracking file for rollback: $file"
}

# ============================================================================
# JSON OPERATIONS
# ============================================================================
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "Missing required command: $cmd"
        if [[ -n "$install_hint" ]]; then
            print_info "$install_hint"
        fi
        exit 1
    fi
}

json_emit_mcp_config() {
    # Generate MCP configuration JSON safely with infinite timeout settings
    local command="$1"
    local data_dir="$2"

    require_cmd jq "Install with: brew install jq (Mac) or apt-get install jq (Linux)"

    jq -n \
        --arg cmd "$command" \
        --arg dir "$data_dir" \
        '{
          mcpServers: {
            chroma: {
              type: "stdio",
              command: $cmd,
              args: ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", $dir],
              env: {
                ANONYMIZED_TELEMETRY: "FALSE",
                PYTHONUNBUFFERED: "1",
                TOKENIZERS_PARALLELISM: "False",
                CHROMA_SERVER_KEEP_ALIVE: "0",
                CHROMA_CLIENT_TIMEOUT: "0"
              },
              initializationOptions: {
                timeout: 0,
                keepAlive: true,
                retryAttempts: 5
              }
            }
          }
        }'
}

json_validate() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi

    if jq -e '.' "$file" >/dev/null 2>&1; then
        return 0
    else
        print_error "Invalid JSON in file: $file"
        if [[ "$DEBUG" == "1" ]]; then
            jq '.' "$file" 2>&1 | head -10
        fi
        return 1
    fi
}

json_merge_mcp_config() {
    # Merge ChromaDB config into existing .mcp.json with infinite timeout settings
    local existing_file="$1"
    local command="$2"
    local data_dir="$3"

    require_cmd jq "Install with: brew install jq (Mac) or apt-get install jq (Linux)"

    jq \
        --arg cmd "$command" \
        --arg dir "$data_dir" \
        '.mcpServers = (.mcpServers // {}) |
         .mcpServers.chroma = {
           type: "stdio",
           command: $cmd,
           args: ["-qq", "chroma-mcp", "--client-type", "persistent", "--data-dir", $dir],
           env: {
             ANONYMIZED_TELEMETRY: "FALSE",
             PYTHONUNBUFFERED: "1",
             TOKENIZERS_PARALLELISM: "False",
             CHROMA_SERVER_KEEP_ALIVE: "0",
             CHROMA_CLIENT_TIMEOUT: "0"
           },
           initializationOptions: {
             timeout: 0,
             keepAlive: true,
             retryAttempts: 5
           }
         }' "$existing_file"
}

# ============================================================================
# SHELL DETECTION & CONFIGURATION
# ============================================================================
detect_shell_rc() {
    # Detect appropriate shell configuration file
    local shell_path="${SHELL:-/bin/bash}"
    local shell_name
    shell_name=$(basename "$shell_path")

    case "$shell_name" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            # Prefer .bashrc but check for .bash_profile on macOS
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ "$OSTYPE" == "darwin"* ]] && [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

ensure_path_line() {
    local line='export PATH="$HOME/.local/bin:$PATH"'
    local rc_file
    rc_file=$(detect_shell_rc)

    if [[ "$DRY_RUN" == "1" ]]; then
        if ! grep -Fq "$line" "$rc_file" 2>/dev/null; then
            print_info "[dry-run] Would add PATH line to $rc_file"
        fi
        return 0
    fi

    backup_if_exists "$rc_file"

    if ! grep -Fq "$line" "$rc_file" 2>/dev/null; then
        printf '\n%s\n' "$line" >> "$rc_file"
        print_status "Added PATH to $rc_file"
        touch_track "$rc_file"
    else
        debug_log "PATH line already exists in $rc_file"
    fi
}

# ============================================================================
# TIMEOUT SUPPORT
# ============================================================================
run_with_timeout() {
    # Run command with timeout (portable across macOS and Linux)
    local timeout_secs="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_secs" "$@"
    else
        # Python fallback
        python3 - <<EOF "$timeout_secs" "$@"
import subprocess, sys, time
secs = int(sys.argv[1])
cmd = sys.argv[2:]
p = subprocess.Popen(cmd)
start = time.time()
while p.poll() is None and time.time() - start < secs:
    time.sleep(0.05)
if p.poll() is None:
    p.terminate()
    time.sleep(0.5)
    if p.poll() is None:
        p.kill()
    sys.exit(124)
sys.exit(p.returncode)
EOF
    fi
}

# ============================================================================
# PROMPTS & USER INTERACTION
# ============================================================================
prompt_yes() {
    local question="$1"

    if [[ "$NON_INTERACTIVE" == "1" ]]; then
        if [[ "$ASSUME_YES" == "1" ]]; then
            debug_log "Non-interactive mode: assuming YES for '$question'"
            return 0
        else
            debug_log "Non-interactive mode: assuming NO for '$question'"
            return 1
        fi
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[dry-run] Would prompt: $question"
        return 0
    fi

    local answer
    read -r -p "$question [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================
check_prerequisites() {
    print_header "🔍 Checking Prerequisites"

    local has_issues=false

    # Check for jq (required for JSON operations)
    if command -v jq >/dev/null 2>&1; then
        local jq_version
        jq_version=$(jq --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0.0")
        print_status "jq found (version: $jq_version)"

        # Check minimum version (1.5+)
        if [[ "${jq_version%.*}" -lt 1 ]] || { [[ "${jq_version%.*}" -eq 1 ]] && [[ "${jq_version#*.}" -lt 5 ]]; }; then
            print_warning "jq version $jq_version is old. Recommend 1.6+"
        fi
    else
        print_error "jq is required for JSON operations"
        print_info "Install with:"
        print_info "  macOS: brew install jq"
        print_info "  Ubuntu: apt-get install jq"
        print_info "  Other: https://stedolan.github.io/jq/download/"
        has_issues=true
    fi

    # Check for Python3 (fallback for various operations)
    if command -v python3 >/dev/null 2>&1; then
        local python_version
        python_version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' || echo "0.0")
        print_status "Python3 found (version: $python_version)"
    else
        print_warning "Python3 not found (used for fallback operations)"
    fi

    # Check for uvx
    if ! command -v uvx >/dev/null 2>&1; then
        print_error "uvx is not installed"
        print_info "ChromaDB MCP server requires uvx"
        print_info ""
        print_info "Install options:"
        print_info "  1. pip install --user uv"
        print_info "  2. pipx install uv"
        print_info "  3. brew install uv (macOS/Linux)"
        print_info "  4. https://github.com/astral-sh/uv"

        if prompt_yes "Try installing with pip?"; then
            print_info "Installing uv with pip..."
            if pip install --user uv || pip3 install --user uv; then
                ensure_path_line
                export PATH="$HOME/.local/bin:$PATH"

                if command -v uvx >/dev/null 2>&1; then
                    print_status "uvx installed successfully"
                else
                    print_error "uvx installed but not in PATH"
                    print_info "Restart terminal or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
                    has_issues=true
                fi
            else
                print_error "Failed to install uv"
                has_issues=true
            fi
        else
            has_issues=true
        fi
    else
        print_status "uvx found at: $(command -v uvx)"
    fi

    # Check Claude CLI (optional)
    if command -v claude >/dev/null 2>&1; then
        print_status "claude CLI found"
    else
        print_info "claude CLI not found (optional)"
        print_info "Install from: https://claude.ai/download"
    fi

    # Test ChromaDB MCP server
    if command -v uvx >/dev/null 2>&1; then
        print_info "Testing ChromaDB MCP server..."
        if run_with_timeout 5 uvx -qq "$CHROMA_MCP_VERSION" --help >/dev/null 2>&1; then
            print_status "ChromaDB MCP server is available"
        else
            print_info "ChromaDB MCP server will be installed on first use"
        fi
    fi

    if [[ "$has_issues" == "true" ]]; then
        print_error "Missing required dependencies"
        exit 1
    fi
}

# ============================================================================
# MAIN SETUP FUNCTIONS
# ============================================================================
setup_project_directory() {
    local project_name="$1"
    local project_path="$2"

    # Validate inputs
    if [[ -n "$project_name" ]] && ! validate_project_name "$project_name"; then
        exit 1
    fi

    if ! validate_path "$project_path"; then
        exit 1
    fi

    # Determine project directory
    if [[ -z "$project_name" ]]; then
        # Use current directory
        PROJECT_DIR="$(pwd)"
        PROJECT_NAME="$(basename "$PROJECT_DIR")"
        print_header "🚀 Setting up ChromaDB in current directory"
        print_info "Project: $PROJECT_NAME"
        print_info "Path: $PROJECT_DIR"
    else
        PROJECT_DIR="$project_path/$project_name"
        PROJECT_NAME="$project_name"
        print_header "🚀 Setting up ChromaDB for: $project_name"
        print_info "Path: $PROJECT_DIR"

        # Create or verify directory
        if [[ -d "$PROJECT_DIR" ]]; then
            print_info "Directory exists"
            if ! prompt_yes "Add ChromaDB to existing project?"; then
                print_info "Setup cancelled"
                exit 0
            fi
        else
            if [[ "$DRY_RUN" == "1" ]]; then
                print_info "[dry-run] Would create directory: $PROJECT_DIR"
            else
                mkdir -p "$PROJECT_DIR"
                print_status "Created directory"
                touch_track "$PROJECT_DIR"
            fi
        fi

        # Only cd if not in dry-run mode (directory won't exist in dry-run)
        if [[ "$DRY_RUN" != "1" ]]; then
            cd "$PROJECT_DIR"
        fi
    fi
}

create_directory_structure() {
    print_info "Creating directory structure..."

    local dirs=(".chroma" ".chroma/context" "claudedocs" "bin")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "$DRY_RUN" == "1" ]]; then
                print_info "[dry-run] Would create directory: $dir"
            else
                mkdir -p "$dir"
                touch_track "$dir"
                debug_log "Created directory: $dir"
            fi
        fi
    done

    print_status "Directory structure ready"
}

create_mcp_config() {
    print_info "Configuring MCP server..."

    local uvx_cmd="uvx"  # Use command name, not full path
    local data_dir="${DATA_DIR_OVERRIDE:-$(pwd)/.chroma}"

    # Validate the data directory path
    if ! validate_path "$data_dir"; then
        print_error "Invalid data directory path"
        exit 1
    fi

    # Ensure data directory doesn't escape project
    assert_within "$data_dir" "$(pwd)"

    if [[ -f ".mcp.json" ]]; then
        print_info "Existing .mcp.json found"

        if ! json_validate ".mcp.json"; then
            print_error "Existing .mcp.json is invalid"
            if prompt_yes "Backup and create new config?"; then
                backup_if_exists ".mcp.json"
                SKIP_MCP=false
            else
                exit 1
            fi
        elif grep -q '"chroma"' .mcp.json 2>/dev/null; then
            print_info "ChromaDB already configured"
            if prompt_yes "Update ChromaDB configuration?"; then
                backup_if_exists ".mcp.json"
                SKIP_MCP=false
            else
                SKIP_MCP=true
            fi
        else
            print_info "Merging ChromaDB into existing configuration"
            backup_if_exists ".mcp.json"

            local merged_config
            merged_config=$(json_merge_mcp_config ".mcp.json" "$uvx_cmd" "$data_dir")

            write_file_safe ".mcp.json" "$merged_config"
            chmod 600 .mcp.json 2>/dev/null || true
            SKIP_MCP=true
        fi
    else
        SKIP_MCP=false
    fi

    if [[ "$SKIP_MCP" != "true" ]]; then
        local mcp_config
        mcp_config=$(json_emit_mcp_config "$uvx_cmd" "$data_dir")

        write_file_safe ".mcp.json" "$mcp_config"
        chmod 600 .mcp.json 2>/dev/null || true
    fi

    # Validate the final config
    if [[ "$DRY_RUN" != "1" ]] && ! json_validate ".mcp.json"; then
        print_error "Failed to create valid MCP configuration"
        exit 1
    fi

    print_status "MCP configuration complete"
}

create_claude_md() {
    print_info "Creating CLAUDE.md instructions..."

    if [[ -f "CLAUDE.md" ]]; then
        print_info "CLAUDE.md already exists"
        print_info "Backing up your existing instructions and creating ChromaDB configuration..."
        backup_claude_md
    fi

    local content='# CLAUDE.md — Project Contract

**Purpose**: Follow this in every session for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

## 🧠 Project Memory (Chroma)

Use server `chroma`. Collection `${PROJECT_COLLECTION}`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

After adding memories, confirm with: **✓ Memory logged** (ignore "result is None" - that'\''s normal)

Before proposing work, query Chroma for prior facts.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "${PROJECT_COLLECTION}" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query:
mcp__chroma__chroma_query_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

## 🧩 Deterministic Reasoning

Default: concise, action oriented.

Auto-propose sequential-thinking when a task has 3+ dependent steps or multiple tradeoffs. Enable for one turn, then disable.

If I say "reason stepwise", enable for one turn, then disable.

## 🌐 Browser Automation

Use playwright to load pages, scrape DOM, run checks, and export screenshots or PDFs.

Save artifacts to `./backups/` with timestamped filenames.

Summarize results and list file paths.

## 🐙 GitHub MCP

Use github to fetch files, list and inspect issues and PRs, and draft PR comments.

Never push or merge without explicit approval.

Always show diffs, file paths, or PR numbers before proposing changes.

## 🔧 Additional MCP Servers

- **context7**: Library docs search. Example: `/docs react hooks`
- **magic**: UI components and small React blocks. Example: `/ui button`
- **sequential-thinking**: Complex planning mode as above

## 🛠️ Tool Selection Matrix

| Task | Tool |
|------|------|
| Multi-file edits | MultiEdit (if available). Otherwise propose unified diff per file |
| Pattern search in repo | Grep MCP (not shell grep). Return matches with file paths and line numbers |
| UI snippet or component | Magic MCP. Return self-contained file |
| Complex analysis or planning | Sequential-thinking for one turn |
| Docs or library behavior | context7 first. Quote relevant lines, then summarize |
| Web page check or scrape | Playwright with artifacts saved to `./backups/` |

If a listed tool is missing, state the exact server or tool name that is unavailable and ask to enable it.

## 📋 Spec and Planning (Lite)

For new features, run three phases:

1. **/specify** user stories, functional requirements, acceptance tests
2. **/plan** stack, architecture, constraints, performance and testing goals
3. **/tasks** granular, test-first steps

Log key spec and plan decisions to Chroma as `type:"decision"` with tags.

## ✅ Quality Gates

Every requirement is unambiguous, testable, and bounded.

Prefer tests and unified diffs over prose.

Mark uncertainty with `[VERIFY]` and propose checks.

Include simple performance budgets where relevant. Example: search under 100ms at 10k rows.

## 🔄 Session Lifecycle

**Start**: Query Chroma for context relevant to the task. List any matches you will rely on.

**Work**: Log decisions and gotchas as they happen. Keep each memory under 300 chars.

**Checkpoint**: Every 30 minutes or at major milestone, summarize progress, open risks, and memories logged.

**End**: Summarize changes, link artifacts in `./backups/`, and list all memories written.

## 📝 Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, ask yourself:
- Did I discover any new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve any tricky problems?
- Did I learn something about the codebase architecture?

If yes → Log a memory immediately before continuing.

**During long coding sessions** (>10 interactions):
- Pause and review: Have I logged recent learnings?
- Check: Are there unrecorded decisions or fixes?
- Remember: Each memory helps future sessions

## 🧹 Session Hygiene

Do not compact long chats.

If context gets heavy, propose pruning to the last 20 turns and continue.

For long outputs, write files to `./backups/` and return paths.

## 🔍 Retrieval Checklist Before Coding

1. Query Chroma for related memories
2. Check repo files that match the task
3. List open PRs or issues that touch the same area
4. Only then propose changes

## 🏷️ Memory Taxonomy

- **type**: `decision`, `fix`, `tip`, `preference`
- **tags**: short domain keywords. Example: `video,encode,preview`
- **id rule**: stable handle per fact. Example: `encode-preview-policy`

### Memory Examples
```javascript
documents: ["Use NVENC for H.264 previews; fallback x264 if GPU is busy"]
metadatas: [{ "type":"tip","tags":"video,encode,preview","source":"PR#142" }]
ids: ["encode-preview-policy"]

documents: ["Adopt Conventional Commits and run tests on pre-push"]
metadatas: [{ "type":"decision","tags":"repo,workflow,testing","source":"spec" }]
ids: ["repo-commit-policy"]
```

## 📁 Output Policy

For code, return unified diff or patchable file set.

For scripts, include exact commands and paths.

Save long outputs in `./backups/`. Use readable names. Echo paths in the reply.

## 🛡️ Safety

No secrets in `.chroma` or transcripts.

Note licenses and third party terms when adding dependencies.

Respect rate limits. Propose batching if needed.

## 🎯 Modes

**Small change**: Skip full spec. Still log key decisions. Still show diffs.

**Feature**: Run the three phases. Enforce quality gates.

## ⚡ Activation

Read this file at session start.

First action: Query existing memories to understand project context:
```javascript
mcp__chroma__chroma_query_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "query_texts": ["project decisions preferences fixes"],
  "n_results": 5  // raise to 10 only if <3 strong hits
}
```

Then review the memories and internalize:
- Key architectural decisions made
- User preferences to maintain
- Known fixes and gotchas to avoid
- Patterns established in the codebase

Then load any always-on context files:
- Read all Markdown files in `.chroma/context/` (titles + key bullets)
- Cite which ones you used

Run `bin/chroma-stats.py` if it exists and announce:
**Contract loaded. Using Chroma ${PROJECT_COLLECTION}. Found [N] memories (by type ...).**

If tools are missing, name them and stop before continuing.

---
*Note: If you had existing CLAUDE.md instructions, they are preserved in `CLAUDE.md.original`*'

    write_file_safe "CLAUDE.md" "$content"
    print_status "Created CLAUDE.md with ChromaDB instructions"

    if [[ -f "CLAUDE.md.original" ]] && [[ "$DRY_RUN" != "1" ]]; then
        print_info "💡 Your original instructions are preserved in: CLAUDE.md.original"
        print_info "   You can manually merge them if needed"
    fi
}

create_gitignore() {
    print_info "Creating .gitignore..."

    if [[ -f ".gitignore" ]]; then
        print_warning ".gitignore already exists"
        if ! prompt_yes "Merge ChromaDB entries into existing .gitignore?"; then
            print_info "Skipping .gitignore"
            return 0
        fi
        backup_if_exists ".gitignore"
    fi

    local content='# ChromaDB local database
.chroma/
*.chroma

# MCP configuration (project-specific, track in version control)
# .mcp.json - Comment out this line if you want to track MCP config

# Memory exports (optional - track for history)
claudedocs/*.md

# Python
__pycache__/
*.py[cod]
.pytest_cache/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp'

    if [[ -f ".gitignore" ]]; then
        # Merge: add ChromaDB-specific lines if not present
        local chroma_lines=(".chroma/" "*.chroma")
        for line in "${chroma_lines[@]}"; do
            if ! grep -Fq "$line" .gitignore 2>/dev/null; then
                if [[ "$DRY_RUN" == "1" ]]; then
                    print_info "[dry-run] Would add to .gitignore: $line"
                else
                    echo "$line" >> .gitignore
                fi
            fi
        done
        touch_track ".gitignore"
        print_status "Updated .gitignore"
    else
        write_file_safe ".gitignore" "$content"
        print_status "Created .gitignore"
    fi
}

create_init_docs() {
    print_info "Creating initialization documentation..."

    local content='# ChromaDB Initialization

## Automatic Setup
When you start Claude in this project:
1. Claude reads CLAUDE.md
2. Checks if ChromaDB collection exists
3. Creates collection if needed
4. Starts logging memories

## Starting Claude
```bash
# From project directory:
claude

# Or use the launcher:
./start-claude-chroma.sh
```

## Manual Commands (if needed)

### Create Collection
```javascript
mcp__chroma__chroma_create_collection { "collection_name": "${PROJECT_COLLECTION}" }
```

### Test Collection
```javascript
mcp__chroma__chroma_query_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "query_texts": ["test"],
  "n_results": 5
}
```

### Add Memory
```javascript
mcp__chroma__chroma_add_documents {
  "collection_name": "${PROJECT_COLLECTION}",
  "documents": ["Your memory text here"],
  "metadatas": [{
    "type": "tip",
    "tags": "relevant,tags",
    "source": "manual",
    "confidence": 0.8
  }],
  "ids": ["unique-id-001"]
}
```

## Troubleshooting

### MCP server not found
- Ensure .mcp.json exists in project root
- Start Claude from the project directory
- Check: `cat .mcp.json | jq .`

### Collection errors
- Verify ChromaDB directory exists: `ls -la .chroma/`
- Try recreating collection with command above

### Memory not persisting
- Check collection name matches: "${PROJECT_COLLECTION}"
- Verify metadata format is correct
- Ensure unique IDs for each memory'

    write_file_safe "claudedocs/INIT_INSTRUCTIONS.md" "$content"
    print_status "Created initialization documentation"
}

create_launcher() {
    print_info "Creating launcher script..."

    local content='#!/usr/bin/env bash
set -euo pipefail

# Check if config exists
if [[ ! -f ".mcp.json" ]]; then
    echo "❌ No MCP config found in this directory"
    echo "Run the ChromaDB setup script first"
    exit 1
fi

# Validate JSON
if ! jq -e . .mcp.json >/dev/null 2>&1; then
    echo "❌ Invalid .mcp.json configuration"
    echo "Run: jq . .mcp.json to see the error"
    exit 1
fi

# Optional: bump registry usage if helper exists
if [[ -x "bin/registry.sh" ]]; then
  bin/registry.sh bump "$PWD" || true
fi
echo "🚀 Starting Claude with ChromaDB..."
exec claude "$@"'

    write_file_safe "start-claude-chroma.sh" "$content"

    if [[ "$DRY_RUN" != "1" ]]; then
        chmod +x start-claude-chroma.sh
    else
        print_info "[dry-run] Would make executable: start-claude-chroma.sh"
    fi

    print_status "Created launcher script"
}

setup_shell_function() {
    print_header "🚀 Optional: Smart Shell Function"

    print_info "Add a global 'claude-chroma' function to your shell?"
    echo ""
    echo -e "${BLUE}This function will:${NC}"
    echo "  ✅ Work from any directory in your project tree"
    echo "  ✅ Auto-detect ChromaDB config files"
    echo "  ✅ Fall back to regular Claude if no config found"
    echo ""

    if ! prompt_yes "Add claude-chroma function?"; then
        print_info "Skipping shell function setup"
        return 0
    fi

    local shell_rc
    shell_rc=$(detect_shell_rc)
    local shell_name
    shell_name=$(basename "${SHELL:-/bin/bash}")

    print_info "Shell: $shell_name"
    print_info "Config: $shell_rc"

    # Check if function already exists
    if [[ -f "$shell_rc" ]] && grep -q "claude-chroma()\|function claude-chroma" "$shell_rc" 2>/dev/null; then
        print_info "claude-chroma function already exists"
        return 0
    fi

    backup_if_exists "$shell_rc"

    local function_content

    if [[ "$shell_name" == "fish" ]]; then
        function_content='
# ChromaDB Smart Function - Added by claude-chroma.sh v3.3
function claude-chroma --description "Start Claude with auto-detected ChromaDB config"
    set config_file ""
    set search_dir "$PWD"

    # Search upward for .mcp.json
    while test "$search_dir" != "/"
        if test -f "$search_dir/.mcp.json"
            set config_file "$search_dir/.mcp.json"
            break
        end
        set search_dir (dirname "$search_dir")
    end

    if test -n "$config_file"
        set project_dir (dirname "$config_file")
        echo "Using ChromaDB project: $project_dir"
        cd "$project_dir"
        if test (count $argv) -eq 0
            claude
        else
            claude $argv
        end
    else
        echo "No ChromaDB config found - using regular Claude"
        if test (count $argv) -eq 0
            claude
        else
            claude $argv
        end
    end
end'
    else
        function_content='
# ChromaDB Smart Function - Added by claude-chroma.sh v3.3
claude-chroma() {
    local config_file=""
    local search_dir="$PWD"

    # Search upward for .mcp.json
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/.mcp.json" ]]; then
            config_file="$search_dir/.mcp.json"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    if [[ -n "$config_file" ]]; then
        local project_dir=$(dirname "$config_file")
        echo "🧠 Using ChromaDB project: $project_dir"
        cd "$project_dir"
        if [[ $# -eq 0 ]]; then
            claude
        else
            claude "$@"
        fi
    else
        echo "ℹ️  No ChromaDB config found - using regular Claude"
        if [[ $# -eq 0 ]]; then
            claude
        else
            claude "$@"
        fi
    fi
}'
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
        print_info "[dry-run] Would add claude-chroma function to $shell_rc"
    else
        echo "$function_content" >> "$shell_rc"
        touch_track "$shell_rc"
        print_status "Added claude-chroma function"
    fi

    print_info "Restart terminal or run: source $shell_rc"
}

# ============================================================================
# MIGRATION FROM OLDER VERSIONS
# ============================================================================
migrate_from_v3() {
    # Check for v3.0/3.1 invalid configuration
    if [[ -f ".claude/settings.local.json" ]]; then
        if grep -q '"instructions"' .claude/settings.local.json 2>/dev/null; then
            print_info "Found incompatible v3.0/3.1 configuration"

            if prompt_yes "Migrate from previous version?"; then
                backup_if_exists ".claude/settings.local.json"

                if [[ "$DRY_RUN" != "1" ]]; then
                    rm -f .claude/settings.local.json

                    # Remove empty .claude directory
                    if [[ -d ".claude" ]] && [[ -z "$(ls -A .claude 2>/dev/null)" ]]; then
                        rmdir .claude
                    fi
                else
                    print_info "[dry-run] Would remove invalid .claude/settings.local.json"
                fi

                print_status "Migrated from v3.0/3.1"
            fi
        fi
    fi
}

# ============================================================================
# SHELL FUNCTION MIGRATION
# ============================================================================
check_broken_shell_function() {
    print_info "Checking for broken shell functions..."

    local shell_rc
    shell_rc=$(detect_shell_rc)

    if [[ ! -f "$shell_rc" ]]; then
        return 0
    fi

    # Check if function exists and is broken (looking for old config file)
    if grep -q "claude-chroma()" "$shell_rc" 2>/dev/null; then
        if grep -q '\.claude/settings\.local\.json' "$shell_rc" 2>/dev/null; then
            print_warning "Found outdated claude-chroma function in $shell_rc"
            print_info "This function looks for the old config file location"

            if prompt_yes "Update claude-chroma function to work with current version?"; then
                backup_if_exists "$shell_rc"

                if [[ "$DRY_RUN" != "1" ]]; then
                    # Remove old function
                    local tmp_file="${shell_rc}.tmp.$$"
                    awk '
                        /^[[:space:]]*claude-chroma\(\)/ { in_func=1 }
                        in_func && /^}/ { in_func=0; next }
                        !in_func { print }
                    ' "$shell_rc" > "$tmp_file"

                    mv "$tmp_file" "$shell_rc"

                    # Add updated function
                    local function_content='
# ChromaDB Smart Function - Updated by claude-chroma.sh v3.3
claude-chroma() {
    local config_file=""
    local search_dir="$PWD"

    # Search upward for .mcp.json
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/.mcp.json" ]]; then
            config_file="$search_dir/.mcp.json"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done

    if [[ -n "$config_file" ]]; then
        local project_dir=$(dirname "$config_file")
        echo "🧠 Using ChromaDB project: $project_dir"
        cd "$project_dir"
        if [[ $# -eq 0 ]]; then
            claude
        else
            claude "$@"
        fi
    else
        echo "ℹ️  No ChromaDB config found - using regular Claude"
        if [[ $# -eq 0 ]]; then
            claude
        else
            claude "$@"
        fi
    fi
}'
                    echo "$function_content" >> "$shell_rc"
                    print_status "Updated claude-chroma function"
                    print_info "Restart terminal or run: source $shell_rc"
                else
                    print_info "[dry-run] Would update claude-chroma function in $shell_rc"
                fi
            fi
        fi
    fi
}

# ============================================================================
# MCP CONFIG TIMEOUT VALIDATION
# ============================================================================
check_mcp_timeout_settings() {
    if [[ ! -f ".mcp.json" ]]; then
        return 0
    fi

    print_info "Checking existing .mcp.json for timeout settings..."

    # Check if timeout settings exist
    local has_timeout_settings=0

    if jq -e '.mcpServers.chroma.env.CHROMA_SERVER_KEEP_ALIVE' .mcp.json >/dev/null 2>&1; then
        if [[ $(jq -r '.mcpServers.chroma.env.CHROMA_SERVER_KEEP_ALIVE' .mcp.json) == "0" ]]; then
            has_timeout_settings=1
        fi
    fi

    if [[ "$has_timeout_settings" -eq 0 ]]; then
        print_warning "Existing .mcp.json lacks infinite timeout settings"
        print_info "Without these settings, ChromaDB may disconnect after inactivity"

        if prompt_yes "Update .mcp.json with timeout prevention settings?"; then
            backup_if_exists ".mcp.json"

            if [[ "$DRY_RUN" != "1" ]]; then
                # Update the config with timeout settings
                local updated_config
                updated_config=$(jq '
                    .mcpServers.chroma.env.CHROMA_SERVER_KEEP_ALIVE = "0" |
                    .mcpServers.chroma.env.CHROMA_CLIENT_TIMEOUT = "0" |
                    .mcpServers.chroma.initializationOptions.timeout = 0 |
                    .mcpServers.chroma.initializationOptions.keepAlive = true |
                    .mcpServers.chroma.initializationOptions.retryAttempts = 5
                ' .mcp.json)

                echo "$updated_config" > .mcp.json
                print_status "Updated .mcp.json with timeout prevention settings"
            else
                print_info "[dry-run] Would update .mcp.json with timeout settings"
            fi
        fi
    else
        print_status "Timeout settings already configured correctly"
    fi
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================
print_summary() {
    print_header "✨ Setup Complete!"

    echo "Project: $PROJECT_NAME"
    echo "Path: $PROJECT_DIR"
    echo ""

    if [[ "$DRY_RUN" == "1" ]]; then
        print_warning "DRY RUN MODE - No changes were made"
        echo ""
        echo "To apply changes, run without DRY_RUN:"
        echo "  DRY_RUN=0 $0 $*"
    else
        print_status "ChromaDB MCP server configured"
        print_status "Project instructions in CLAUDE.md"
        print_status "All files backed up before modification"

        echo ""
        print_info "Directory structure:"
        if command -v tree >/dev/null 2>&1; then
            tree -a -L 2 . 2>/dev/null | head -20
        else
            ls -la . | head -10
        fi

        echo ""
        print_info "Next steps:"
        echo "  1. cd \"$PROJECT_DIR\""
        echo "  2. Run ONE of these commands:"
        echo "     $ claude           (starts Claude with ChromaDB)"
        echo "     $ ./start-claude-chroma.sh"
        echo "  3. Claude auto-initializes ChromaDB"

        echo ""
        print_info "The system will:"
        echo "  • Auto-detect .mcp.json configuration"
        echo "  • Auto-create collection if needed"
        echo "  • Auto-log memories during work"
        echo "  • Persist knowledge across sessions"
    fi
}

# ============================================================================
# PROJECT REGISTRY
# ============================================================================
add_to_registry() {
    # Use XDG config home if available
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local registry="$config_dir/claude/chroma_projects.jsonl"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create registry directory if needed
    mkdir -p "$(dirname "$registry")"

    # Add entry if not already present (JSONL format)
    if ! grep -Fq "\"path\":\"$PROJECT_DIR\"" "$registry" 2>/dev/null; then
        printf '{"name":"%s","path":"%s","collection":"%s","data_dir":"%s/.chroma","created_at":"%s","sessions":0}\n' \
            "$PROJECT_NAME" "$PROJECT_DIR" "$PROJECT_COLLECTION" "$PROJECT_DIR" "$timestamp" >> "$registry"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    # Handle command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                print_warning "DRY RUN MODE - No changes will be made"
                ;;
            --non-interactive)
                NON_INTERACTIVE=1
                ;;
            --yes|-y)
                ASSUME_YES=1
                ;;
            --debug)
                DEBUG=1
                ;;
            --version)
                echo "claude-chroma.sh version $SCRIPT_VERSION"
                exit 0
                ;;
            --collection)
                shift
                CHROMA_COLLECTION_OVERRIDE="${1:-}"
                ;;
            --data-dir)
                shift
                DATA_DIR_OVERRIDE="${1:-}"
                ;;
            --print-collection)
                # Just print the collection name and exit
                PROJECT_NAME="${2:-$(basename "$PWD")}"
                : "${CHROMA_COLLECTION_OVERRIDE:=}"
                derive_collection_name() {
                    local base="${PROJECT_NAME:-$(basename "$PWD")}"
                    if command -v iconv >/dev/null 2>&1; then
                        base="$(printf '%s' "$base" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || printf '%s' "$base")"
                    fi
                    local norm
                    norm="$(printf '%s' "$base" | tr '[:upper:] .-/' '[:lower:]___' | sed 's/[^a-z0-9_]/_/g')"
                    norm="${norm:0:48}"
                    printf '%s_memory' "$norm"
                }
                PROJECT_COLLECTION="${CHROMA_COLLECTION_OVERRIDE:-$(derive_collection_name)}"
                echo "$PROJECT_COLLECTION"
                exit 0
                ;;
            --help)
                echo "Usage: $0 [PROJECT_NAME] [PROJECT_PATH] [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --dry-run          Preview changes without applying"
                echo "  --non-interactive  Run without prompts"
                echo "  --yes, -y          Assume yes to all prompts"
                echo "  --debug            Show debug output"
                echo "  --collection NAME  Override collection name"
                echo "  --data-dir PATH    Override data directory"
                echo "  --print-collection Print collection name and exit"
                echo "  --version          Show version"
                echo "  --help             Show this help"
                echo ""
                echo "Environment variables:"
                echo "  DRY_RUN=1          Same as --dry-run"
                echo "  NON_INTERACTIVE=1  Same as --non-interactive"
                echo "  ASSUME_YES=1       Same as --yes"
                echo "  DEBUG=1            Same as --debug"
                exit 0
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    # Get project name and path from remaining arguments
    local project_name="${1:-}"
    local project_path="${2:-}"

    # Sanitize inputs
    project_name=$(sanitize_input "$project_name")

    # Default path detection
    if [[ -z "$project_path" ]]; then
        if [[ -z "$project_name" ]]; then
            # No arguments - use current directory
            project_path="$(pwd)"
        elif [[ -d "$HOME/projects" ]]; then
            project_path="$HOME/projects"
        elif [[ -d "$HOME/Documents/projects" ]]; then
            project_path="$HOME/Documents/projects"
        elif [[ -d "$HOME/Desktop/projects" ]]; then
            project_path="$HOME/Desktop/projects"
        else
            project_path="$HOME"
            print_info "Using home directory. Consider creating ~/projects/"
        fi
    fi

    project_path=$(sanitize_input "$project_path")

    # Run setup
    check_prerequisites
    setup_project_directory "$project_name" "$project_path"

    # Derive a per-project collection name
    : "${CHROMA_COLLECTION_OVERRIDE:=}"
    derive_collection_name() {
        local base="${PROJECT_NAME:-$(basename "$PWD")}"
        # Transliterate non-ASCII characters if iconv is available
        if command -v iconv >/dev/null 2>&1; then
            base="$(printf '%s' "$base" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || printf '%s' "$base")"
        fi
        # normalize: lower, replace non [a-z0-9_] with _
        local norm
        norm="$(printf '%s' "$base" | tr '[:upper:] .-/' '[:lower:]___' | sed 's/[^a-z0-9_]/_/g')"
        # clamp to reasonable length
        norm="${norm:0:48}"
        printf '%s_memory' "$norm"
    }
    PROJECT_COLLECTION="${CHROMA_COLLECTION_OVERRIDE:-$(derive_collection_name)}"

    migrate_from_v3
    check_broken_shell_function
    create_directory_structure
    create_mcp_config
    check_mcp_timeout_settings
    create_claude_md
    ensure_memory_discipline
    ensure_settings_memory_discipline
    create_gitignore
    create_init_docs
    create_launcher
    setup_shell_function
    add_to_registry
    print_summary
}

# Run main function
main "$@"