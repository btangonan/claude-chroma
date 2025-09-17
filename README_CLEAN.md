# ChromaDB for Claude - Persistent Memory

Give your Claude projects perfect memory across sessions.

## Quick Start

### Install Prerequisites
```bash
# Install uvx (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Setup ChromaDB

**New Project:**
```bash
chmod +x chromadb_setup_fixed.sh
./chromadb_setup_fixed.sh my-project
cd my-project
claude --mcp-config .claude/settings.local.json
```

**Existing Project:**
```bash
cd your-project
/path/to/chromadb_setup_fixed.sh
# Press ENTER when asked for project name
# Optionally add global shell function when prompted
claude-chroma          # If you added the shell function
# OR: claude --mcp-config .claude/settings.local.json
```

## What It Does

- 📝 **Remembers Everything** - Decisions, fixes, patterns persist across sessions
- 🔄 **Auto-logs** - Automatically captures important discoveries
- 💾 **100% Local** - Your data never leaves your machine
- 🎯 **Project-Isolated** - Each project has its own memory

## Test It Works

In Claude, type:
```
mcp__chroma__chroma_list_collections
```
You should see: `["project_memory"]`

## How Memory Works

Claude automatically logs when you:
- Fix a bug → Remembers the solution
- Make a decision → Stores the reasoning
- Discover a pattern → Saves for reuse

## Smart Shell Function (Optional)

During setup, you can add a global `claude-chroma` function:

✅ **Works from any directory** in your project tree
✅ **Auto-detects** ChromaDB config files
✅ **Falls back** to regular Claude if no config found
✅ **Passes through** all Claude arguments

```bash
# Use anywhere in your project
claude-chroma chat
claude-chroma --help
```

## Multiple Projects

Each project gets its own memory:
```bash
./chromadb_setup_fixed.sh project-1
./chromadb_setup_fixed.sh project-2
```

## What Gets Created

```
your-project/
├── .claude/settings.local.json  # ChromaDB config
├── .chroma/                      # Memory database
└── CLAUDE.md                     # Auto-instructions
```

---

*One setup, persistent memory forever.*