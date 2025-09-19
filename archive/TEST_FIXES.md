# ChromaDB Connection Fixes

## Issues Fixed

### 1. Shell Function Looking for Wrong File ✅
**Problem**: `claude-chroma` function was looking for `.claude/settings.local.json` instead of `.mcp.json`
**Fix**: Updated shell function in `~/.zshrc` to search for `.mcp.json`

### 2. Session Timeout After Inactivity ✅
**Problem**: ChromaDB MCP server disconnects during inactivity
**Fix**: Added timeout and keep-alive settings to `.mcp.json`:
- `CHROMA_SERVER_KEEP_ALIVE`: 1 hour
- `CHROMA_CLIENT_TIMEOUT`: 5 minutes
- Retry attempts and keep-alive options

## How to Use

### Option 1: Use the Shell Function (Recommended)
```bash
# From ANY directory (even your WMUG transcripts directory)
claude-chroma

# The function will:
# 1. Search upward for .mcp.json
# 2. Auto-switch to ChromaDB project directory
# 3. Start Claude with memory enabled
```

### Option 2: Manual Navigation
```bash
# Navigate to any ChromaDB project directory
cd "/Users/bradleytangonan/Desktop/my apps/chromadb"
claude chat
```

### Option 3: Direct Launcher
```bash
# Use project-specific launcher
cd "/Users/bradleytangonan/Desktop/my apps/chromadb"
./start-claude-chroma.sh
```

## Testing the Fix

1. **Test shell function from different directory**:
   ```bash
   cd /tmp
   claude-chroma  # Should find and use ChromaDB config
   ```

2. **Verify session persistence**:
   - Start Claude with ChromaDB
   - Leave idle for 10+ minutes
   - Try to use memory - should still work

## Troubleshooting

- **Shell function not found**: Run `source ~/.zshrc` to reload
- **Still shows setup message**: Ensure using `claude-chroma` command, not `claude chat`
- **Session timeout persists**: Restart Claude and try again with new config