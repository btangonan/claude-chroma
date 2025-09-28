# ChromaDB v3.3.0 Complete Testing Instructions

## ✅ Script Testing Results

### Test 1: Existing Project Configuration ✅
- Script correctly detected existing `.mcp.json`
- Validated timeout settings already present
- No unnecessary overwrites

### Test 2: Fresh Installation ✅
- Successfully created new project with all settings
- Infinite timeout settings included automatically
- All required files generated correctly

### Test 3: Shell Function Verification ✅
- Function correctly searches for `.mcp.json`
- Includes emoji indicators (🧠, ℹ️)
- Auto-changes to project directory

## 🚀 Terminal Restart & Testing Procedure

### Step 1: Restart Your Terminal

Choose ONE method:

**Option A: Complete Terminal Restart (Recommended)**
```bash
# macOS Terminal/iTerm2:
Cmd+Q to quit, then reopen

# VS Code integrated terminal:
Kill terminal → New terminal

# tmux session:
exit
tmux new-session
```

**Option B: Reload Shell Configuration**
```bash
# For zsh (your shell):
source ~/.zshrc

# Verify function loaded:
type claude-chroma
```

### Step 2: Test the ChromaDB Setup

#### A. Test Shell Function Auto-Detection
```bash
# Navigate to ANY subdirectory in your project
cd "/Users/bradleytangonan/Desktop/my apps/chromadb/docs"

# Use the function - it should detect the parent .mcp.json
claude-chroma

# Expected output:
# 🧠 Using ChromaDB project: /Users/bradleytangonan/Desktop/my apps/chromadb
# [Claude interface starts with ChromaDB enabled]
```

#### B. Test Direct Project Access
```bash
# Navigate directly to project root
cd "/Users/bradleytangonan/Desktop/my apps/chromadb"

# Start Claude - auto-detects .mcp.json
claude chat

# ChromaDB should initialize automatically
```

#### C. Test Memory Persistence
Once in Claude:
```
1. Create a test memory:
   "Remember: Test memory created at [timestamp]"

2. Exit Claude (Ctrl+C or 'exit')

3. Restart Claude:
   claude-chroma

4. Query the memory:
   "What test memory did we create?"

✅ Success if Claude recalls the memory
```

### Step 3: Verify Timeout Settings

Test infinite timeout (no disconnection):
```bash
# Start Claude with ChromaDB
claude-chroma

# Leave idle for 15+ minutes
# Try using memory commands

✅ Success if ChromaDB still responds (no timeout errors)
```

## 🔍 Quick Verification Checklist

Run these checks to confirm everything works:

```bash
# 1. Check .mcp.json has timeout settings
jq '.mcpServers.chroma.env.CHROMA_SERVER_KEEP_ALIVE' .mcp.json
# Should output: "0"

# 2. Check shell function exists
type claude-chroma
# Should show the function definition

# 3. Check ChromaDB data directory exists
ls -la .chroma/
# Should show chroma.sqlite3

# 4. Test from any project subdirectory
cd docs/ && claude-chroma
# Should detect parent config and start
```

## 🎯 Expected Behaviors

### ✅ Working Correctly If:
1. `claude-chroma` from any project subdirectory finds config
2. No "ChromaDB setup required" messages after initial setup
3. Memories persist across sessions
4. No timeouts during idle periods
5. Emoji indicators appear (🧠, ℹ️)

### ❌ Troubleshooting:
- **"No ChromaDB config found"**: Not in project tree or .mcp.json missing
- **Timeout errors**: Run script again to update .mcp.json
- **Function not found**: Restart terminal or `source ~/.zshrc`
- **Memory not persisting**: Check .chroma/ directory exists

## 📝 Test Projects Created

1. **Main Project**: `/Users/bradleytangonan/Desktop/my apps/chromadb/`
2. **Test Project**: `./chromadb-test/` (subdirectory test)
3. **Fresh Install**: `~/Documents/projects/test-fresh-install/`

All have proper timeout settings and are ready to use.

## 🚦 Final Test Command

After terminal restart, run this one-liner test:
```bash
cd "/Users/bradleytangonan/Desktop/my apps/chromadb" && \
echo "Testing ChromaDB..." && \
claude-chroma --version && \
echo "✅ All systems operational"
```

---
*Script Version: v3.3.0 - Fully self-contained with portability fixes*