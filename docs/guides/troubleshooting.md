# Claude-Chroma Troubleshooting Guide

## Common Issues and Solutions

### 🔴 Critical Issues

#### "ChromaDB MCP server not found"

**Symptom:**
```
Error: MCP server 'chromadb' not available
```

**Solutions:**
1. Install ChromaDB MCP server:
   ```bash
   uvx install chroma-mcp
   ```

2. Verify installation:
   ```bash
   uvx chroma-mcp --help
   ```

3. If uvx not found, you have two options:

   **Option A: Use the One-Click Installer (macOS only)**
   - Download `setup-claude-chroma-oneclick-fixed.command`
   - Double-click to run - it includes embedded uvx!

   **Option B: Manual installation**
   ```bash
   # Install via pipx (recommended)
   pipx install uv

   # Or via pip
   pip install --user uv

   # Or via the official installer
   curl -LsSf https://astral.sh/uv/install.sh | sh
   # Restart terminal or source profile
   source ~/.profile
   ```

   **Important**: Without uvx, the ChromaDB MCP server WILL NOT WORK and Claude won't have persistent memory.

---

#### "Claude Desktop doesn't recognize ChromaDB"

**Symptom:**
- No ChromaDB tools available in Claude
- Can't use `mcp__chroma__*` functions

**Solutions:**
1. Check Claude config location:
   - Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
   - Linux: `~/.config/Claude/claude_desktop_config.json`

2. Verify ChromaDB configuration exists:
   ```json
   {
     "mcpServers": {
       "chromadb": {
         "command": "uvx",
         "args": ["-qq", "chroma-mcp", "--data-dir", "./.chroma"],
         "env": {
           "ANONYMIZED_TELEMETRY": "FALSE",
           "PYTHONUNBUFFERED": "1",
           "TOKENIZERS_PARALLELISM": "false"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop** (required after config changes)

---

#### "Collection 'project_memory' not found"

**Symptom:**
```
Error: Collection project_memory does not exist
```

**Solutions:**
1. The collection auto-creates on first use in Claude
2. Just start working - Claude will create the collection automatically when you first mention a decision or ask it to remember something

---

### 🟡 Connection Issues

#### "Cannot connect to ChromaDB server"

**Symptom:**
```
Error: ChromaDB MCP server not responding
```

**Solutions:**
1. ChromaDB starts automatically when Claude loads via stdio - no manual start needed
2. If testing outside Claude:
   ```bash
   # Start temporary server for testing
   uvx -qq chroma-mcp --data-dir ./.chroma
   ```
3. Check MCP server is configured correctly:
   ```bash
   # Verify uvx can run chroma-mcp
   uvx -qq chroma-mcp --help
   ```

---

#### "Memory not persisting between sessions"

**Symptom:**
- Memories disappear after Claude restart
- Can't query previous memories

**Solutions:**
1. Ensure using stable IDs:
   ```javascript
   // Good - uses stable ID
   ids: ["auth-decision-2024"]

   // Bad - random ID each time
   ids: [Math.random().toString()]
   ```

2. Verify collection name is consistent:
   ```javascript
   // Always use same name
   "collection_name": "project_memory"
   ```

3. Check ChromaDB data persistence:
   - MCP server maintains persistence automatically
   - Local fallback uses `.chromadb/` directory

---

### 🟢 Configuration Issues

#### "CLAUDE.md not auto-initializing memory"

**Symptom:**
- Memory system doesn't start automatically
- Have to manually create collection

**Solutions:**
1. Ensure CLAUDE.md is in project root (not subdirectory)
2. Check auto-init section exists:
   ```markdown
   ## Project Memory (Chroma) - AUTO-INITIALIZE
   At session start, ALWAYS:
   1. Try to query the collection first
   2. If collection doesn't exist, create it
   ```
3. Verify Claude reads CLAUDE.md on startup

---

#### "Multiple ChromaDB installations conflicting"

**Symptom:**
```
ImportError: chromadb module version conflict
```

**Solutions:**
1. Use MCP server version (recommended):
   ```bash
   uvx chroma-mcp  # Isolated environment
   ```

2. If using local Python:
   ```bash
   pip3 uninstall chromadb
   pip3 install chromadb==0.4.24  # Specific version
   ```

3. Check for conflicts:
   ```bash
   pip3 list | grep chroma
   which chroma-mcp
   ```

---

### 🔧 Platform-Specific Issues

#### Mac: "Permission denied" errors

**Solutions:**
```bash
# Fix permissions
chmod +x chromadb/*.sh

# If using system Python
pip3 install --user chromadb
```

#### Windows: "Script not recognized"

**Solutions:**
1. Use Git Bash or WSL for shell scripts
2. Or run the main setup script:
   ```powershell
   .\claude-chroma.sh
   ```

#### Linux: "uvx command not found"

**Solutions:**
```bash
# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Or use full path
~/.local/bin/uvx chroma-mcp
```

---

### 📝 Testing and Validation

#### Run Complete Test Suite

```bash
./chromadb/test_chromadb.sh
```

Expected output:
```
✅ Python found
✅ uvx is installed
✅ ChromaDB MCP server is installed
✅ Claude configuration found
✅ ChromaDB server configured in Claude
✅ Project files exist
✅ ChromaDB connection successful
✅ Memory operations working
```

#### Manual Testing in Claude

Test memory operations:
```javascript
// 1. Create collection (if needed)
mcp__chroma__chroma_create_collection {
  "collection_name": "project_memory"
}

// 2. Add test memory
mcp__chroma__chroma_add_documents {
  "collection_name": "project_memory",
  "documents": ["Test memory from troubleshooting"],
  "metadatas": [{"type": "test", "tags": "debug", "source": "manual"}],
  "ids": ["test-troubleshoot"]
}

// 3. Query it back
mcp__chroma__chroma_query_documents {
  "collection_name": "project_memory",
  "query_texts": ["test troubleshooting"],
  "n_results": 1
}
```

---

### 🚨 Emergency Reset

If nothing works, complete reset:

```bash
# 1. Remove all ChromaDB data
rm -rf .chromadb/
rm -rf ~/.chromadb/

# 2. Reinstall MCP server
pip3 uninstall chroma-mcp
uvx install --force chroma-mcp

# 3. Reset Claude config
# Backup first!
cp ~/Library/Application\ Support/Claude/claude_desktop_config.json ~/claude_config_backup.json

# 4. Re-run setup
./chromadb/setup_chromadb.sh

# 5. Restart Claude Desktop
```

---

### 💡 Best Practices to Avoid Issues

1. **Always restart Claude** after configuration changes
2. **Use stable IDs** for memory entries
3. **Keep documents under 300 chars** (ChromaDB limit)
4. **One collection name** throughout project
5. **Test after setup** with test_chromadb.sh
6. **Check logs** in Claude Desktop developer console

---

### 📞 Getting Help

If issues persist:

1. **Check versions:**
   ```bash
   python3 --version  # Should be 3.8+
   uvx --version
   uvx chroma-mcp --version
   ```

2. **Collect diagnostics:**
   ```bash
   ./chromadb/test_chromadb.sh > diagnostic.log 2>&1
   ```

3. **Review logs:**
   - Claude Desktop: View → Developer Tools → Console
   - ChromaDB: Check `.chromadb/chroma.log` if exists

4. **Common working configurations:**
   - Mac: Claude 0.7.0+, Python 3.11, uvx 0.1.0+
   - Windows: Claude 0.7.0+, Python 3.10+, Git Bash
   - Linux: Claude 0.7.0+, Python 3.8+, native terminal

---

### ✅ Success Indicators

You know it's working when:
1. Claude shows "Contract loaded. Using Chroma project_memory." on startup
2. `mcp__chroma__*` functions are available
3. Memories persist across Claude restarts
4. Test script shows all green checkmarks
5. Can query previous session's memories

---

*Remember: Most issues are solved by restarting Claude Desktop after configuration changes!*