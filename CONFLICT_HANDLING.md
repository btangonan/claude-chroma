# ChromaDB Setup - Conflict Handling

The script now intelligently handles existing files!

## When CLAUDE.md Already Exists

You'll see 3 options:
```
1) Backup existing and create new (recommended)
2) Append ChromaDB section to existing
3) Skip CLAUDE.md creation
```

- **Option 1**: Backs up your CLAUDE.md as `CLAUDE.md.backup.TIMESTAMP` and creates fresh ChromaDB version
- **Option 2**: Keeps your existing CLAUDE.md and adds ChromaDB section at the end
- **Option 3**: Leaves your CLAUDE.md untouched

## When settings.local.json Already Exists

### If ChromaDB already configured:
```
ChromaDB MCP server already configured in settings
Overwrite existing ChromaDB config? (y/n):
```
- **y**: Backs up and overwrites with fresh config
- **n**: Keeps your existing ChromaDB config

### If settings exist but no ChromaDB:
```
1) Merge ChromaDB into existing settings (recommended)
2) Backup and replace with new settings
```
- **Option 1**: Intelligently merges ChromaDB config into your existing settings (preserves other MCP servers, permissions, etc.)
- **Option 2**: Backs up entire settings and creates new one

## Backup Files

All backups are timestamped:
- `CLAUDE.md.backup.20250115_143022`
- `.claude/settings.local.json.backup.20250115_143022`

## Safe to Run Multiple Times

The script is idempotent - you can run it multiple times safely:
- Won't lose existing configurations
- Won't create duplicate entries
- Always offers choice on conflicts
- Creates timestamped backups

## Example Scenarios

### Scenario 1: Adding to project with existing CLAUDE.md
```bash
./chromadb_setup_fixed.sh
# Press ENTER for current directory
# Choose option 2 to append ChromaDB section
```

### Scenario 2: Project already has other MCP servers
```bash
./chromadb_setup_fixed.sh
# Press ENTER
# Choose option 1 to merge ChromaDB into existing settings
# Your other MCP servers remain intact
```

### Scenario 3: Re-running after ChromaDB already setup
```bash
./chromadb_setup_fixed.sh
# Press ENTER
# Choose 'n' to keep existing ChromaDB config
# Choose option 3 to skip CLAUDE.md
```

## Clean Solution

- **No data loss** - Always backs up before modifying
- **Preserves customizations** - Merges rather than overwrites
- **User control** - Always asks before changing existing files
- **Professional** - Handles edge cases gracefully