# Path Update on Project Move - Design Document

## Problem Statement

When users move their project folder, `.mcp.json` contains an absolute path that becomes invalid:

```json
{
  "args": ["--data-dir", "/old/path/to/project/.chroma"]
}
```

After moving project to `/new/path/to/project/`, ChromaDB MCP server fails because:
- Path in `.mcp.json` still points to `/old/path/to/project/.chroma`
- SessionStart hook knows current path (`$PWD`) but doesn't update config

## Solution Design

### Detection Logic

Add function to detect path mismatch:

```bash
needs_path_update() {
    # Only check if .mcp.json exists
    [ ! -f "$MCP_CONFIG" ] && return 1

    # Extract current data-dir path from .mcp.json
    local current_path=$(python3 -c "
import json
try:
    with open('$MCP_CONFIG', 'r') as f:
        config = json.load(f)
    chroma = config.get('mcpServers', {}).get('chroma', {})
    args = chroma.get('args', [])
    for i, arg in enumerate(args):
        if arg == '--data-dir' and i+1 < len(args):
            print(args[i+1])
            break
except:
    pass
" 2>/dev/null)

    # Check if path exists and matches current expected path
    if [ -n "$current_path" ] && [ "$current_path" != "$CHROMA_DIR" ]; then
        # Path mismatch detected
        return 0
    fi

    return 1
}
```

### Update Logic

```bash
update_mcp_path() {
    local old_path=$(python3 -c "
import json
with open('$MCP_CONFIG', 'r') as f:
    config = json.load(f)
chroma = config.get('mcpServers', {}).get('chroma', {})
args = chroma.get('args', [])
for i, arg in enumerate(args):
    if arg == '--data-dir' and i+1 < len(args):
        print(args[i+1])
        break
" 2>/dev/null)

    echo "📍 Project path changed detected:"
    echo "   Old: $old_path"
    echo "   New: $CHROMA_DIR"

    # Create backup
    cp "$MCP_CONFIG" "${MCP_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

    # Update path using Python
    python3 -c "
import json
with open('$MCP_CONFIG', 'r') as f:
    config = json.load(f)

# Update data-dir argument
if 'mcpServers' in config and 'chroma' in config['mcpServers']:
    args = config['mcpServers']['chroma'].get('args', [])
    for i, arg in enumerate(args):
        if arg == '--data-dir' and i+1 < len(args):
            args[i+1] = '$CHROMA_DIR'
            break
    config['mcpServers']['chroma']['args'] = args

with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
"

    echo "   ✅ Updated .mcp.json with new path"
    echo "   ⚠️  IMPORTANT: Restart Claude Code to apply changes"
}
```

### Integration into Main Logic

Insert before checking if chromadb is configured:

```bash
# ==============================================================================
# Main Logic
# ==============================================================================

# Track if anything was modified
MODIFIED=false

# 0. Check for path update needed (before other checks)
if needs_path_update; then
    update_mcp_path
    MODIFIED=true
fi

# 1. Check and setup .chroma directory if needed
if [ ! -d "$CHROMA_DIR" ]; then
    mkdir -p "$CHROMA_DIR"
    MODIFIED=true
fi

# ... rest of logic
```

## User Experience

### Scenario: User Moves Project

**Before** (current behavior):
```
User moves: ~/Desktop/myapp → ~/Documents/myapp
Opens Claude Code → ChromaDB MCP fails silently
No clear error message
```

**After** (with path update):
```
User moves: ~/Desktop/myapp → ~/Documents/myapp
Opens Claude Code → SessionStart hook detects path change
Output:
  📍 Project path changed detected:
     Old: /Users/user/Desktop/myapp/.chroma
     New: /Users/user/Documents/myapp/.chroma
     ✅ Updated .mcp.json with new path
     ⚠️  IMPORTANT: Restart Claude Code to apply changes

User restarts Claude Code → ChromaDB works correctly
```

## Edge Cases

### 1. Data Directory Doesn't Exist at Old Path
**Situation**: User moved project, old `.chroma` dir no longer exists
**Solution**: Existing logic already handles - creates new `.chroma` directory

### 2. Data Directory Exists at Both Paths
**Situation**: User copied (not moved) project
**Solution**: Uses new path, two separate ChromaDB instances (correct behavior)

### 3. User Manually Edited .mcp.json
**Situation**: User has custom path that doesn't match project root
**Detection**: `current_path != $CHROMA_DIR`
**Decision**: Should we update or respect manual config?

**Recommendation**: Add flag to check if path starts with old PROJECT_ROOT

```bash
needs_path_update() {
    # ... existing extraction ...

    # Only update if old path was relative to some project root
    # (contains /.chroma at the end)
    if [[ "$current_path" == *"/.chroma" ]] && [ "$current_path" != "$CHROMA_DIR" ]; then
        return 0  # Path was project-relative, update it
    fi

    return 1  # Custom absolute path, respect it
}
```

## Testing Plan

### Test Case 1: Fresh Project
- Create new project
- Install plugin
- Verify `.mcp.json` created with correct path

### Test Case 2: Move Project
- Create project at path A
- Install plugin
- Move project to path B
- Restart Claude Code
- Verify path updated automatically
- Verify ChromaDB data still accessible

### Test Case 3: Copy Project
- Create project
- Install plugin
- Copy project to new location
- Both projects should have independent ChromaDB instances

### Test Case 4: Custom Path
- Manually set data-dir to `/custom/path/`
- Move project
- Verify custom path is NOT auto-updated (respects user intent)

## Implementation Priority

**High Priority**: Essential for project portability
**User Impact**: High - moving projects is common
**Implementation Effort**: Medium - needs careful testing

## Alternative: Relative Paths

**Could we use relative paths instead?**

```json
"args": ["--data-dir", ".chroma"]
```

**Research needed**:
- Does chroma-mcp support relative paths?
- What is the CWD when MCP server starts?

**Advantage**: No path updates needed
**Risk**: If CWD isn't project root, breaks anyway
