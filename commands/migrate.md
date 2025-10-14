# Migrate ChromaDB Data

---
allowed-tools: Bash(*), Read(*), Edit(.mcp.json), mcp__chroma__*
description: Migrate ChromaDB data from external volumes to local project storage
---

## Your Task

Safely migrate ChromaDB data from external volumes (like `/Volumes/*`) to project-local storage to prevent path breakage.

### Migration Process

1. **Identify Source and Target**
   - **Source**: Current ChromaDB data location (from `.mcp.json`)
   - **Target**: Project-local `.chroma/` directory
   - Confirm source path exists and contains data

2. **Pre-Migration Validation**
   - Check source directory has `chroma.sqlite3` file
   - List collections in source to verify it's a valid ChromaDB instance
   - Estimate data size for migration
   - Ensure target location has sufficient disk space

3. **Backup Current Configuration**
   - Save current `.mcp.json` as `.mcp.json.backup.YYYYMMDD`
   - This allows rollback if migration fails

4. **Create Target Directory**
   - Create `.chroma/` in project root if it doesn't exist
   - Set proper permissions (read/write for user)

5. **Perform Migration**
   - Use `rsync` for safe, resumable copy:
     ```bash
     rsync -av --progress \
       "/source/path/.chroma/" \
       "./.chroma/"
     ```
   - Verify all files copied successfully
   - Compare file counts and sizes

6. **Update MCP Configuration**
   - Edit `.mcp.json` to point to new local path
   - Replace external volume path with project-relative path
   - Example:
     ```json
     {
       "mcpServers": {
         "chroma": {
           "args": [
             "--data-dir",
             "/absolute/path/to/project/.chroma"  // Use full project path
           ]
         }
       }
     }
     ```

7. **Test New Configuration**
   - Restart MCP connection
   - List collections to verify data is accessible
   - Run a test query on existing collection
   - Confirm all collections migrated successfully

8. **Post-Migration Validation**
   - Compare collection counts (source vs target)
   - Verify collection metadata intact
   - Test read/write operations
   - Confirm no data loss

9. **Cleanup (Optional)**
   - Ask user if they want to remove source data
   - **WARNING**: Only delete after confirmed successful migration
   - Keep backup on external volume for safety

10. **Generate Migration Report**

    ```
    ## ChromaDB Migration Report

    **Source**: /Volumes/WMUG-master/WMUG_master/7 - Documents/.chroma
    **Target**: /Users/username/project/.chroma
    **Migration Status**: ✅ Success | ❌ Failed

    ### Data Migrated
    - Collections: 2
    - Database Size: 1.2 MB
    - Files Transferred: 15
    - Duration: 2.3 seconds

    ### Collections Verified
    ✅ project_memory (120 documents)
    ✅ chromadb_memory (45 documents)

    ### Next Steps
    - MCP configuration updated to use local path
    - Test connection successful
    - Original data preserved on external volume
    - Safe to remove source after final verification
    ```

### Safety Guardrails

- **Never delete source data automatically** - Always ask user first
- **Use rsync** - Preserves timestamps, handles interruptions
- **Backup .mcp.json** - Always create backup before editing
- **Validate before cleanup** - Confirm migration success before any deletions
- **Preserve permissions** - Ensure target has correct access rights

### Error Handling

**If migration fails**:
1. Restore `.mcp.json` from backup
2. Keep source data untouched
3. Report specific error to user
4. Provide troubleshooting steps

**Common Issues**:
- Insufficient disk space → Check with `df -h`
- Permission denied → Check directory ownership
- Source disappeared → Remount external volume
- Rsync interrupted → Resume with same command

### Success Criteria

✅ All data copied to local `.chroma/` directory
✅ `.mcp.json` updated with new path
✅ MCP connection test successful
✅ All collections verified and accessible
✅ Migration report generated
✅ User informed about cleanup options
