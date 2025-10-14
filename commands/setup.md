# ChromaDB MCP Server Setup

---
allowed-tools: Bash(*), Write(*), Edit(*), Read(*), mcp__chroma__*
description: Comprehensive ChromaDB setup with memory discipline and best practices
---

## Your Task

Set up complete ChromaDB MCP server integration for this project, matching the functionality of the claude-chroma.sh setup script.

### Phase 1: Prerequisites Check

1. **Verify Required Dependencies**
   - Check if `uvx` is installed (REQUIRED for running ChromaDB MCP)
     ```bash
     command -v uvx || echo "uvx not found"
     ```
   - Check if `jq` is installed (REQUIRED for JSON operations)
     ```bash
     command -v jq || echo "jq not found"
     ```
   - Check if `python3` is available (optional, for fallbacks)

   **If missing**:
   - uvx: `pip install --user uv` or `pipx install uv`
   - jq: `brew install jq` (Mac) or `apt-get install jq` (Linux)

   **If prerequisites missing**: Stop and ask user to install before continuing.

### Phase 2: Directory Structure

2. **Create Complete Directory Structure**
   ```bash
   mkdir -p .chroma
   mkdir -p .chroma/context
   mkdir -p claudedocs
   mkdir -p bin
   mkdir -p templates
   ```

   **Purpose of each directory**:
   - `.chroma/` - ChromaDB database storage
   - `.chroma/context/` - Context documents for Claude to read at session start
   - `claudedocs/` - Project documentation and reports
   - `bin/` - Utility scripts (chroma-stats.py, registry.sh, etc.)
   - `templates/` - Configuration templates (CLAUDE.md.tpl)

### Phase 3: MCP Configuration

3. **Configure MCP Server**
   - Check if `.mcp.json` exists in project root
   - **Backup existing config**: If `.mcp.json` exists, create `.mcp.json.backup.YYYYMMDD_HHMMSS`
   - Create or merge ChromaDB configuration using absolute project path for data-dir

   **Configuration template**:
   ```json
   {
     "mcpServers": {
       "chroma": {
         "type": "stdio",
         "command": "uvx",
         "args": [
           "-qq",
           "chroma-mcp",
           "--client-type",
           "persistent",
           "--data-dir",
           "/absolute/path/to/project/.chroma"
         ],
         "env": {
           "ANONYMIZED_TELEMETRY": "FALSE",
           "PYTHONUNBUFFERED": "1",
           "TOKENIZERS_PARALLELISM": "False",
           "CHROMA_SERVER_KEEP_ALIVE": "0",
           "CHROMA_CLIENT_TIMEOUT": "0"
         },
         "initializationOptions": {
           "timeout": 0,
           "keepAlive": true,
           "retryAttempts": 5
         }
       }
     }
   }
   ```

   **Important**: Use `pwd` to get absolute project path and substitute into data-dir.

### Phase 4: CLAUDE.md Template Rendering

4. **Create Project CLAUDE.md from Template**

   **Step 4a**: Check if `templates/CLAUDE.md.tpl` exists
   - If missing, create it with the template from this project's templates directory

   **Step 4b**: Generate PROJECT_COLLECTION name
   - Derive from project directory name: `basename $(pwd)`
   - Normalize: lowercase, replace spaces/dots/hyphens with underscores
   - Remove non-alphanumeric characters except underscores
   - Limit to 48 characters
   - Append `_memory` suffix
   - Example: "My Project" → "my_project_memory"

   **Step 4c**: Render template
   - Read `templates/CLAUDE.md.tpl`
   - Substitute `${PROJECT_COLLECTION}` with generated collection name
   - **Validate before writing**:
     - Content must not be empty
     - Content must not be whitespace-only
     - Content must be at least 10 characters
     - No unresolved placeholders like `${VARIABLE_NAME}` should remain

   **Step 4d**: Backup existing CLAUDE.md
   - If CLAUDE.md exists:
     - Create `CLAUDE.md.backup.YYYYMMDD_HHMMSS`
     - Create `CLAUDE.md.original` for easy user reference
     - Inform user their original instructions are preserved

   **Step 4e**: Write new CLAUDE.md
   - Write validated content
   - Set permissions: `chmod 644 CLAUDE.md`

### Phase 5: Memory Discipline Setup

5. **Configure Memory Discipline (Never modify global files!)**

   **Step 5a**: Check global CLAUDE.md (READ-ONLY)
   - Check if `~/.claude/CLAUDE.md` exists
   - Check if it contains "Memory Checkpoint Rules" or "Checkpoint Protocol"
   - **Never modify this file** - read-only check only

   **Step 5b**: Create project memory settings
   - Create `.claude/settings.local.json` in project with memory instructions:
     ```json
     {
       "instructions": [
         "IMPORTANT: This project uses ChromaDB for persistent memory",
         "Every 5 interactions, check if you have logged recent learnings",
         "After solving problems or making decisions, immediately log to ChromaDB",
         "Use mcp__chroma__chroma_add_documents to preserve discoveries",
         "Query existing memories at session start with mcp__chroma__chroma_query_documents",
         "Each memory should be under 300 chars with appropriate metadata",
         "Log architecture decisions, user preferences, fixes, and patterns"
       ],
       "permissions": {
         "allow": [],
         "deny": [],
         "ask": []
       }
     }
     ```
   - If `.claude/settings.local.json` already exists, merge instructions (don't duplicate)

   **Step 5c**: Create reminder document if needed
   - If global CLAUDE.md doesn't have memory rules, create `MEMORY_CHECKPOINT_REMINDER.md`
   - Include checkpoint protocol, session start queries, and memory schema

### Phase 6: .gitignore Management

6. **Create or Update .gitignore**
   - Check if `.gitignore` exists
   - **Backup if exists**: Create `.gitignore.backup.YYYYMMDD_HHMMSS`
   - Add or merge these entries (check if already present):
     ```
     # ChromaDB local database
     .chroma/
     *.chroma

     # Memory exports (optional - track for history)
     claudedocs/*.md

     # Python
     __pycache__/
     *.py[cod]
     .pytest_cache/

     # OS
     .DS_Store
     Thumbs.db

     # IDE
     .vscode/
     .idea/
     *.swp
     ```
   - Don't add duplicate lines - check before adding each entry

### Phase 7: Documentation Generation

7. **Generate Project Documentation**

   **INIT_INSTRUCTIONS.md**:
   - Create `claudedocs/INIT_INSTRUCTIONS.md` with:
     - Automatic setup overview
     - Manual ChromaDB commands (create collection, query, add documents)
     - Troubleshooting guide
     - Collection name reference (use PROJECT_COLLECTION)

   **start-claude-chroma.sh** (optional):
   - Create executable launcher script
   - Validates .mcp.json exists and is valid
   - Launches Claude with config
   - Set permissions: `chmod +x start-claude-chroma.sh`

### Phase 8: Connection Test

8. **Test MCP Connection**
   - Attempt to list collections: `mcp__chroma__chroma_list_collections`
   - If connection fails:
     - Check if uvx is in PATH
     - Verify .mcp.json is valid JSON
     - Test ChromaDB MCP server manually
     - Provide troubleshooting steps

   **Note**: Collection list may be empty (that's OK - collections created on demand)

### Phase 9: Setup Summary

9. **Generate Comprehensive Setup Report**

   ```markdown
   ## ChromaDB Setup Complete ✅

   **Project**: [project-name]
   **Collection**: [PROJECT_COLLECTION]
   **Data Directory**: /absolute/path/to/project/.chroma

   ### Files Created/Modified
   - ✅ .chroma/ (directory structure)
   - ✅ .mcp.json (MCP server configuration)
   - ✅ CLAUDE.md (project instructions from template)
   - ✅ .claude/settings.local.json (memory discipline)
   - ✅ .gitignore (ChromaDB entries)
   - ✅ claudedocs/INIT_INSTRUCTIONS.md (documentation)
   - ⚠️ [Backup files created if originals existed]

   ### Prerequisites Verified
   - ✅ uvx installed and accessible
   - ✅ jq available for JSON operations
   - ✅ ChromaDB MCP server can be launched

   ### Memory Discipline
   - ✅ Project settings configured with memory instructions
   - ✅ Memory checkpoint reminders in place
   - ⚠️ [Global CLAUDE.md status - has rules or reminder created]

   ### Connection Status
   - ✅ MCP server connection successful
   - Collections: [N] (list them or "none yet - will create on first use")

   ### Next Steps
   1. Start Claude: `claude` (from this directory)
   2. Claude will auto-read CLAUDE.md on startup
   3. Create first collection: `mcp__chroma__chroma_create_collection {"collection_name": "[PROJECT_COLLECTION]"}`
   4. Begin logging memories as you work

   ### Backup Information
   [List any backup files created with timestamps]
   - Original files preserved for reference
   - Backups kept for easy rollback if needed
   ```

### Important Notes

- **Path Strategy**: Use absolute paths in `.mcp.json` for robustness, but relative paths in documentation
- **Isolation**: Each project has its own ChromaDB instance in `.chroma/`
- **Safety**: Always backup before modifying existing files
- **Validation**: Verify content before writing (non-empty, properly formatted)
- **Global Files**: NEVER modify `~/.claude/CLAUDE.md` or `~/.claude/settings.local.json` - read-only checks only
- **Idempotency**: Running setup multiple times should be safe (check before creating/modifying)

### Success Criteria

✅ All prerequisites verified (uvx, jq)
✅ Complete directory structure created
✅ `.mcp.json` configured with infinite timeout settings
✅ CLAUDE.md rendered from template with PROJECT_COLLECTION
✅ Memory discipline configured (project settings + reminder if needed)
✅ .gitignore updated with ChromaDB entries
✅ Documentation generated (INIT_INSTRUCTIONS.md)
✅ MCP connection test successful
✅ All original files backed up before modification
✅ Comprehensive setup report provided
✅ User knows exactly what was changed and how to proceed

### Error Handling

If any step fails:
1. Report specific error with context
2. List what was completed successfully
3. Note any backup files created
4. Provide recovery instructions
5. Don't continue to next phase - stop and ask user how to proceed

### Comparison with Setup Script

This command preserves all critical functionality from `claude-chroma.sh` (v3.5.3):
- ✅ Prerequisites checking
- ✅ Complete directory structure
- ✅ Template-based CLAUDE.md rendering
- ✅ Memory discipline enforcement
- ✅ Backup system
- ✅ Documentation generation
- ✅ Safety validations

Features intentionally omitted (script-only):
- Shell function installer (modifies global shell RC files)
- Project registry (global state management)
- Dry-run mode (plugin is inherently preview-based)
- Non-interactive mode (not applicable to plugin context)
