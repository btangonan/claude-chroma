#!/usr/bin/env bash
# Enhanced auto-setup.sh merge logic
# This file contains the implementation for non-destructive merging

# ==============================================================================
# Detection Functions
# ==============================================================================

detect_chromadb_in_claudemd() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"
    
    # Check if file exists
    [ ! -f "$claudemd" ] && return 1
    
    # Check for ChromaDB markers (multiple heuristics)
    if grep -q "## 🧠 Project Memory (Chroma)" "$claudemd" 2>/dev/null || \
       grep -q "mcp__chroma__chroma_create_collection" "$claudemd" 2>/dev/null || \
       grep -q "collection_name.*project_memory" "$claudemd" 2>/dev/null || \
       grep -q "ChromaDB Plugin Configuration" "$claudemd" 2>/dev/null; then
        return 0  # ChromaDB section exists
    fi
    
    return 1  # No ChromaDB section found
}

detect_chromadb_in_settings() {
    local settings_path="${PROJECT_ROOT}/.claude/settings.local.json"
    
    # Check if file exists
    [ ! -f "$settings_path" ] && return 1
    
    # Check if chroma is in enabledMcpjsonServers
    if grep -q '"chroma"' "$settings_path" 2>/dev/null && \
       grep -q '"mcpServers".*"chroma"' "$settings_path" 2>/dev/null; then
        return 0  # ChromaDB configured
    fi
    
    return 1  # ChromaDB not configured
}

# ==============================================================================
# CLAUDE.md Merge Logic
# ==============================================================================

merge_claudemd_chromadb() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"
    
    # If file doesn't exist, create from template
    if [ ! -f "$claudemd" ]; then
        create_claudemd_from_template
        return 0
    fi
    
    # Detect if ChromaDB already configured
    if detect_chromadb_in_claudemd; then
        echo "   ℹ️  CLAUDE.md already has ChromaDB configuration"
        return 0
    fi
    
    # Create backup before modification
    local backup_path="${claudemd}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$claudemd" "$backup_path"
    echo "   📦 Backup created: $backup_path"
    
    # Append ChromaDB section with clear marker
    cat >> "$claudemd" << 'CHROMADB_SECTION'

# ═══════════════════════════════════════════════════════════
# ChromaDB Plugin Configuration (auto-added by claude-chroma)
# ═══════════════════════════════════════════════════════════

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query (start with 5; escalate only if <3 strong hits):
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

## 🔍 Retrieval Checklist Before Coding
1. Query Chroma for related memories.
2. Check repo files that match the task.
3. List open PRs or issues that touch the same area.
4. Only then propose changes.

## 📝 Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, pause and check:
- Did I discover new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve tricky problems or learn about architecture?

If yes → Log memory IMMEDIATELY using the schema above.

**During long sessions (>10 interactions)**:
- Stop and review: Have I logged recent learnings?
- Check for unrecorded decisions or fixes
- Remember: Each memory helps future sessions

## ⚡ ChromaDB Activation
At session start, after reading this file:
- Query existing memories: `mcp__chroma__chroma_query_documents`
- Announce: **Contract loaded. Using Chroma project_memory.**

CHROMADB_SECTION

    echo "   ✅ Appended ChromaDB configuration to CLAUDE.md"
}

create_claudemd_from_template() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"
    
    cat > "$claudemd" << 'CLAUDEMD_FULL'
# CLAUDE.md — Project Memory Contract

**Purpose**: Follow this in every session for this repo. Keep memory sharp. Keep outputs concrete. Cut rework.

## 🧠 Project Memory (Chroma)
Use server `chroma`. Collection `project_memory`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: `{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }`
- **ids**: stable string if updating the same fact.

### Chroma Calls
```javascript
// Create once:
mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }

// Add:
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["<text>"],
  "metadatas": [{"type":"<type>","tags":"a,b,c","source":"<src>"}],
  "ids": ["<stable-id>"]
}

// Query (start with 5; escalate only if <3 strong hits):
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["<query>"],
  "n_results": 5
}
```

## 🔍 Retrieval Checklist Before Coding
1. Query Chroma for related memories.
2. Check repo files that match the task.
3. List open PRs or issues that touch the same area.
4. Only then propose changes.

## 📝 Memory Checkpoint Rules

**Every 5 interactions or after completing a task**, pause and check:
- Did I discover new decisions, fixes, or patterns?
- Did the user express any preferences?
- Did I solve tricky problems or learn about architecture?

If yes → Log memory IMMEDIATELY using the schema above.

**During long sessions (>10 interactions)**:
- Stop and review: Have I logged recent learnings?
- Check for unrecorded decisions or fixes
- Remember: Each memory helps future sessions

## ⚡ Activation
Read this file at session start.
Announce: **Contract loaded. Using Chroma project_memory.**

## 🧹 Session Hygiene
Prune to last 20 turns if context gets heavy. Save long outputs in `./backups/` and echo paths.

## 📁 Output Policy
For code, return unified diff or patchable files. For scripts, include exact commands and paths.

## 🛡️ Safety
No secrets in `.chroma` or transcripts. Respect rate limits. Propose batching if needed.
CLAUDEMD_FULL

    echo "   ✅ Created CLAUDE.md from template"
}

# ==============================================================================
# settings.local.json Merge Logic
# ==============================================================================

merge_settings_json() {
    local settings_path="${PROJECT_ROOT}/.claude/settings.local.json"
    
    # If doesn't exist, create from template
    if [ ! -f "$settings_path" ]; then
        create_settings_from_template "$settings_path"
        return 0
    fi
    
    # Detect if ChromaDB already configured
    if detect_chromadb_in_settings; then
        echo "   ℹ️  settings.local.json already has ChromaDB configuration"
        return 0
    fi
    
    # Merge using Python
    python3 << PYTHON_MERGE
import json
import sys
from datetime import datetime
import shutil

settings_path = "$settings_path"

try:
    # Load existing settings
    with open(settings_path, 'r') as f:
        settings = json.load(f)
    
    modified = False
    
    # 1. Merge enabledMcpjsonServers
    if 'enabledMcpjsonServers' not in settings:
        settings['enabledMcpjsonServers'] = []
        modified = True
    
    if 'chroma' not in settings['enabledMcpjsonServers']:
        settings['enabledMcpjsonServers'].append('chroma')
        modified = True
    
    # 2. Merge mcpServers.chroma config
    if 'mcpServers' not in settings:
        settings['mcpServers'] = {}
        modified = True
    
    if 'chroma' not in settings['mcpServers']:
        settings['mcpServers']['chroma'] = {
            'alwaysAllow': [
                'chroma_list_collections',
                'chroma_create_collection',
                'chroma_add_documents',
                'chroma_query_documents',
                'chroma_get_documents'
            ]
        }
        modified = True
    
    # 3. Merge instructions array
    chromadb_instructions = [
        'IMPORTANT: This project uses ChromaDB for persistent memory',
        'Every 5 interactions, check if you have logged recent learnings',
        'After solving problems or making decisions, immediately log to ChromaDB',
        'Use mcp__chroma__chroma_add_documents to preserve discoveries',
        'Query existing memories at session start with mcp__chroma__chroma_query_documents',
        'Each memory should be under 300 chars with appropriate metadata',
        'Log architecture decisions, user preferences, fixes, and patterns'
    ]
    
    if 'instructions' not in settings:
        settings['instructions'] = []
        modified = True
    
    # Add ChromaDB instructions if not already present (fuzzy match)
    for instruction in chromadb_instructions:
        # Check if similar instruction already exists
        found = False
        for existing in settings.get('instructions', []):
            # Simple fuzzy match: check if key words overlap significantly
            if 'ChromaDB' in instruction and 'ChromaDB' in existing:
                found = True
                break
            elif 'logged recent learnings' in instruction and 'logged recent learnings' in existing:
                found = True
                break
            elif 'mcp__chroma__chroma_add_documents' in instruction and 'mcp__chroma__chroma_add_documents' in existing:
                found = True
                break
        
        if not found:
            settings['instructions'].append(instruction)
            modified = True
    
    if modified:
        # Create backup
        backup_path = f"{settings_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(settings_path, backup_path)
        print(f"BACKUP:{backup_path}", file=sys.stderr)
        
        # Write merged settings
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)
        
        print("MODIFIED")
    else:
        print("UNCHANGED")

except Exception as e:
    print(f"ERROR:{str(e)}", file=sys.stderr)
    sys.exit(1)
PYTHON_MERGE

    local result=$?
    if [ $result -eq 0 ]; then
        echo "   ✅ Merged ChromaDB config into settings.local.json"
    else
        echo "   ⚠️  Failed to merge settings.local.json (Python error)"
        echo "   → Manual merge required"
    fi
}

create_settings_from_template() {
    local settings_path="$1"
    
    # Ensure .claude directory exists
    mkdir -p "$(dirname "$settings_path")"
    
    cat > "$settings_path" << 'SETTINGS_TEMPLATE'
{
  "enabledMcpjsonServers": [
    "chroma"
  ],
  "mcpServers": {
    "chroma": {
      "alwaysAllow": [
        "chroma_list_collections",
        "chroma_create_collection",
        "chroma_add_documents",
        "chroma_query_documents",
        "chroma_get_documents"
      ]
    }
  },
  "instructions": [
    "IMPORTANT: This project uses ChromaDB for persistent memory",
    "Every 5 interactions, check if you have logged recent learnings",
    "After solving problems or making decisions, immediately log to ChromaDB",
    "Use mcp__chroma__chroma_add_documents to preserve discoveries",
    "Query existing memories at session start with mcp__chroma__chroma_query_documents",
    "Each memory should be under 300 chars with appropriate metadata",
    "Log architecture decisions, user preferences, fixes, and patterns"
  ]
}
SETTINGS_TEMPLATE

    echo "   ✅ Created settings.local.json from template"
}

# ==============================================================================
# Main Setup Function (Updated)
# ==============================================================================

setup_chromadb_enhanced() {
    echo "🔧 ChromaDB not configured. Setting up automatically..."
    
    # Create .chroma directory
    mkdir -p "$CHROMA_DIR"
    
    # 1. Setup .mcp.json (existing logic, already works well)
    setup_mcp_json
    
    # 2. Setup or merge CLAUDE.md
    echo ""
    echo "📝 Configuring CLAUDE.md..."
    merge_claudemd_chromadb
    
    # 3. Setup or merge settings.local.json
    echo ""
    echo "⚙️  Configuring settings.local.json..."
    merge_settings_json
    
    echo ""
    echo "✅ ChromaDB configured successfully!"
    echo "   Data directory: $CHROMA_DIR"
    echo "   MCP config: $MCP_CONFIG"
    echo "   Claude config: ${PROJECT_ROOT}/CLAUDE.md"
    echo "   Settings: ${PROJECT_ROOT}/.claude/settings.local.json"
    echo ""
    echo "📝 CLAUDE.md instructs Claude to use ChromaDB for project memory."
    echo "   Collection: project_memory"
    echo ""
    echo "⚠️  IMPORTANT: Restart Claude Code to activate the ChromaDB MCP server."
    echo ""
    echo "After restart, you can use /chroma:validate, /chroma:migrate, and /chroma:stats commands."
}

setup_mcp_json() {
    # Existing .mcp.json setup logic from original script
    # (Lines 37-178 of original auto-setup.sh)
    # This already works well, no changes needed
    :
}
