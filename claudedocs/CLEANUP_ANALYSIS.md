# Project Cleanup Analysis

## Current Directory Analysis

### Plugin Core Files (KEEP - Core functionality)
```
.claude-plugin/plugin.json          Plugin metadata
commands/setup.md                   /chroma:setup command
commands/validate.md                /chroma:validate command
commands/migrate.md                 /chroma:migrate command
commands/stats.md                   /chroma:stats command
hooks/hooks.json                    Hook configuration
hooks/validate-chroma-path.py       Pre-tool validation hook
bin/chroma-stats.py                 Stats utility script
```

### Plugin Documentation (KEEP - Essential docs)
```
PLUGIN_README.md                    Main plugin documentation
PLUGIN_STRUCTURE.md                 Structure validation doc
README.plugin.md                    Additional plugin readme
CLAUDE.md                          Project contract
LICENSE                            License file
THIRD_PARTY_NOTICES.md             Third-party notices
CHANGELOG.md                       Change history
```

### Installer Files (MOVE TO ARCHIVE - Separate repo concern)
```
setup-claude-chroma.command        One-click installer (879KB)
claude-chroma.sh                   Installer script
start-claude-chroma.sh             Startup script
bin/rebuild-installer.sh           Installer build script
bin/fix-paths.sh                   Path fix utility
test_empty_file_fix.sh             Installer test
old-installers/                    Old installer versions
templates/                         Installer templates
```

### Development Documentation (KEEP - Claude working docs)
```
claudedocs/                        Claude Code workspace docs
  - SETUP_SCRIPT_ANALYSIS.md
  - INIT_INSTRUCTIONS.md
  - README.md
  - TEST_PLAN.md
  - CLAUDE_CODEX_PROMPT_CORRECTED.md
  - FINAL_COMPARISON_REPORT.md
```

### Project Documentation (REORGANIZE)
```
docs/                              General documentation
  - development/
  - releases/
  - audits/
  - guides/
README.md                          Main readme (needs update)
QUICKSTART.md                      Quickstart guide
```

### Configuration Files (KEEP - Essential)
```
.mcp.json                          Working MCP config
.mcp.json.template                 Template for users
.gitignore                         Git ignore rules
.gitignore.plugin                  Plugin-specific ignores
.github/workflows/                 GitHub Actions (if exists)
```

### Development/Test Files (REVIEW - May remove)
```
.chroma/                           Local ChromaDB instance
.claude/                           Local Claude settings
test-home/                         Test directory
ChatGPT-5-Audit-Prompt.md          Audit prompt
patches-archive.tar.gz             Old patches
MEMORY_CHECKPOINT_REMINDER.md      Checkpoint reminder
```

### Backup Files (DELETE - Cruft)
```
.mcp.json.backup.*                 5 backup files
.claude/settings.local.json.backup.* Multiple backups
.gitignore.backup.*                Backup gitignore
CLAUDE.md.backup.*                 Backup CLAUDE.md
CLAUDE.md.original                 Original CLAUDE.md
```

### System Files (KEEP)
```
.git/                              Git repository
.DS_Store                          macOS metadata (gitignore)
```

## Categorization Summary

### 🟢 KEEP (Plugin Core)
- `.claude-plugin/`
- `commands/`
- `hooks/`
- `bin/chroma-stats.py`
- Core documentation files

### 🟡 KEEP (Documentation)
- `claudedocs/` (Claude workspace)
- `docs/` (restructure)
- Essential READMEs
- LICENSE, CHANGELOG

### 🔵 ARCHIVE (Installer - Separate Repo)
- `setup-claude-chroma.command`
- `claude-chroma.sh`
- `start-claude-chroma.sh`
- `bin/rebuild-installer.sh`
- `bin/fix-paths.sh`
- `test_empty_file_fix.sh`
- `old-installers/`
- `templates/`
- `patches-archive.tar.gz`

### 🔴 DELETE (Cruft/Temporary)
- All `.backup.*` files (10+ files)
- `.DS_Store` (add to gitignore)
- `CLAUDE.md.original`
- `test-home/` (if not needed)
- `ChatGPT-5-Audit-Prompt.md` (move to docs if keep)
- `MEMORY_CHECKPOINT_REMINDER.md` (obsolete)

## Proposed Structure

```
claude-chroma/                     # Plugin Repository
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── setup.md
│   ├── validate.md
│   ├── migrate.md
│   └── stats.md
├── hooks/
│   ├── hooks.json
│   └── validate-chroma-path.py
├── bin/
│   └── chroma-stats.py
├── docs/
│   ├── guides/
│   ├── development/
│   └── releases/
├── claudedocs/                    # Claude Code workspace docs
├── examples/
│   ├── .mcp.json.example
│   └── sample-project/
├── README.md                      # Main plugin README
├── CLAUDE.md                      # Project contract
├── CHANGELOG.md
├── LICENSE
├── THIRD_PARTY_NOTICES.md
└── .gitignore

# Separate Repository: claude-chroma-setup
setup-claude-chroma.command
claude-chroma.sh
templates/
docs/installer/
```

## Cleanup Actions

### Phase 1: Archive Installer Files
1. Create `archive/installer/` directory
2. Move all installer-related files
3. Update README with pointer to claude-chroma-setup repo

### Phase 2: Remove Cruft
1. Delete all `.backup.*` files
2. Remove obsolete temporary files
3. Clean up test directories if not needed

### Phase 3: Reorganize Documentation
1. Consolidate plugin docs to README.md
2. Move development docs to docs/
3. Create clear examples/ directory

### Phase 4: Update Configuration
1. Update .gitignore for plugin focus
2. Create .mcp.json.example from .mcp.json.template
3. Clean up root directory clutter

### Phase 5: Documentation
1. Create STRUCTURE.md explaining organization
2. Update README.md for plugin-only focus
3. Add CONTRIBUTING.md if needed
