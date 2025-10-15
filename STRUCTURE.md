# Claude Chroma Plugin - Project Structure

**Last Updated**: 2025-10-14
**Status**: Plugin-focused development, installer archived

## Overview

This repository contains the Claude Chroma plugin for Claude Code. The one-click installer has been moved to a separate repository: [claude-chroma-setup](https://github.com/btangonan/claude-chroma-setup)

## Purpose Separation

### This Repository (Plugin)
**Focus**: Claude Code plugin development and distribution
**Users**: Developers who install via `/plugin install`
**Distribution**: Claude Code marketplace and GitHub

### Separate Repository (Installer)
**Focus**: One-click setup script for non-technical users
**Users**: End-users who want automated setup
**Distribution**: Standalone downloadable installer

## Directory Structure

```
claude-chroma/                          # Plugin Repository
├── .claude-plugin/                     # Plugin Metadata
│   └── plugin.json                     # Plugin manifest (name, version, description)
│
├── commands/                           # Plugin Commands
│   ├── setup.md                        # /chroma:setup - MCP configuration
│   ├── validate.md                     # /chroma:validate - Path validation
│   ├── migrate.md                      # /chroma:migrate - Data migration
│   └── stats.md                        # /chroma:stats - Collection statistics
│
├── hooks/                              # Plugin Hooks
│   ├── hooks.json                      # Hook configuration
│   └── validate-chroma-path.py         # PreToolUse validation hook
│
├── bin/                                # Utility Scripts
│   ├── chroma-stats.py                 # Stats utility (used by stats.md)
│   └── registry.sh                     # Registry management (if needed)
│
├── docs/                               # Documentation
│   ├── guides/                         # User guides
│   │   └── QUICKSTART.md               # Quick start guide
│   ├── development/                    # Development docs
│   │   └── PATH_MIGRATION.md           # Path migration guide
│   ├── releases/                       # Release notes
│   └── audits/                         # Security audits
│
├── examples/                           # Example Configurations
│   ├── .mcp.json.example               # Example MCP configuration
│   └── sample-project/                 # Sample project structure
│
├── claudedocs/                         # Claude Code Workspace Docs
│   ├── README.md                       # Workspace overview
│   ├── CLEANUP_ANALYSIS.md             # This cleanup analysis
│   └── *.md                            # Other Claude working docs
│
├── archive/                            # Archived Files (gitignored)
│   ├── installer/                      # Moved to claude-chroma-setup repo
│   │   ├── setup-claude-chroma.command # One-click installer
│   │   ├── claude-chroma.sh            # Installer script
│   │   ├── templates/                  # Installer templates
│   │   └── old-installers/             # Historical versions
│   └── old-docs/                       # Deprecated documentation
│
├── PLUGIN_README.md                    # Main plugin documentation
├── PLUGIN_STRUCTURE.md                 # Plugin structure validation
├── README.md                           # Repository readme
├── CLAUDE.md                           # Claude Code project contract
├── CHANGELOG.md                        # Version history
├── LICENSE                             # MIT License
└── THIRD_PARTY_NOTICES.md              # Third-party attributions
```

## File Categories

### Plugin Core (Essential)
- `.claude-plugin/plugin.json` - Plugin metadata and configuration
- `commands/*.md` - Command implementations
- `hooks/hooks.json` - Hook configuration
- `hooks/validate-chroma-path.py` - Hook implementation

### Utilities
- `bin/chroma-stats.py` - Statistics utility script
- `bin/registry.sh` - Registry management (if applicable)

### Documentation
- `PLUGIN_README.md` - Primary plugin documentation
- `README.md` - Repository overview
- `docs/` - Organized documentation by category
- `CLAUDE.md` - Project contract for Claude Code sessions

### Configuration
- `.mcp.json` - Working MCP config (gitignored, user-specific)
- `examples/.mcp.json.example` - Template for users
- `.gitignore` - Plugin-focused ignore rules

### Development
- `claudedocs/` - Claude Code workspace documentation
- `.chroma/` - Local ChromaDB instance (gitignored)
- `.claude/` - Local Claude settings (gitignored)

### Archived (Not in Git)
- `archive/installer/` - Installer files moved to separate repo
- `archive/old-docs/` - Deprecated documentation

## Installation Paths

### Plugin Installation (This Repo)
Users install the plugin with:
```bash
/plugin install https://github.com/btangonan/claude-chroma
```

Or from Claude Code marketplace:
```bash
/plugin install claude-chroma
```

### Installer Installation (Separate Repo)
Users download the one-click installer:
```bash
curl -o setup-claude-chroma.command \
  https://raw.githubusercontent.com/btangonan/claude-chroma-setup/main/setup-claude-chroma.command
chmod +x setup-claude-chroma.command
./setup-claude-chroma.command
```

## Development Workflow

### Plugin Development
1. Clone this repository
2. Make changes to commands, hooks, or utilities
3. Test locally with `/plugin install /path/to/claude-chroma`
4. Update version in `.claude-plugin/plugin.json`
5. Update `CHANGELOG.md`
6. Commit and push to GitHub
7. Tag release: `git tag v1.x.x && git push --tags`

### Installer Development (Separate Repo)
1. Clone claude-chroma-setup repository
2. Modify installer scripts
3. Test with fresh installation
4. Update version in installer
5. Commit and push to separate repo

## Cross-References

### From Plugin to Installer
The plugin does NOT depend on the installer. Users can install the plugin directly without ever running the installer.

### From Installer to Plugin
The installer MAY optionally install the plugin by running:
```bash
/plugin install https://github.com/btangonan/claude-chroma
```

But the installer primarily focuses on:
- Installing ChromaDB Python package
- Configuring MCP server
- Setting up initial project structure

## Design Decisions

### Why Separate?
1. **Different Users**: Plugin users (developers) vs installer users (end-users)
2. **Different Lifecycles**: Plugin changes frequently, installer is stable
3. **Cleaner Repository**: Plugin repo focuses on plugin code, not installer complexity
4. **Easier Maintenance**: Changes to one don't affect the other
5. **Better Testing**: Can test plugin independently of installer

### What Stays Together?
- Commands and hooks stay with plugin (core functionality)
- Documentation stays with plugin (user-facing docs)
- Utilities stay with plugin if used by commands

### What Gets Separated?
- One-click installer script (separate repo)
- Installer templates (separate repo)
- Installer build scripts (separate repo)
- Installer tests (separate repo)

## Migration Notes

### For Existing Users
If you previously used the one-click installer, nothing changes. Your installation continues to work. The installer now lives at:
https://github.com/btangonan/claude-chroma-setup

### For Plugin Users
If you installed via `/plugin install`, nothing changes. You're already using the plugin-only installation path.

### For Developers
If you were developing on this repo, note that:
- Installer files moved to `archive/installer/`
- Archive directory is gitignored
- Focus is now on plugin development
- Installer development happens in separate repo

## Clean Workspace

### What's Not in Git
- `.chroma/` - Local ChromaDB instance
- `.claude/` - Local Claude settings
- `.mcp.json` - User-specific MCP configuration
- `archive/` - Archived installer files
- `*.backup.*` - Temporary backup files

### What's in Git
- Plugin core files (commands, hooks, utilities)
- Documentation
- Examples and templates
- Project configuration (CLAUDE.md, .gitignore, etc.)

## Questions?

- **Plugin Issues**: Report here in this repository
- **Installer Issues**: Report in claude-chroma-setup repository
- **General Questions**: Open discussion in either repository

## Related Repositories

- **Plugin**: https://github.com/btangonan/claude-chroma
- **Installer**: https://github.com/btangonan/claude-chroma-setup
- **ChromaDB**: https://github.com/chroma-core/chroma
- **Claude Code**: https://claude.ai/code
