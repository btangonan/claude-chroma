# Claude Chroma v3.5.4 - One-Click Installer Release

We're excited to announce the release of the **Claude Chroma One-Click Installer** alongside our existing plugin! Now you have **two ways to install** ChromaDB MCP support for Claude Code.

## 🎉 What's New

### One-Click Installer

Perfect for beginners and quick project setup! Just download and double-click to configure ChromaDB in any project.

**Download:** [`setup-claude-chroma.command`](https://github.com/btangonan/claude-chroma/releases/latest/download/setup-claude-chroma.command)

### Key Features

✅ **Zero Dependencies** - Self-bootstraps jq and handles Python fallbacks automatically
✅ **Works Offline** - All assets embedded in the installer (941KB)
✅ **Preserves Your Work** - Intelligently merges with existing CLAUDE.md
✅ **User-Friendly** - Colorful output with clear progress indicators
✅ **Creates Launcher** - Generates `launch-claude-here.command` for easy project access
✅ **Self-Testing** - Run `./setup-claude-chroma.command --self-test-offline` to verify integrity

## 📦 Installation Methods Comparison

| Feature | One-Click Installer | Plugin |
|---------|-------------------|--------|
| **Setup Steps** | Download + Double-click | Two commands |
| **Dependencies** | None (self-bootstraps) | Python 3 required |
| **Updates** | Re-download file | `/plugin update` |
| **Auto-activation** | Manual per project | Automatic on startup |
| **Management Tools** | Basic setup only | Full suite (`/chroma:*`) |
| **Best For** | Quick setup, single projects | Multiple projects, power users |

## 🚀 Quick Start

### Using One-Click Installer

```bash
# 1. Download the installer to your project directory
cd ~/myproject

# 2. Make it executable (if needed)
chmod +x setup-claude-chroma.command

# 3. Run it (or just double-click in Finder)
./setup-claude-chroma.command
```

The installer will:
1. Auto-detect and bootstrap any missing dependencies (jq, python3)
2. Create `.chroma/` directory for persistent memory storage
3. Generate `.mcp.json` with optimized ChromaDB configuration
4. Create or merge `CLAUDE.md` with ChromaDB instructions
5. Create a launcher script for easy Claude access

### Using Plugin (Alternative)

```bash
/plugin marketplace add btangonan/claude-chroma-marketplace
/plugin install claude-chroma@claude-chroma-marketplace
```

## 🔧 Advanced Features

### Self-Test Mode
Verify the installer's embedded assets work correctly:
```bash
./setup-claude-chroma.command --self-test-offline
```

### Uninstall Bootstrap Components
Remove any bootstrapped binaries (jq, etc.):
```bash
./setup-claude-chroma.command --uninstall
```

## 📚 What Gets Configured

Both installation methods create the same ChromaDB setup:

- **`.chroma/`** - Local data directory for vector embeddings and metadata
- **`.mcp.json`** - MCP server configuration with optimized timeout settings
- **`CLAUDE.md`** - Project-specific memory instructions and usage guidelines
- **`launch-claude-here.command`** - (One-click only) Convenient launcher script

## 🔄 Upgrading from Previous Versions

### From Old One-Click Installers
Simply download the new version and run it in your project directory. It will:
- Preserve all existing data in `.chroma/`
- Update configuration files safely with automatic backups
- Merge any new instructions into existing `CLAUDE.md`

### From Plugin
No changes needed! Continue using the plugin as normal. The one-click installer is an additional option, not a replacement.

## 🛡️ Safety Features

- **Automatic Backups** - Creates timestamped backups before modifying files
- **Idempotent** - Safe to run multiple times without duplicating configuration
- **Non-Destructive** - Preserves existing content when merging CLAUDE.md
- **Offline Capable** - All dependencies embedded, no network required
- **Validated Paths** - Input sanitization prevents command injection

## 📖 Documentation

- **README**: Full installation guide and comparison table
- **Wiki**: Best practices and troubleshooting
- **Issues**: Report bugs or request features

## 🙏 Acknowledgments

Thanks to the Claude Code community for feedback and testing! This release addresses requests for:
- Simpler installation without plugin system knowledge
- Offline installation capability
- Self-contained, portable setup script

---

**Choose your installation method:** [One-Click Installer](https://github.com/btangonan/claude-chroma/releases/latest) | [Plugin Installation](https://github.com/btangonan/claude-chroma#installation)

Built with ❤️ for the Claude Code community
