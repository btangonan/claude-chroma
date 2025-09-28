# Security Hardening Implementation

## Overview
This document describes the security hardening measures implemented in claude-chroma v3.5.4+, addressing critical vulnerabilities identified in the security audit.

## Registry Safety (bin/registry.sh)

### Cross-Platform Locking Strategy
The registry uses a three-tier locking approach for maximum compatibility:

```bash
_lock_run() {
    # Priority order:
    # 1. flock (Linux) - kernel-level file locking
    # 2. lockf (macOS) - native BSD lock facility
    # 3. mkdir (fallback) - atomic directory creation
}
```

**Implementation Details:**
- `flock -x`: Exclusive lock via file descriptor (Linux)
- `lockf -k`: Keep trying until lock acquired (macOS)
- `mkdir`: Atomic operation on all POSIX systems

**Edge Cases:**
- Stale lock detection in mkdir fallback (10-second timeout)
- lockf truncation risk mitigated by `-k` flag
- All locks cleaned up in EXIT trap

### Atomic JSONL Operations
All registry modifications use atomic write patterns:

```bash
# Pattern used throughout:
temp="${REGISTRY}.tmp.$$"     # Same directory as target
umask 077                      # Strict permissions from creation
cat > "$temp"                  # Write to temp
chmod 600 "$temp"             # Enforce permissions
mv -f "$temp" "$REGISTRY"     # Atomic replace
```

**Key Safety Features:**
- jq for JSON manipulation (no regex/sed on structured data)
- Safe defaults when jq missing (skip update vs corrupt)
- Temp files in same directory (no cross-device mv)
- Double permission enforcement (umask + chmod)

### Concurrency Testing
Verified with parallel operations:
```bash
seq 10 | xargs -n1 -P10 -I{} registry.sh bump "$path"
# Result: sessions=10, no corruption, no partial writes
```

## Path Portability (.mcp.json)

### Absolute Path Resolution
The installer now computes absolute paths at installation time:

```bash
local data_dir_rel="${DATA_DIR_OVERRIDE:-.chroma}"
local project_dir_abs="$(pwd)"
local data_dir_abs="$project_dir_abs/$data_dir_rel"

if command -v realpath >/dev/null 2>&1; then
    data_dir_abs="$(realpath -m "$data_dir_abs")"
fi
```

**Benefits:**
- No CWD dependency when Claude launches
- Projects relocatable (path computed at install)
- IDE/launcher compatibility (different working dirs)
- Boundary validation prevents escaping project

### Migration Path
Existing installations with relative paths will be updated on next run:
1. Installer detects existing .mcp.json
2. Backs up current configuration
3. Regenerates with absolute paths
4. Validates configuration before finalizing

## Security Checklist

### File Permissions
- [x] Registry: 600 (read/write owner only)
- [x] .mcp.json: 600 (contains project paths)
- [x] Lock files: Created with umask 077
- [x] Temp files: 600 before atomic move

### Race Conditions
- [x] Registry updates: Locked with platform-native mechanisms
- [x] File creation: Atomic mv operations
- [x] Directory creation: mkdir atomic guarantee
- [x] Cleanup: EXIT traps for all temporary resources

### Input Validation
- [x] Path validation: assert_within checks
- [x] JSON validation: jq parsing before use
- [x] Command injection: Quoted variables throughout
- [x] Path traversal: Absolute path resolution with boundaries

## Known Limitations

1. **lockf on older macOS**: Falls back to mkdir if unavailable
2. **Stale locks**: mkdir fallback has 10-second timeout (could use PID checking)
3. **jq dependency**: Soft requirement (degrades gracefully)
4. **Network filesystems**: Locking behavior varies (NFS, SMB)

## Testing Procedures

### Concurrency Test
```bash
# Create test entry
registry.sh add "test" "$PWD" "test_memory"

# Run parallel bumps
seq 100 | xargs -n1 -P20 -I{} registry.sh bump "$PWD"

# Verify count
registry.sh find "$PWD" | jq .sessions
# Expected: 100
```

### Portability Test
```bash
# Install in directory A
cd /path/A && ./claude-chroma.sh

# Move to directory B
mv /path/A /path/B

# Verify paths updated
cat /path/B/.mcp.json | jq '.mcpServers.chroma.args'
# Should show /path/B/.chroma
```

### Permission Test
```bash
# Check registry permissions
stat -c "%a" ~/.config/claude/chroma_projects.jsonl  # Linux
stat -f "%OLp" ~/.config/claude/chroma_projects.jsonl # macOS
# Expected: 600

# Check .mcp.json permissions
stat -c "%a" .mcp.json  # Linux
stat -f "%OLp" .mcp.json # macOS
# Expected: 600
```

## Future Improvements

1. **Enhanced stale lock detection**: Add PID checking to mkdir fallback
2. **Distributed locking**: Support for network filesystems
3. **Audit logging**: Track all registry modifications
4. **Signature verification**: GPG signing for installer integrity

## Security Contact

Report security issues to: security@claude-chroma.dev (or via GitHub Security Advisory)

---

*Last updated: 2025-09-28*
*Version: Post-audit hardening (commits b6865cd, ed45a1c)*