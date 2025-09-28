# v3.5.3: Template Externalization & Production Polish

## 🎯 Highlights

This release delivers **lean-by-default** setup with externalized templates, comprehensive CI hardening, and production-ready polish across all components.

## 📦 What's New

### Template Externalization
- **CLAUDE.md** now rendered from `templates/CLAUDE.md.tpl` via `envsubst`
- Template parameterization with `${PROJECT_COLLECTION}` variable
- Auto-seeding of minimal template if missing
- Preservation of existing CLAUDE.md as `.original` during upgrades

### Lean-by-Default Setup
- Shell function installer gated behind `--full` flag
- Default: `MINIMAL=1`, `FULL=0` for lightweight installations
- Reduced shell environment pollution in standard mode
- Opt-in for advanced features

### CI Hardening
- **macOS matrix testing** alongside Ubuntu for cross-platform validation
- **ShellCheck exclusions** for false positives (SC2034, SC2120, SC2119)
- **Side-effect-free** `--print-collection` mode with exact match assertions
- **uvx PATH verification** guard for resilient Python environment detection
- **Dry-run path safety** handling for non-existent directories

### Production Polish
- Improved `.gitignore` clarity with explicit MCP tracking guidance
- **CHROMA_MCP_VERSION** override support for version flexibility
- Template absence path handling with graceful fallback
- Enhanced error messages and user guidance

## 🔧 Breaking Changes

None. All changes are backward compatible.

## 📋 Upgrade Instructions

For existing installations:

```bash
# Your existing CLAUDE.md will be preserved as CLAUDE.md.original
./claude-chroma.sh your-project /path/to/project
```

For new installations:

```bash
# Lean mode (default)
./claude-chroma.sh project-name /path/to/project

# Full mode with shell functions
./claude-chroma.sh --full project-name /path/to/project
```

## 🧪 Testing

All changes validated across:
- ✅ Ubuntu 22.04 (GitHub Actions)
- ✅ macOS latest (GitHub Actions)
- ✅ Local ShellCheck validation
- ✅ Dry-run mode testing
- ✅ Template absence scenarios

## 📝 Documentation

See [UPGRADE_v3.5.3.md](UPGRADE_v3.5.3.md) for detailed upgrade notes.

## 🙏 Acknowledgments

Thanks to all users for feedback that shaped these production improvements!

---

**Full Changelog**: [v3.5.2...v3.5.3](https://github.com/btangonan/claude-chroma/compare/v3.5.2...v3.5.3)