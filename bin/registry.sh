#!/bin/bash
# ChromaDB Project Registry Management - Hardened Version
# JSONL append-only format with atomic operations
set -euo pipefail

# Use XDG config home if available
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly REGISTRY="${REGISTRY:-$CONFIG_DIR/claude/chroma_projects.jsonl}"

# Strict perms on anything we touch
umask 077

# Cross-platform lock runner:
# - Linux: flock
# - macOS: lockf
# - Fallback: mkdir-based spinlock (last resort; cleans up)
_lock_run() { # _lock_run <lockfile> <cmd...>
    local lf="$1"; shift
    # Prefer flock if present
    if command -v flock >/dev/null 2>&1; then
        ( exec 9>>"$lf"; flock 9; "$@" )
        return $?
    fi
    # macOS: lockf is native
    if command -v lockf >/dev/null 2>&1; then
        lockf -k "$lf" "$@"
        return $?
    fi
    # Fallback: mkdir lock with timeout
    local d="${lf}.dirlock"
    local max_attempts=100  # 5 seconds at 0.05s intervals
    local attempts=0

    echo "Warning: Using mkdir fallback for locking (flock/lockf unavailable)" >&2

    while ! mkdir "$d" 2>/dev/null; do
        attempts=$((attempts + 1))
        if [[ $attempts -ge $max_attempts ]]; then
            echo "Error: Lock timeout after ${max_attempts} attempts, removing stale lock" >&2
            rm -rf "$d" 2>/dev/null || true
            if ! mkdir "$d" 2>/dev/null; then
                echo "Error: Unable to acquire lock even after cleanup" >&2
                return 1
            fi
            break
        fi
        sleep 0.05
    done

    trap 'rmdir "$d" 2>/dev/null || true' EXIT
    "$@"; local rc=$?
    rmdir "$d" 2>/dev/null || true
    trap - EXIT
    return $rc
}

# Atomic write helper
_write_atomic() { # _write_atomic <target> [mode]
    local target="$1"
    local mode="${2:-600}"
    local tmp="${target}.tmp.$$"
    cat >"$tmp"
    chmod "$mode" "$tmp" 2>/dev/null || true
    mv -f "$tmp" "$target"
}

# Check jq version and warn if < 1.5
_check_jq_version() {
    if command -v jq >/dev/null 2>&1; then
        if ! jq -r --version 2>/dev/null | grep -qE 'jq-1\.[5-9]|jq-[2-9]'; then
            echo "Warning: jq >=1.5 recommended for optimal JSON handling" >&2
        fi
    fi
}

# Ensure registry exists with proper permissions
init_registry() {
    local dir="$(dirname "$REGISTRY")"
    mkdir -p "$dir"
    touch "$REGISTRY"
    chmod 600 "$REGISTRY" 2>/dev/null || true
}

# Add entry
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

    # Ensure sessions and last_used fields exist for later bumps
    _lock_run "$REGISTRY.lock" bash -c '
        line=$0; reg=$1
        printf "%s\n" "$line" >> "$reg"
        chmod 600 "$reg" 2>/dev/null || true
    ' "$(printf '{"name":"%s","path":"%s","collection":"%s","created":"%s","sessions":0,"last_used":null}' \
         "$name" "$path" "$collection" "$timestamp")" "$REGISTRY"
}

# List all entries as JSON array
list_entries() {
    [[ -f "$REGISTRY" ]] || { echo "[]"; return; }

    # Use jq to collect JSONL into array
    if command -v jq >/dev/null 2>&1; then
        jq -s '.' "$REGISTRY" 2>/dev/null || echo "[]"
    else
        echo "["
        local first=true
        while IFS= read -r line; do
            [[ "$first" == true ]] && first=false || echo ","
            printf "  %s" "$line"
        done < "$REGISTRY"
        echo -e "\n]"
    fi
}

# Find by path
find_by_path() {
    local search_path="${1:-}"
    [[ -f "$REGISTRY" ]] || return 1
    [[ -z "$search_path" ]] && return 1

    if command -v jq >/dev/null 2>&1; then
        # Use jq to find matching entries
        jq -r --arg path "$search_path" \
            'select(.path == $path)' "$REGISTRY" 2>/dev/null | tail -1
    else
        grep -F "\"path\":\"$search_path\"" "$REGISTRY" | tail -1
    fi
}

# Update entry to bump sessions and last_used (jq-based; safe defaults)
update_entry() {
    local path="${1:-}"
    [[ -z "$path" ]] && {
        echo "Error: update requires path" >&2
        return 1
    }

    [[ -f "$REGISTRY" ]] || return 0

    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if ! command -v jq >/dev/null 2>&1; then
        # No jq: fail soft without corrupting the registry
        echo "jq not found; skipping registry bump safely" >&2
        return 0
    fi

    _lock_run "$REGISTRY.lock" bash -c '
        reg="$1"; path="$2"; ts="$3"; tmp="${reg}.tmp.$$"
        {
            while IFS= read -r line; do
                if printf %s "$line" | grep -F "\"path\":\"$path\"" >/dev/null; then
                    printf %s "$line" | jq -c --arg ts "$ts" \
                        ".sessions = ((.sessions // 0) + 1) | .last_used = \$ts"
                else
                    printf "%s\n" "$line"
                fi
            done <"$reg"
        } >"$tmp" && mv -f "$tmp" "$reg"
    ' _ "$REGISTRY" "$path" "$timestamp"
}

# Clean up on exit
cleanup() {
    rm -f "$REGISTRY".tmp.* 2>/dev/null || true
    rm -f "$REGISTRY.lock" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Main
# Check jq version early for any operations that use it
_check_jq_version

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