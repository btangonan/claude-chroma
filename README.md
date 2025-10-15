# Claude Chroma Plugin

**ChromaDB MCP server management plugin with path validation, migration utilities, and best practices enforcement for persistent AI memory.**

## Overview

Claude Chroma helps you set up and manage ChromaDB MCP servers in your Claude Code projects with:
- ✅ **Automated Setup**: Quick ChromaDB MCP configuration for any project
- 🔍 **Path Validation**: Detect and prevent path issues from external volumes
- 🚚 **Data Migration**: Safely move ChromaDB data from external drives to local storage
- 📊 **Statistics Dashboard**: Monitor collections, document counts, and storage usage
- 🛡️ **Pre-Tool Hooks**: Automatic path validation before ChromaDB operations

## Installation

**One command. That's it.**

```bash
/plugin marketplace add btangonan/claude-chroma-marketplace
/plugin install claude-chroma@claude-chroma-marketplace
```

**Done!** ChromaDB is automatically configured when you start Claude Code.

The plugin automatically:
- ✅ Creates `.chroma/` directory in your project root
- ✅ Configures `.mcp.json` with ChromaDB MCP server
- ✅ Sets up optimal configuration for persistent memory

**No manual setup required.** Just install and start using the commands below.

## Quick Start

### View Statistics

See your collections and storage usage:

```bash
/chroma:stats
```

### Validate Configuration

Check if your ChromaDB paths and configuration are healthy:

```bash
/chroma:validate
```

### Migrate from External Volumes

Move ChromaDB data from external drives to local storage:

```bash
/chroma:migrate
```

## Commands

### `/chroma:setup`
**Set up ChromaDB MCP server for the current project**

Automatically configures ChromaDB MCP integration with:
- Project-local `.chroma/` data directory
- Optimized MCP server settings
- Connection validation

**Usage:**
```bash
/chroma:setup
```

---

### `/chroma:validate`
**Validate ChromaDB paths and configuration**

Performs comprehensive validation:
- ✅ Checks if `.mcp.json` exists and is valid
- ✅ Verifies data directory path is accessible
- ⚠️ Warns about external volume risks
- ✅ Tests MCP connection
- ✅ Provides actionable recommendations

**Usage:**
```bash
/chroma:validate
```

**Output Example:**
```
## ChromaDB Validation Report

**MCP Config**: ✅ Found at .mcp.json
**Data Directory**: /Users/you/project/.chroma
**Path Status**: ✅ Local
**Permissions**: ✅ Read/Write
**Connection Test**: ✅ Connected
**Collections Found**: 2 (project_memory, chromadb_memory)

### Recommendations
✅ Configuration is healthy
```

---

### `/chroma:migrate`
**Migrate ChromaDB data from external volumes to local storage**

Safely migrates your ChromaDB data from external drives (like `/Volumes/*`) to project-local storage to prevent path breakage.

**Usage:**
```bash
/chroma:migrate
```

**What it does:**
1. Backs up current `.mcp.json`
2. Copies all data from external volume to local `.chroma/`
3. Updates MCP configuration to use local path
4. Verifies all collections migrated successfully
5. Provides cleanup options

**Safety Features:**
- Never deletes source data automatically
- Creates configuration backups
- Validates migration success before any cleanup
- Uses `rsync` for resumable, safe copies

---

### `/chroma:stats`
**Show ChromaDB statistics and collection info**

Displays comprehensive statistics about your ChromaDB instance:
- 📊 Collection counts and document totals
- 💾 Storage usage and file breakdown
- 🏥 Health indicators and path status
- 📈 Per-collection metrics

**Usage:**
```bash
/chroma:stats
```

**Output Example:**
```
## ChromaDB Statistics Report

**Data Directory**: /Users/you/project/.chroma
**Path Type**: ✅ Local
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
```

## How It Works

### Path Management Strategy

**Recommended:** Project-local `.chroma/` directory
- ✅ Survives project moves
- ✅ No external dependencies
- ✅ Fast access
- ✅ Easy to backup

**Not Recommended:** External volumes (`/Volumes/*`)
- ❌ Breaks when volume unmounts
- ❌ Slower access
- ❌ Path dependencies

### Pre-Tool Validation Hook

The plugin includes a Python hook that runs before every ChromaDB MCP operation to:
1. Check if data directory exists
2. Verify read/write permissions
3. Warn about external volume paths
4. Block operations if path is invalid

This prevents cryptic MCP errors and provides clear guidance.

### Migration Process

When you run `/chroma:migrate`, the plugin:
1. Identifies source (current path) and target (`.chroma/`)
2. Validates source has valid ChromaDB data
3. Backs up `.mcp.json` configuration
4. Uses `rsync` to safely copy all data
5. Updates `.mcp.json` to point to new path
6. Tests connection and verifies collections
7. Provides cleanup recommendations

## Best Practices

### 1. Use Project-Local Paths
Always store ChromaDB data in your project root (`.chroma/`), not on external volumes.

### 2. Add to .gitignore
Your `.chroma/` directory should NOT be committed to git:

```gitignore
# ChromaDB data
.chroma/
*.sqlite3
```

### 3. Regular Backups
Backup your `.chroma/` directory if you need persistence across machines:

```bash
# Backup
tar -czf chroma-backup-$(date +%Y%m%d).tar.gz .chroma/

# Restore
tar -xzf chroma-backup-20251014.tar.gz
```

### 4. Collection Naming
Use descriptive, project-specific collection names:
- ✅ `project_name_memory`
- ✅ `feature_context`
- ❌ `memory` (too generic)
- ❌ `collection1` (not descriptive)

### 5. Regular Validation
Run `/chroma:validate` periodically, especially:
- After moving projects
- After system updates
- When MCP connection fails
- Before important work sessions

## Troubleshooting

### MCP Connection Failed

**Symptom:** ChromaDB MCP operations fail or timeout

**Solution:**
```bash
# 1. Validate configuration
/chroma:validate

# 2. Check MCP server status
/mcp

# 3. Restart Claude Code if needed
```

### Path Not Found

**Symptom:** "ChromaDB path does not exist" error

**Solution:**
```bash
# Run setup to create proper structure
/chroma:setup
```

### External Volume Warning

**Symptom:** "ChromaDB is on external volume" warning

**Solution:**
```bash
# Migrate to local storage
/chroma:migrate
```

### Permission Denied

**Symptom:** "ChromaDB path is not accessible" error

**Solution:**
```bash
# Check permissions
ls -la .chroma/

# Fix permissions if needed
chmod 755 .chroma/
chmod 644 .chroma/chroma.sqlite3
```

## Technical Details

### Plugin Structure

```
claude-chroma/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   ├── setup.md            # /chroma:setup command
│   ├── validate.md         # /chroma:validate command
│   ├── migrate.md          # /chroma:migrate command
│   └── stats.md            # /chroma:stats command
├── hooks/
│   ├── hooks.json          # Hook configuration
│   └── validate-chroma-path.py  # Pre-tool validation hook
└── README.md
```

### MCP Configuration Format

The plugin creates/updates `.mcp.json` with this structure:

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

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/bradleytangonan/claude-chroma/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/bradleytangonan/claude-chroma/discussions)
- 📖 **Documentation**: [Wiki](https://github.com/bradleytangonan/claude-chroma/wiki)

## Acknowledgments

Built with:
- [ChromaDB](https://www.trychroma.com/) - Vector database for AI embeddings
- [Claude Code](https://claude.com/claude-code) - Agentic terminal tool
- [MCP](https://modelcontextprotocol.io/) - Model Context Protocol

---

**Made with ❤️ for the Claude Code community**
