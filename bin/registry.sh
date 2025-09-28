#!/bin/bash
# ChromaDB Project Registry Management - Hardened Version
# JSONL append-only format with atomic operations
set -euo pipefail

# Use XDG config home if available
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly REGISTRY="${REGISTRY:-$CONFIG_DIR/claude/chroma_projects.jsonl}"
readonly LOCK_FD=200

# Ensure registry exists with proper permissions
init_registry() {
    local dir="$(dirname "$REGISTRY")"
    mkdir -p "$dir"
    touch "$REGISTRY"
    chmod 600 "$REGISTRY" 2>/dev/null || true
}

# Acquire lock for atomic operations
acquire_lock() {
    # Try flock first (Linux)
    if command -v flock >/dev/null 2>&1; then
        eval "exec $LOCK_FD>\"$REGISTRY.lock\""
        flock -x "$LOCK_FD"
    else
        # macOS fallback using mkdir (atomic operation)
        local lock_dir="$REGISTRY.lockdir"
        local max_wait=10
        local waited=0

        while ! mkdir "$lock_dir" 2>/dev/null; do
            if [[ $waited -ge $max_wait ]]; then
                # Force release stale lock
                rm -rf "$lock_dir" 2>/dev/null || true
                mkdir "$lock_dir" 2>/dev/null || true
                break
            fi
            sleep 0.1
            waited=$((waited + 1))
        done
    fi
}

# Release lock
release_lock() {
    if command -v flock >/dev/null 2>&1; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        eval "exec $LOCK_FD>&-" 2>/dev/null || true
    else
        rm -rf "$REGISTRY.lockdir" 2>/dev/null || true
    fi
}

# Add entry with atomic append
add_entry() {
    local name="${1:-}"
    local path="${2:-}"
    local collection="${3:-}"

    [[ -z "$name" || -z "$path" || -z "$collection" ]] && {
        echo "Error: add requires name, path, and collection" >&2
        return 1
    }

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    init_registry
    acquire_lock

    # Create JSON with jq for proper escaping (compact format for JSONL)
    local entry=$(jq -nc \
        --arg name "$name" \
        --arg path "$path" \
        --arg collection "$collection" \
        --arg ts "$timestamp" \
        '{name: $name, path: $path, collection: $collection, created: $ts, sessions: 1, last_used: null}')

    echo "$entry" >> "$REGISTRY"

    release_lock
}

# List all entries as JSON array
list_entries() {
    [[ -f "$REGISTRY" ]] || { echo "[]"; return; }

    # Use jq to collect JSONL into array
    jq -s '.' "$REGISTRY" 2>/dev/null || echo "[]"
}

# Find by path
find_by_path() {
    local search_path="${1:-}"
    [[ -f "$REGISTRY" ]] || return 1
    [[ -z "$search_path" ]] && return 1

    # Use jq to find matching entries
    jq -r --arg path "$search_path" \
        'select(.path == $path)' "$REGISTRY" 2>/dev/null | tail -1
}

# Update entry with atomic rewrite using jq
update_entry() {
    local path="${1:-}"
    [[ -z "$path" ]] && {
        echo "Error: update requires path" >&2
        return 1
    }

    [[ -f "$REGISTRY" ]] || return 0

    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local tmp="${REGISTRY}.tmp.$$"

    acquire_lock

    # Use jq to update the matching entry
    if command -v jq >/dev/null 2>&1; then
        # Safe JSON manipulation with jq
        jq -c --arg path "$path" --arg ts "$timestamp" '
            if .path == $path then
                .sessions = ((.sessions // 0) + 1) |
                .last_used = $ts
            else
                .
            end
        ' "$REGISTRY" > "$tmp" 2>/dev/null

        # Atomic move with proper permissions
        if [[ -s "$tmp" ]]; then
            chmod 600 "$tmp"
            mv -f "$tmp" "$REGISTRY"
        else
            rm -f "$tmp"
        fi
    else
        # Fallback: safer sed approach with validation
        echo "Warning: jq not found, using fallback method" >&2

        while IFS= read -r line; do
            if [[ "$line" == *"\"path\":\"$path\""* ]]; then
                # Validate JSON structure before manipulation
                if echo "$line" | grep -qE '^\{.*\}$'; then
                    # Extract current sessions count safely
                    local current_sessions=$(echo "$line" | grep -oE '"sessions":[0-9]+' | grep -oE '[0-9]+' || echo "0")
                    local new_sessions=$((current_sessions + 1))

                    # Update with careful escaping
                    echo "$line" | sed \
                        -e "s/\"sessions\":[0-9]*/\"sessions\":$new_sessions/" \
                        -e "s/\"last_used\":null/\"last_used\":\"$timestamp\"/" \
                        -e "s/\"last_used\":\"[^\"]*\"/\"last_used\":\"$timestamp\"/"
                else
                    echo "$line"
                fi
            else
                echo "$line"
            fi
        done < "$REGISTRY" > "$tmp"

        if [[ -s "$tmp" ]]; then
            chmod 600 "$tmp"
            mv -f "$tmp" "$REGISTRY"
        else
            rm -f "$tmp"
        fi
    fi

    release_lock
}

# Clean up on exit
cleanup() {
    release_lock
    rm -f "$REGISTRY".tmp.* 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Main
case "${1:-}" in
    add)
        add_entry "$2" "$3" "$4"
        ;;
    bump|update)
        update_entry "$2"
        ;;
    list)
        list_entries
        ;;
    find)
        find_by_path "$2"
        ;;
    *)
        cat >&2 <<EOF
Usage: $0 {add|bump|update|list|find} [args...]
  add <name> <path> <collection>  Add new project entry
  bump <path>                      Update session count and timestamp
  update <path>                    Alias for bump
  list                             List all entries as JSON
  find <path>                      Find entry by path
EOF
        exit 1
        ;;
esac