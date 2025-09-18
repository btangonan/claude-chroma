# Migration Guide: claude-chroma.sh v3.0 to v3.1

## Breaking Changes

### 1. Removed `.claude/settings.local.json`
**Why**: Claude's schema validation rejects the "instructions" field
**Impact**: Projects using v3.0 will have invalid configuration files
**Automatic Migration**: The script now automatically removes invalid files

### 2. Changed Default Project Path
**Old**: `/Users/bradleytangonan/Desktop/my apps` (hardcoded)
**New**: Intelligent detection:
- First tries: `$HOME/projects`
- Then tries: `$HOME/Documents/projects`
- Then tries: `$HOME/Desktop/projects`
- Falls back to: `$HOME`

### 3. Fixed Command Suggestions
**Old (incorrect)**: `claude --mcp-config .claude/settings.local.json chat`
**New (correct)**: `claude chat` (auto-detects .mcp.json)

## What Gets Created Now

| File | Purpose | v3.0 | v3.1 |
|------|---------|------|------|
| `.mcp.json` | MCP server configuration | ✅ | ✅ |
| `CLAUDE.md` | Project instructions | ✅ | ✅ |
| `.claude/settings.local.json` | Invalid config | ❌ Created | ✅ Not created |
| `.claude/` directory | Container | Created | Not created |
| `.gitignore` | Version control | ✅ | ✅ |
| `start-claude-chroma.sh` | Launcher | ✅ | ✅ |

## Automatic Migration

When you run v3.1 on a project that has v3.0 files:
1. Script detects invalid `.claude/settings.local.json`
2. Automatically removes the invalid file
3. Removes empty `.claude/` directory if no other files exist
4. Continues with normal setup

## Manual Migration (if needed)

If automatic migration doesn't work:

```bash
# Remove invalid settings file
rm .claude/settings.local.json

# Remove empty .claude directory
rmdir .claude

# Re-run the setup script
./claude-chroma.sh
```

## How It Works Now

1. **`.mcp.json`** - Makes Chroma MCP server available to Claude
2. **`CLAUDE.md`** - Contains all instructions for using Chroma
3. **No `.claude/settings.local.json`** - Not needed, causes errors

## Testing Your Setup

1. Start Claude in your project directory:
   ```bash
   claude chat
   ```

2. Check that Chroma is available:
   ```
   /mcp
   ```
   Should show "chroma" in the list

3. Test memory creation:
   ```javascript
   mcp__chroma__chroma_create_collection { "collection_name": "project_memory" }
   ```

## Troubleshooting

### Problem: "Invalid MCP configuration" error
**Solution**: You have an old settings.local.json. Re-run the v3.1 script.

### Problem: Chroma not showing in /mcp list
**Solution**: Make sure you're in the project directory with .mcp.json

### Problem: Instructions not working
**Solution**: Check that CLAUDE.md exists and contains the Chroma instructions

## Summary

v3.1 fixes critical bugs that prevented Chroma from working properly:
- ✅ Proper MCP server loading via .mcp.json
- ✅ Instructions in CLAUDE.md (where they belong)
- ✅ Portable paths that work for any user
- ✅ Automatic migration from v3.0
- ❌ No more invalid settings.local.json files