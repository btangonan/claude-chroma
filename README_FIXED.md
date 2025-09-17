# 🧠 ChromaDB Setup for Claude - Simplified Edition

A streamlined script that sets up persistent memory for Claude projects using ChromaDB. No Python dependencies, no manual initialization - just run and go.

## ✨ What's Different in v3.0?

- **No Python packages required** - Uses MCP server (uvx) exclusively
- **Auto-initialization** - Claude creates collections automatically
- **Zero manual steps** - Run script, start Claude, done
- **Simplified structure** - Only essential files created
- **macOS compatible** - Works with system Python restrictions

## 📋 Prerequisites

Only two requirements:
1. **uvx** - Install from [https://docs.astral.sh/uv/](https://docs.astral.sh/uv/)
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Claude CLI** - Install from [https://claude.ai/download](https://claude.ai/download)

## 🚀 Quick Start

### One-Time Setup
```bash
# Run the setup script
./chromadb_setup_fixed.sh "my-project"

# Navigate to your project
cd "my-project"

# Start Claude
claude chat
```

That's it! Claude will automatically:
- Detect if ChromaDB is initialized
- Create the collection if needed
- Start logging memories

## 🏗️ What Gets Created

```
your-project/
├── .chroma/                     # ChromaDB database (auto-managed)
├── .claude/
│   └── settings.local.json      # MCP server configuration
├── claudedocs/
│   └── INIT_INSTRUCTIONS.md     # Manual commands reference
├── CLAUDE.md                    # Auto-initialization instructions
└── .gitignore                   # Excludes .chroma database
```

## 🤖 How Auto-Initialization Works

When Claude starts in your project:

1. **Reads CLAUDE.md** which contains initialization instructions
2. **Checks if collection exists** by attempting a query
3. **Creates collection** if the query fails
4. **Logs initial memory** to confirm setup
5. **Starts working** with persistent memory

No manual commands needed!

## 💾 Memory Schema

```javascript
{
  "documents": ["Brief description <300 chars"],
  "metadatas": [{
    "type": "decision|fix|tip|pattern",
    "tags": ["tag1", "tag2"],
    "source": "file:line",
    "confidence": 0.8,  // 0.3=hypothesis, 1.0=proven
    "timestamp": "2024-01-15T10:30:00Z"
  }],
  "ids": ["type-component-20240115-001"]
}
```

## 🎯 Automatic Memory Logging

Claude automatically logs memories when:
- ✅ Bug is fixed
- 🔧 Configuration changes
- ⚡ Performance improves
- 🏗️ Architecture decisions made
- 📦 Dependencies change

## 🔍 Manual Operations (Optional)

If you need to manually interact with ChromaDB:

### Query Memories
```javascript
mcp__chroma__chroma_query_documents {
  "collection": "project_memory",
  "query_texts": ["search", "terms"],
  "n_results": 10
}
```

### Add Memory
```javascript
mcp__chroma__chroma_add_documents {
  "collection": "project_memory",
  "documents": ["Memory text"],
  "metadatas": [{"type": "tip", "tags": ["useful"], "confidence": 0.8}],
  "ids": ["tip-001"]
}
```

## 🔧 Troubleshooting

### "uvx not found"
Install uv first:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### "ChromaDB MCP server test failed"
Update the MCP server:
```bash
uvx --refresh chroma-mcp
```

### Collection not creating automatically
1. Make sure you're in the project directory
2. Check that CLAUDE.md exists
3. Try manual creation (see INIT_INSTRUCTIONS.md)

## 🎉 Key Benefits

1. **Zero Dependencies** - No Python packages to install
2. **Automatic Setup** - Claude handles initialization
3. **Persistent Memory** - Knowledge survives across sessions
4. **Project Isolation** - Each project has its own memory
5. **macOS Friendly** - Works with system Python restrictions

## 📝 Example Workflow

```bash
# Create new project
./chromadb_setup_fixed.sh "xml-processor"
cd "xml-processor"

# Start Claude
claude chat

# Claude automatically:
# - Creates ChromaDB collection
# - Logs "Project initialized" memory
# - Starts tracking decisions

# Work on your project...
# Claude logs memories automatically

# Next session
claude chat
# Claude loads existing memories and continues
```

## 🤝 Differences from v2.0

| Feature | v2.0 (Complex) | v3.0 (Simple) |
|---------|---------------|--------------|
| Python ChromaDB | Required | Not needed |
| Manual init | Run init_chroma.sh | Automatic |
| Utility scripts | Many .sh files | None needed |
| Collections | 4 collections | 1 collection |
| Setup complexity | ~800 lines | ~200 lines |

## 📜 License

Free to use for enhancing Claude's capabilities with persistent memory.