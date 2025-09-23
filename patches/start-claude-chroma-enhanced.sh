#!/bin/bash
# Enhanced launcher for Claude with ChromaDB and session tracking

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to update session registry
update_registry() {
  local registry="$HOME/.claude/chroma_projects.yml"
  local project_dir="$PWD"

  # Only update if registry exists and we have python3
  if [[ -f "$registry" ]] && command -v python3 >/dev/null 2>&1; then
    python3 - "$project_dir" <<'PY' 2>/dev/null || true
import os, sys, yaml, datetime

registry_path = os.path.expanduser("~/.claude/chroma_projects.yml")
project_path = sys.argv[1]

try:
    # Load registry
    with open(registry_path, 'r') as f:
        data = yaml.safe_load(f) or []

    # Update entry for this project
    updated = False
    for entry in data:
        if entry.get("path") == project_path:
            entry["sessions"] = int(entry.get("sessions", 0)) + 1
            entry["last_used"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
            updated = True
            break

    # Write back if we updated
    if updated:
        with open(registry_path, 'w') as f:
            yaml.safe_dump(data, f, sort_keys=False)

except Exception:
    # Silent fail - don't disrupt launch
    pass
PY
  fi
}

# Function to display project info
show_project_info() {
  if [[ -f "bin/chroma-stats.py" ]] && command -v python3 >/dev/null 2>&1; then
    local stats=$(python3 bin/chroma-stats.py 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$stats" ]]; then
      local total=$(echo "$stats" | python3 -c "import sys, json; print(json.load(sys.stdin).get('total', 0))" 2>/dev/null)
      local by_type=$(echo "$stats" | python3 -c "import sys, json; d=json.load(sys.stdin).get('by_type', {}); print(', '.join([f'{k}:{v}' for k,v in d.items()]))" 2>/dev/null)

      if [[ -n "$total" ]]; then
        echo -e "${BLUE}📊 Memory Statistics:${NC}"
        echo -e "   Total memories: ${GREEN}$total${NC}"
        if [[ -n "$by_type" ]]; then
          echo -e "   Breakdown: $by_type"
        fi
        echo
      fi
    fi
  fi

  # Show context directory info
  if [[ -d ".chroma/context" ]]; then
    local context_count=$(find .chroma/context -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$context_count" -gt 0 ]]; then
      echo -e "${BLUE}📁 Context Files:${NC} $context_count reference documents loaded"
      echo
    fi
  fi
}

# Main execution
main() {
  echo
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}     ChromaDB-Enhanced Claude Launcher v3.5.0     ${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo

  # Check for required files
  if [[ ! -f ".mcp.json" ]] || [[ ! -f "CLAUDE.md" ]]; then
    echo -e "${RED}⚠️  Error: Not in a ChromaDB-enabled project directory${NC}"
    echo -e "${YELLOW}Run 'claude-chroma.sh' first to set up the project${NC}"
    exit 1
  fi

  # Get project name and collection
  local project_name=$(basename "$PWD")
  if [[ -f ".chroma/config.yml" ]]; then
    local collection=$(grep "collection:" .chroma/config.yml 2>/dev/null | cut -d: -f2 | tr -d ' ')
    if [[ -n "$collection" ]]; then
      echo -e "${BLUE}🧠 Project:${NC} $project_name"
      echo -e "${BLUE}📦 Collection:${NC} $collection"
      echo
    fi
  fi

  # Display project info
  show_project_info

  # Update registry (best effort, don't fail)
  update_registry

  echo -e "${YELLOW}Important Instructions:${NC}"
  echo "1. Claude will automatically read CLAUDE.md on start"
  echo "2. It will query existing memories and load context files"
  echo "3. Remember to log important decisions as memories!"
  echo
  echo -e "${GREEN}Launching Claude...${NC}"
  echo

  # Launch Claude
  claude
}

# Run main
main "$@"