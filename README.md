# Claude Chroma

**Easy ChromaDB MCP setup for Claude Code with two installation options: one-click installer or modular plugin. Includes path validation, migration utilities, and best practices enforcement for persistent AI memory.**

## Overview

Claude Chroma helps you set up and manage ChromaDB MCP servers in your Claude Code projects with:
- ✅ **Automated Setup**: Quick ChromaDB MCP configuration for any project
- 🔍 **Path Validation**: Detect and prevent path issues from external volumes
- 🚚 **Data Migration**: Safely move ChromaDB data from external drives to local storage
- 📊 **Statistics Dashboard**: Monitor collections, document counts, and storage usage
- 🛡️ **Pre-Tool Hooks**: Automatic path validation before ChromaDB operations

## Requirements

**Python 3 is required** for this plugin to function correctly.

The plugin uses Python for reliable JSON configuration merging and path management. This ensures:
- ✅ Safe merging of `.mcp.json` and `settings.local.json` without data loss
- ✅ Accurate path updates when projects are moved
- ✅ Reliable configuration validation

**Installation:**
- **macOS**: Python 3 is pre-installed on recent versions
- **Linux**: `sudo apt install python3` (Ubuntu/Debian) or equivalent
- **Windows**: Download from [python.org/downloads](https://www.python.org/downloads/)

If Python is not available, the plugin will display a clear error message with installation instructions.

## Installation

Choose the method that works best for you:

### 🚀 Option 1: One-Click Installer (Easiest)

**Perfect for beginners or quick setup.** Just download and double-click!

1. **Download** [`setup-claude-chroma.command`](https://github.com/btangonan/claude-chroma/releases/latest/download/setup-claude-chroma.command)
2. **Double-click** the file in your project directory
3. **Done!** ChromaDB is configured automatically

**Features:**
- ✅ Zero dependencies (self-bootstraps everything)
- ✅ Works offline (embedded assets)
- ✅ Colorful, friendly output
- ✅ Creates launcher script for easy access
- ✅ Preserves existing CLAUDE.md
- ✅ Perfect for one-off projects

### 🔌 Option 2: Plugin (Recommended for Power Users)

**Best for developers who manage multiple projects.** Easy updates and modular design.

```bash
/plugin marketplace add btangonan/claude-chroma-marketplace
/plugin install claude-chroma@claude-chroma-marketplace
```

**Repository:** [https://github.com/btangonan/claude-chroma](https://github.com/btangonan/claude-chroma)

**Features:**
- ✅ Easy updates with `/plugin update`
- ✅ Auto-runs on project start
- ✅ Additional management commands
- ✅ Path validation hooks
- ✅ Migration utilities
- ✅ Statistics dashboard

### Comparison

| Feature | One-Click Installer | Plugin |
|---------|-------------------|--------|
| **Setup Steps** | Download + Double-click | Two commands |
| **Dependencies** | None (self-bootstraps) | Python 3 required |
| **Updates** | Re-download file | `/plugin update` |
| **Auto-activation** | Manual per project | Automatic on startup |
| **Management Tools** | Basic | Full suite (`/chroma:*`) |
| **Best For** | Quick setup, beginners | Multiple projects, power users |

---

**Both methods create the same ChromaDB configuration.** Choose based on your workflow!

The plugin automatically:
- ✅ Creates `.chroma/` directory in your project root
- ✅ Configures `.mcp.json` with ChromaDB MCP server
- ✅ Adds `enabledMcpjsonServers` to `.claude/settings.local.json` (activates MCP)
- ✅ Creates or merges `CLAUDE.md` with ChromaDB instructions
- ✅ **Non-destructive merge**: Preserves existing project files with automatic backups
- ✅ **Idempotent**: Safe to run multiple times without duplication
- ✅ **Project portability**: Auto-updates paths when you move project folders

**No manual setup required.** Just install and start using the commands below.

> **Note:** Plugin-specific features below apply to Option 2 (Plugin). The one-click installer creates the same ChromaDB setup but without the additional management commands.

### Works with Existing Projects

The plugin intelligently handles all project states:
- ✅ **Fresh projects**: Creates all files from templates
- ✅ **Existing CLAUDE.md**: Appends ChromaDB section (preserves your content)
- ✅ **Existing settings.local.json**: Merges ChromaDB config (preserves existing servers)
- ✅ **Already configured**: Silent exit, no modifications
- ✅ **Moved projects**: Auto-detects and updates paths when you move folders

**Automatic backups created before any modifications** (timestamped `.backup` files)

### Project Portability

**Move projects freely** - the plugin automatically detects and fixes path changes:

```bash
# Move your project
mv ~/Desktop/myproject ~/Documents/myproject

# Open in Claude Code - paths auto-update!
cd ~/Documents/myproject
claude  # SessionStart hook detects change and updates .mcp.json
```

The plugin:
- Detects when project folder path has changed
- Updates `.mcp.json` to point to new location
- Creates backup before modification
- Respects custom paths (only updates project-relative paths)

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

### Python 3 Not Found

**Symptom:** "Python 3 is required for Claude Chroma plugin" error on startup

**Cause:** Python 3 is not installed or not in system PATH

**Solution:**
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3

# Windows
# Download from https://www.python.org/downloads/
# Make sure to check "Add Python to PATH" during installation

# Verify installation
python3 --version
```

After installing Python, restart Claude Code.

**Alternative:** If you cannot install Python, you can manually configure ChromaDB:
1. Create `.chroma/` directory in your project root
2. Copy `.mcp.json` template from plugin repository
3. Update the `--data-dir` path to match your project location
4. Manually add ChromaDB configuration to `.claude/settings.local.json`

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
