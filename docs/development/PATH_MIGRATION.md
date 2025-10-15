# Path Migration Guide

## The Problem

ChromaDB projects use absolute paths in three locations:
1. **`.mcp.json`** - ChromaDB server data directory
2. **`.claude/settings.local.json`** - File read permissions
3. **`~/.config/Claude/chroma_projects.jsonl`** - Project registry

When you move a project to a new directory or drive, these paths break and Chroma MCP fails to connect.

## Quick Fix: Auto-Repair Tool

The easiest solution is the auto-repair utility:

```bash
cd /path/to/your/moved/project
./path/to/claude-chroma/bin/fix-paths.sh
```

The tool will:
1. Detect the old path from `.mcp.json`
2. Compare it to your current directory
3. Ask for confirmation
4. Update all three configuration files
5. Create backups of originals

### Manual Path Specification

If auto-detect doesn't work:

```bash
./path/to/claude-chroma/bin/fix-paths.sh "/old/path" "/new/path"
```

## Manual Fix Process

If you prefer to fix paths manually:

### 1. Update `.mcp.json`

```bash
# Old path
"--data-dir",
"/Volumes/OldDrive/Projects/myproject/.chroma"

# New path
"--data-dir",
"/Volumes/NewDrive/Projects/myproject/.chroma"
```

### 2. Update `.claude/settings.local.json`

Remove old read permissions, add new ones:

```json
{
  "permissions": {
    "allow": [
      "Read(//Volumes/OldDrive/Projects/**)",  // Remove this
      "Read(//Volumes/NewDrive/Projects/**)"   // Add this
    ]
  }
}
```

### 3. Update Registry

```bash
# Edit ~/.config/Claude/chroma_projects.jsonl
# Find the line with your project's old path and update it
sed -i.bak 's|/old/path|/new/path|g' ~/.config/Claude/chroma_projects.jsonl
```

### 4. Restart Claude

```bash
# Quit Claude Desktop completely (Cmd+Q)
# Relaunch and navigate to project
cd /new/path/to/project
claude
```

## Prevention Strategies

### Option 1: Project-Local Tools

Copy `fix-paths.sh` to your project:

```bash
cp /path/to/claude-chroma/bin/fix-paths.sh ./bin/
chmod +x ./bin/fix-paths.sh
```

Then after any move:
```bash
./bin/fix-paths.sh
```

### Option 2: Re-run Setup

Alternatively, re-run `claude-chroma.sh` to regenerate configs:

```bash
# In your moved project directory
/path/to/claude-chroma/claude-chroma.sh
```

This will:
- Detect existing `.mcp.json` and offer to update
- Update registry with new path
- Preserve your `.chroma` database

### Option 3: Relative Paths (Advanced)

**⚠️ Not recommended** - can fail if Claude isn't launched from project directory.

Edit `.mcp.json` to use relative path:

```json
"--data-dir",
"./.chroma"  // Relative to project root
```

**Caveat**: This only works if you always launch Claude from the exact project directory.

## Verification

After fixing paths, verify Chroma is connected:

```bash
cd /new/project/path
claude

# In Claude, run:
/mcp
```

Should show `chroma` as connected ✅

## Troubleshooting

### "No such tool: mcp__chroma__*"

- Chroma MCP not loaded
- Check `.mcp.json` exists and has correct paths
- Verify `.claude/settings.local.json` has `"enabledMcpjsonServers": ["chroma"]`
- Ensure you restarted Claude Desktop

### "Connection failed" or timeout errors

- `.chroma` directory doesn't exist at specified path
- Check path is absolute, not relative
- Verify directory permissions (should be readable/writable)

### Registry not updating

- Check `~/.config/Claude/chroma_projects.jsonl` exists
- Verify you have write permissions
- Look for backup files (`.backup.*`) if sed failed

## Why Absolute Paths?

The installer uses absolute paths by design:
- **Reliability**: Works regardless of current working directory
- **Clarity**: No ambiguity about which `.chroma` directory
- **Safety**: Prevents accidental path traversal

The trade-off is needing to update paths after moves, which this guide addresses.

## Future Improvements

Planned enhancements:
- [ ] Auto-detect path changes on `claude-chroma.sh` re-run
- [ ] Symlink support for cross-drive moves
- [ ] Registry-based path resolution (path-independent lookup)
- [ ] Integration with `claude` command to auto-repair
