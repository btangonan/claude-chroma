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

# Main
case "${1:-}" in
    add) add_entry "$2" "$3" "$4" ;;
    list) list_entries ;;
    find) find_by_path "$2" ;;
    *) echo "Usage: $0 {add|list|find} [args...]"; exit 1 ;;
esac