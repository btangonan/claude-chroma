# ChromaDB Statistics

---
allowed-tools: mcp__chroma__*, Bash(du:*), Bash(ls:*)
description: Show ChromaDB statistics, collections, and usage metrics
---

## Your Task

Display comprehensive statistics about the current ChromaDB instance including collections, document counts, and storage usage.

### Statistics to Gather

1. **Connection Status**
   - Verify MCP server is accessible
   - Show configured data directory path
   - Confirm ChromaDB is responding

2. **Collection Overview**
   - List all collections
   - Show document count for each collection
   - Display collection metadata (if available)
   - Show embedding function used

3. **Storage Metrics**
   - Total disk space used by `.chroma/` directory
   - Size of `chroma.sqlite3` database file
   - Number of files in ChromaDB directory
   - Breakdown by collection (if possible)

4. **Collection Details** (for each collection)
   - Name
   - Document count
   - Sample metadata structure
   - Creation/modification time (from filesystem)

5. **Health Indicators**
   - Path status (local vs external volume)
   - Read/write permissions
   - Database integrity (file exists and is valid SQLite)
   - Recent activity (last modified timestamp)

### Output Format

```
## ChromaDB Statistics Report

**Data Directory**: /Users/username/project/.chroma
**Path Type**: ✅ Local | ⚠️ External Volume
**Database Size**: 1.2 MB
**Total Collections**: 2

### Collections

1. **project_memory**
   - Documents: 120
   - Metadata: {type, tags, source}
   - Last Modified: 2025-10-14 13:39
   - Size: ~800 KB

2. **chromadb_memory**
   - Documents: 45
   - Metadata: {type, tags, source}
   - Last Modified: 2025-10-13 10:22
   - Size: ~400 KB

### Storage Breakdown

| Component          | Size    | Files |
|--------------------|---------|-------|
| chroma.sqlite3     | 638 KB  | 1     |
| Collection vectors | 562 KB  | 8     |
| Metadata cache     | 45 KB   | 3     |
| **Total**          | 1.2 MB  | 12    |

### Health Check

✅ Database accessible
✅ All collections valid
✅ Proper permissions
✅ Local path (recommended)
⚠️ [Any warnings if applicable]

### Recommendations

- Consider archiving old collections if > 10 exist
- Backup .chroma/ directory regularly for persistence
- Monitor disk usage if collections grow large
```

### Advanced Queries (if time permits)

- Most recent documents per collection
- Collection growth over time (if tracking data available)
- Memory usage efficiency (documents per MB)

### Success Criteria

✅ Complete statistics report generated
✅ All collections enumerated with counts
✅ Storage metrics calculated
✅ Health status assessed
✅ Clear, formatted output
