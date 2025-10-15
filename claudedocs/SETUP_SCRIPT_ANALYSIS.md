# Auto-Setup Script Analysis: Non-Destructive Merge Strategy

**Date**: 2025-10-15  
**Scope**: Analysis of `/hooks/auto-setup.sh` merge behavior for existing projects

## Current Implementation Analysis

### What Works Well

1. **.mcp.json Merging** (Lines 37-178)
   - Uses Python JSON manipulation for proper merging
   - Preserves existing `mcpServers` entries
   - Only adds `chroma` server if not present
   - Fallback to bash heredoc if Python fails

2. **Idempotent Checks**
   - `is_chromadb_configured()` prevents redundant setup
   - Checks both `.chroma/` directory and `.mcp.json` presence

### Critical Gaps

#### 1. CLAUDE.md Handling (Lines 184-240)
**Current Behavior**:
```bash
if [ ! -f "${PROJECT_ROOT}/CLAUDE.md" ]; then
    # Create entire CLAUDE.md from scratch
fi
```

**Problem**: If `CLAUDE.md` exists, ChromaDB instructions are NEVER added.

**Impact**: Existing projects with `CLAUDE.md` won't get:
- ChromaDB memory contract section
- Chroma schema and call examples
- Retrieval checklist
- Memory checkpoint rules
- Activation instructions

#### 2. settings.local.json Handling (Lines 243-271)
**Current Behavior**:
```bash
if [ ! -f "${PROJECT_ROOT}/.claude/settings.local.json" ]; then
    # Create entire settings.local.json from scratch
fi
```

**Problem**: If `settings.local.json` exists, ChromaDB config is NEVER merged.

**Impact**: Existing projects won't get:
- `"chroma"` added to `enabledMcpjsonServers` array
- `mcpServers.chroma.alwaysAllow` permissions
- ChromaDB-specific instructions in `instructions` array

---

## Merge Strategy Design

### Design Principles

1. **Non-Destructive**: Never overwrite existing content
2. **Idempotent**: Running setup multiple times is safe
3. **Smart Detection**: Recognize if ChromaDB already configured
4. **Preserve Ordering**: Maintain existing structure/formatting
5. **Clear Boundaries**: Mark plugin-added content with comments
6. **Rollback-Friendly**: Changes are reversible

### Edge Cases to Handle

#### CLAUDE.md Scenarios

| Scenario | Current Behavior | Required Behavior |
|----------|-----------------|-------------------|
| No CLAUDE.md | Create from template | Create from template ✅ |
| CLAUDE.md exists, no Chroma section | Skip entirely ❌ | Append Chroma section |
| CLAUDE.md exists with Chroma section | Skip entirely ✅ | Skip (already configured) |
| CLAUDE.md exists with different Chroma collection | Skip entirely ❌ | Detect and warn/skip |
| CLAUDE.md with partial Chroma config | Skip entirely ❌ | Detect gaps and offer merge |

#### settings.local.json Scenarios

| Scenario | Current Behavior | Required Behavior |
|----------|-----------------|-------------------|
| No settings.local.json | Create from template | Create from template ✅ |
| Exists, no `enabledMcpjsonServers` | Skip entirely ❌ | Add array with ["chroma"] |
| Exists, has `enabledMcpjsonServers: []` | Skip entirely ❌ | Append "chroma" to array |
| Exists, has `enabledMcpjsonServers: ["other"]` | Skip entirely ❌ | Append "chroma" if missing |
| Exists, has `enabledMcpjsonServers: ["chroma"]` | Skip entirely ✅ | Skip (already configured) |
| Exists, no `mcpServers.chroma` | Skip entirely ❌ | Add chroma server config |
| Exists, has `mcpServers.chroma` | Skip entirely ✅ | Skip (already configured) |
| Exists, no `instructions` array | Skip entirely ❌ | Add ChromaDB instructions |
| Exists, has `instructions` array | Skip entirely ❌ | Merge ChromaDB instructions |
| Existing instructions duplicate plugin instructions | Skip entirely ❌ | Detect and skip duplicates |

---

## Implementation Strategy

### Option A: Python-Based Merge (Recommended)

**Pros**:
- Proper JSON parsing and manipulation
- Reliable array merging without duplicates
- Text block detection and insertion
- Better error handling

**Cons**:
- Additional Python dependency
- Slightly more complex

### Option B: Bash + jq

**Pros**:
- Standard Unix tools
- Fast execution

**Cons**:
- jq might not be installed
- Complex text manipulation in CLAUDE.md
- Array merging is verbose

### Option C: Hybrid (Recommended for This Project)

**Strategy**:
- Use Python for JSON files (settings.local.json)
- Use bash for text files (CLAUDE.md with marker detection)
- Fallback to bash heredoc if Python unavailable

**Rationale**: Already using Python for .mcp.json merging successfully

---

## Detailed Implementation Design

### 1. CLAUDE.md Merge Strategy

#### Detection Algorithm
```bash
detect_chromadb_in_claudemd() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"
    
    # Check if file exists
    [ ! -f "$claudemd" ] && return 1
    
    # Check for ChromaDB markers
    if grep -q "## 🧠 Project Memory (Chroma)" "$claudemd" || \
       grep -q "mcp__chroma__chroma_create_collection" "$claudemd" || \
       grep -q "collection_name.*project_memory" "$claudemd"; then
        return 0  # ChromaDB section exists
    fi
    
    return 1  # No ChromaDB section
}
```

#### Merge Implementation
```bash
merge_claudemd_chromadb() {
    local claudemd="${PROJECT_ROOT}/CLAUDE.md"
    
    # Detect if ChromaDB already configured
    if detect_chromadb_in_claudemd; then
        echo "   CLAUDE.md already has ChromaDB configuration, skipping..."
        return 0
    fi
    
    # Create backup
    cp "$claudemd" "${claudemd}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Append ChromaDB section with clear marker
    cat >> "$claudemd" << 'CHROMADB_SECTION'

# ═══════════════════════════════════════════════════════════
# ChromaDB Plugin Configuration (auto-added by claude-chroma)
# ═══════════════════════════════════════════════════════════

## 🧠 Project Memory (Chroma)
Use server \`chroma\`. Collection \`project_memory\`.

Log after any confirmed fix, decision, gotcha, or preference.

**Schema:**
- **documents**: 1–2 sentences. Under 300 chars.
- **metadatas**: \`{ "type":"decision|fix|tip|preference", "tags":"comma,separated", "source":"file|PR|spec|issue" }\`
- **ids**: stable string if updating the same fact.

### Chroma Calls
\`\`\`javascript
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
\`\`\`

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
- Query existing memories: \`mcp__chroma__chroma_query_documents\`
- Announce: **Contract loaded. Using Chroma project_memory.**

CHROMADB_SECTION

    echo "   ✅ Appended ChromaDB configuration to CLAUDE.md"
}
```

### 2. settings.local.json Merge Strategy

#### Python Merge Script
```python
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

def merge_chromadb_settings(settings_path):
    """Non-destructively merge ChromaDB config into settings.local.json"""
    
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
    
    # Add ChromaDB instructions if not already present
    for instruction in chromadb_instructions:
        # Check for similar instruction (fuzzy match)
        if not any(instruction.lower() in existing.lower() 
                  for existing in settings['instructions']):
            settings['instructions'].append(instruction)
            modified = True
    
    # Save if modified
    if modified:
        # Create backup
        backup_path = f"{settings_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(settings_path, backup_path)
        
        # Write merged settings
        with open(settings_path, 'w') as f:
            json.dump(settings, f, indent=2)
        
        return True  # Modified
    
    return False  # No changes needed
```

#### Bash Wrapper
```bash
merge_settings_json() {
    local settings_path="${PROJECT_ROOT}/.claude/settings.local.json"
    
    # If doesn't exist, create from template
    if [ ! -f "$settings_path" ]; then
        cat > "$settings_path" << 'SETTINGS'
{
  "enabledMcpjsonServers": ["chroma"],
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
SETTINGS
        echo "   ✅ Created settings.local.json"
        return 0
    fi
    
    # Exists, merge using Python
    python3 << 'PYTHON_MERGE'
import json
import sys
from datetime import datetime
import shutil

settings_path = "${settings_path}"

with open(settings_path, 'r') as f:
    settings = json.load(f)

modified = False

# Merge enabledMcpjsonServers
if 'enabledMcpjsonServers' not in settings:
    settings['enabledMcpjsonServers'] = []
    modified = True

if 'chroma' not in settings['enabledMcpjsonServers']:
    settings['enabledMcpjsonServers'].append('chroma')
    modified = True

# Merge mcpServers.chroma
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

# Merge instructions
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

for instruction in chromadb_instructions:
    if not any(instruction.lower() in existing.lower() 
              for existing in settings.get('instructions', [])):
        settings['instructions'].append(instruction)
        modified = True

if modified:
    # Create backup
    import shutil
    from datetime import datetime
    backup_path = f"{settings_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(settings_path, backup_path)
    
    # Write merged
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
    
    print("MODIFIED")
else:
    print("UNCHANGED")
PYTHON_MERGE

    if [ $? -eq 0 ]; then
        echo "   ✅ Merged ChromaDB config into settings.local.json"
    else
        echo "   ⚠️  Failed to merge settings.local.json (Python error)"
    fi
}
```

---

## Risk Assessment

### Low Risk
- .mcp.json merging (already working well)
- New project setup (no existing files)

### Medium Risk
- CLAUDE.md appending (text format, but clear markers)
- Duplicate instruction detection (fuzzy matching needed)

### High Risk
- settings.local.json merging with existing permissions arrays
- Existing non-standard CLAUDE.md structures
- UTF-8 encoding issues in CLAUDE.md

### Mitigation Strategies

1. **Always Create Backups**
   ```bash
   cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
   ```

2. **Clear Markers for Plugin Content**
   ```markdown
   # ═══════════════════════════════════════════════════════════
   # ChromaDB Plugin Configuration (auto-added by claude-chroma)
   # ═══════════════════════════════════════════════════════════
   ```

3. **Detect Before Merge**
   - Check for existing ChromaDB configuration before any modifications
   - Use multiple detection heuristics (keywords, structure, markers)

4. **Idempotent Operations**
   - Running setup multiple times should not duplicate content
   - Array merging uses set semantics (no duplicates)

5. **Fail-Safe Defaults**
   - If Python fails, skip merge and warn user
   - Never partially modify files on error

---

## Testing Strategy

### Test Matrix

| Test Case | CLAUDE.md State | settings.local.json State | Expected Outcome |
|-----------|----------------|---------------------------|------------------|
| Fresh Project | Missing | Missing | Create both from templates |
| Partial Setup | Missing | Exists (no chroma) | Create CLAUDE.md, merge settings |
| Partial Setup | Exists (no chroma) | Missing | Append CLAUDE.md, create settings |
| Partial Setup | Exists (no chroma) | Exists (no chroma) | Append CLAUDE.md, merge settings |
| Already Configured | Exists (has chroma) | Exists (has chroma) | Skip both (idempotent) |
| Mixed Config | Exists (has chroma) | Exists (no chroma) | Skip CLAUDE.md, merge settings |
| Corrupted Config | Invalid format | Invalid JSON | Backup and recreate |

### Validation Commands

```bash
# Test detection
bash -c "source hooks/auto-setup.sh; detect_chromadb_in_claudemd"

# Test full setup on new project
mkdir -p /tmp/test-project && cd /tmp/test-project
bash /path/to/auto-setup.sh

# Test merge on existing project
cd /tmp/test-project-with-claudemd
bash /path/to/auto-setup.sh

# Verify idempotency
bash /path/to/auto-setup.sh  # Run twice
diff CLAUDE.md CLAUDE.md.backup.*  # Should be identical
```

---

## Implementation Roadmap

### Phase 1: Enhanced Detection (Low Risk)
- Add `detect_chromadb_in_claudemd()` function
- Add `detect_chromadb_in_settings()` function
- Test detection on various file formats

### Phase 2: CLAUDE.md Merge (Medium Risk)
- Implement `merge_claudemd_chromadb()` with markers
- Add backup creation
- Test append logic with existing files

### Phase 3: settings.local.json Merge (Medium-High Risk)
- Create Python merge script
- Implement bash wrapper with fallback
- Test JSON merging on various existing configs

### Phase 4: Integration & Testing (Critical)
- Update main `setup_chromadb()` function
- Create comprehensive test suite
- Document merge behavior in README

### Phase 5: User Communication
- Add clear output messages for each merge action
- Warn users when manual review recommended
- Document rollback procedures

---

## Recommended Implementation Order

1. **Read Existing Files First** (10 lines of bash)
2. **Detection Functions** (30 lines of bash)
3. **CLAUDE.md Merge** (50 lines of bash)
4. **settings.local.json Merge** (80 lines of Python + bash wrapper)
5. **Update main setup_chromadb()** (20 lines refactor)
6. **Testing & Validation** (separate test script)

**Total Estimated LOC**: ~200 lines (mostly Python for JSON handling)

---

## Conclusion

**Current Status**: Auto-setup script is non-destructive for .mcp.json but ignores existing CLAUDE.md and settings.local.json entirely.

**Recommended Approach**: Hybrid Python/Bash merge strategy with:
- Clear detection before merge
- Backup creation for safety
- Marker-based content insertion
- Idempotent operations
- Comprehensive testing

**Risk Level**: Medium (manageable with proper testing and backups)

**Implementation Complexity**: Moderate (most complexity in JSON merging, which has precedent in existing .mcp.json logic)

**User Impact**: High positive impact (enables plugin use with existing projects without manual configuration)
