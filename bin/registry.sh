#!/bin/bash
# ChromaDB Project Registry Management
# JSONL append-only format for safety
set -euo pipefail

# Use XDG config home if available
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly REGISTRY="${REGISTRY:-$CONFIG_DIR/claude/chroma_projects.jsonl}"

# Add entry
add_entry() {
    local name="$1" path="$2" collection="$3"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    mkdir -p "$(dirname "$REGISTRY")"
    printf '{"name":"%s","path":"%s","collection":"%s","created":"%s"}\n' \
        "$name" "$path" "$collection" "$timestamp" >> "$REGISTRY"
}

# List all entries
list_entries() {
    [[ -f "$REGISTRY" ]] || { echo "[]"; return; }

    echo "["
    local first=true
    while IFS= read -r line; do
        [[ "$first" == true ]] && first=false || echo ","
        printf "  %s" "$line"
    done < "$REGISTRY"
    echo -e "\n]"
}

# Find by path
find_by_path() {
    local search_path="$1"
    [[ -f "$REGISTRY" ]] || return 1

    grep -F "\"path\":\"$search_path\"" "$REGISTRY" | tail -1
}

# Update entry to bump sessions and last_used
update_entry() {
    local path="$1"
    local tmp="${REGISTRY}.tmp.$$"
    [[ -f "$REGISTRY" ]] || return 0

    # Simple sed-based approach for better portability
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    while IFS= read -r line; do
        if [[ "$line" == *"\"path\":\"$path\""* ]]; then
            # Extract current sessions count and increment
            local current_sessions=$(echo "$line" | sed -n 's/.*"sessions":\([0-9]*\).*/\1/p')
            local new_sessions=$((current_sessions + 1))

            # Update line
            echo "$line" | sed -e "s/\"sessions\":[0-9]*/\"sessions\":$new_sessions/" \
                              -e "s/\"last_used\":null/\"last_used\":\"$timestamp\"/" \
                              -e "s/\"last_used\":\"[^\"]*\"/\"last_used\":\"$timestamp\"/"
        else
            echo "$line"
        fi
    done < "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"
}

# Main
case "${1:-}" in
  add)  add_entry "$2" "$3" "$4" ;;
  bump) update_entry "$2" ;;
  list) list_entries ;;
  find) find_by_path "$2" ;;
  *) echo "Usage: $0 {add|bump|list|find} [args...]"; exit 1 ;;
esac