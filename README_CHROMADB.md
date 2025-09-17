# ChromaDB for Claude - Persistent Project Memory

Give your Claude projects perfect memory that persists across sessions.

## What This Does

ChromaDB gives Claude a **permanent memory** for your project that:
- 📝 Remembers decisions, fixes, and patterns across sessions
- 🔄 Automatically logs important discoveries
- 🎯 Retrieves relevant context when needed
- 💾 Stores everything locally in your project

## Quick Start (2 minutes)

### First Time Setup
```bash
# Make the script executable (only needed once)
chmod +x chromadb_setup_fixed.sh
```

### For New Projects
```bash
# 1. Run Setup (creates new project folder)
./chromadb_setup_fixed.sh your-project-name

# 2. Start Claude with Memory
cd your-project-name
claude --mcp-config .claude/settings.local.json
```

### For Existing Projects
```bash
# 1. Go to your existing project
cd existing-project

# 2. Run setup (adds ChromaDB to current folder)
/path/to/chromadb_setup_fixed.sh
# When asked "Enter project name": just press ENTER

# 3. Start Claude with Memory
claude --mcp-config .claude/settings.local.json
```

**Note**: Pressing Enter for project name tells the script to use the current directory

### That's It!
Claude now has persistent memory for this project. It will automatically:
- Create the memory database on first run
- Log important decisions and fixes
- Remember context between sessions

## Requirements

- **Claude CLI** (installed from https://claude.ai/)
- **uvx** (installs automatically with: `curl -LsSf https://astral.sh/uv/install.sh | sh`)
- **macOS or Linux** (Windows users: use WSL)

## What Gets Created

```
your-project/
├── .claude/
│   └── settings.local.json    # ChromaDB configuration
├── .chroma/                    # Memory database (auto-created)
├── CLAUDE.md                   # Instructions for Claude
└── claudedocs/                 # Documentation
```

## How Memory Works

Claude automatically logs memories when you:
- ✅ Fix a bug → Remembers the solution
- 🔧 Make a configuration decision → Stores the choice
- ⚡ Discover a pattern → Saves for reuse
- 📦 Change architecture → Tracks the reasoning

Example memory:
```javascript
"Fixed: Use stdio not HTTP for MCP transport"
Tags: mcp,stdio,config
Source: setup.sh:45
```

## Testing It Works

After starting Claude, type:
```
mcp__chroma__chroma_list_collections
```

You should see: `["project_memory"]`

## Multiple Projects

Each project gets its own memory. Just run the setup script in each project directory:

```bash
# For new projects
./chromadb_setup_fixed.sh project-1
./chromadb_setup_fixed.sh project-2

# For existing projects
cd ~/projects/project-1
/path/to/chromadb_setup_fixed.sh

cd ~/projects/project-2
/path/to/chromadb_setup_fixed.sh
```

Note: Replace `your-project-name` with your actual project name (e.g., `todo-app`, `my-website`, `data-analysis`)

## Troubleshooting

### "ChromaDB not found"
Start Claude with the config flag:
```bash
claude --mcp-config .claude/settings.local.json
```

### "uvx not found"
Install uv first:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### "Permission denied"
Make the script executable:
```bash
chmod +x chromadb_setup_fixed.sh
```

## Advanced Usage

### Query memories manually
```javascript
mcp__chroma__chroma_query_documents {
  "collection": "project_memory",
  "query_texts": ["search term"],
  "n_results": 5
}
```

### Add custom memory
```javascript
mcp__chroma__chroma_add_documents {
  "collection": "project_memory",
  "documents": ["Decision: Use TypeScript for type safety"],
  "metadatas": [{"type": "decision", "tags": "typescript,setup"}],
  "ids": ["decision-001"]
}
```

## Privacy & Security

- ✅ **100% local** - No data leaves your machine
- ✅ **Project-isolated** - Each project has separate memory
- ✅ **In your control** - Database stored in `.chroma/` directory
- ✅ **Gitignore-ready** - Script adds `.chroma/` to gitignore

## How It's Different

**Without ChromaDB:**
- Claude forgets everything between sessions
- You repeat explanations
- Loses context of past decisions

**With ChromaDB:**
- Claude remembers your project's history
- Retrieves relevant past solutions
- Maintains context across weeks/months

## Support

This tool uses:
- [ChromaDB](https://www.trychroma.com/) - Vector database
- [MCP](https://modelcontextprotocol.io/) - Model Context Protocol
- [Claude CLI](https://claude.ai/) - Command-line interface

## License

MIT - Use freely in your projects

---

*Built to give Claude perfect memory. One setup, persistent context forever.*