# 🚀 Claude-Chroma Quick Start Guide

Get Claude with persistent memory in under 60 seconds!

## What is Claude-Chroma?

Claude-Chroma gives Claude Desktop **persistent memory** for your projects. Claude will remember:
- Your project decisions and preferences
- Bugs you've fixed and solutions you've found
- Architecture choices and coding patterns
- Context from previous conversations

## Installation Options

### Option 1: One-Click Install (Easiest! 🎯)

**For macOS users:**

1. **Download the installer:**
   - Get `setup-claude-chroma-oneclick-fixed.command` from this repository

2. **Double-click to install:**
   - The installer opens in Terminal
   - Enter your project name when prompted
   - Wait for "Setup Complete!" message

3. **Start Claude with memory:**
   - Double-click the created `launch-claude-here.command` file
   - Claude opens with ChromaDB memory enabled!

### Option 2: Command Line Install

```bash
# Download and run the setup script
./claude-chroma.sh

# Or specify project name directly
./claude-chroma.sh "my-awesome-project"
```

## What Gets Installed?

After setup, your project will have:

```
your-project/
├── .mcp.json                 # ChromaDB server configuration
├── CLAUDE.md                 # Project memory instructions
├── launch-claude-here.command # Double-click to start Claude
├── .chroma/                  # Memory database (gitignored)
└── .claude/                  # Claude settings
```

## Using Claude with Memory

### First Session
1. Double-click `launch-claude-here.command` (or run `claude` in terminal)
2. Claude reads `CLAUDE.md` and activates memory
3. Work on your project - Claude logs important decisions automatically

### Subsequent Sessions
1. Launch Claude the same way
2. Claude queries previous memories
3. Continues where you left off with full context!

## Memory Examples

Claude automatically remembers things like:

- **Decisions:** "Using TypeScript strict mode for type safety"
- **Fixes:** "Fixed auth bug by adding JWT refresh token logic"
- **Preferences:** "User prefers functional components over class components"
- **Tips:** "Database queries need connection pooling for performance"

## Troubleshooting

### "Command not found: claude"
Install Claude Desktop from: https://claude.ai/download

### "Command not found: uvx"
The installer will guide you through installing uv:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### "Raw mode is not supported" error
This was fixed in the latest installer. Make sure you're using `setup-claude-chroma-oneclick-fixed.command`

### Memory not working?
1. Check that ChromaDB server is running: Look for `chroma` in Claude's MCP servers
2. Verify collection name in CLAUDE.md matches your project
3. Ensure .mcp.json exists and points to .chroma directory

## Tips for Best Results

1. **Let Claude read CLAUDE.md first** - It contains the memory instructions
2. **Be patient with first launch** - ChromaDB server takes a few seconds to start
3. **Check memory periodically** - Claude logs decisions as it works
4. **One project = One collection** - Each project has its own isolated memory

## Next Steps

- Read the full [README.md](README.md) for advanced options
- Check [docs/development/](docs/development/) for technical details
- Report issues at: https://github.com/btangonan/claude-chroma/issues

---

**Ready to give Claude a memory upgrade? Let's go! 🧠✨**