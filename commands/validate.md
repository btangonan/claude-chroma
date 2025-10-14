# Validate ChromaDB Configuration

---
allowed-tools: Bash(*), Read(.mcp.json), mcp__chroma__*
description: Validate ChromaDB paths, configuration, and connection health
---

## Your Task

Perform comprehensive validation of ChromaDB MCP server configuration and detect/fix path issues.

### Validation Steps

1. **Check MCP Configuration**
   - Verify `.mcp.json` exists in project root
   - Extract configured `--data-dir` path from MCP config
   - Validate JSON structure is correct

2. **Validate Data Directory Path**
   - Check if configured path exists and is accessible
   - Verify read/write permissions
   - Detect if path is on external volume (`/Volumes/*`)
   - Warn about external volume risks (unmounting, disconnection)

3. **Test MCP Connection**
   - Attempt to list ChromaDB collections
   - If connection fails, diagnose the issue:
     - Path doesn't exist
     - Permissions issue
     - MCP server not running
     - Invalid configuration

4. **Path Location Analysis**
   - **✅ GOOD**: Project-local path (`.chroma/` or `.claude/chroma/`)
   - **⚠️ WARNING**: External volume path (`/Volumes/*`)
   - **❌ BAD**: Path doesn't exist or isn't accessible

5. **Generate Validation Report**

   ```
   ## ChromaDB Validation Report

   **MCP Config**: ✅ Found at .mcp.json
   **Data Directory**: /path/to/.chroma
   **Path Status**: ✅ Local | ⚠️ External Volume | ❌ Not Found
   **Permissions**: ✅ Read/Write | ❌ Permission Denied
   **Connection Test**: ✅ Connected | ❌ Failed
   **Collections Found**: 2 (project_memory, chromadb_memory)

   ### Recommendations
   - [If external volume] Consider migrating to local storage with /chroma:migrate
   - [If path missing] Run /chroma:setup to configure properly
   - [If connection failed] Check MCP server logs with /mcp
   ```

6. **Provide Actionable Next Steps**
   - If validation passes: Confirm everything is working
   - If external volume detected: Suggest migration command
   - If path broken: Provide fix command or manual steps
   - If MCP down: Guide user to restart or reconfigure

### Detection Patterns

**External Volume Detection**:
- Paths starting with `/Volumes/`
- Mounted network drives
- Removable storage

**Common Issues**:
- Volume was unmounted → Path no longer exists
- Project moved → Absolute paths broke
- Permissions changed → Can't read/write
- MCP server crashed → Connection refused

### Success Criteria

✅ Complete validation report generated
✅ All issues identified with severity levels
✅ Clear remediation steps provided
✅ User knows exactly what to do next
