# Claude-Chroma

A streamlined setup script for ChromaDB Model Context Protocol (MCP) server integration with Claude.

## Purpose

Claude-Chroma enables **persistent memory** for Claude Desktop projects. Instead of starting fresh every session, Claude can remember your project decisions, fixes, and preferences across conversations. This creates continuity that dramatically improves development workflows by maintaining context about your codebase, architecture choices, and project history.

📖 **New to Claude-Chroma?** Check out our [Quick Start Guide](QUICKSTART.md) for the fastest setup!

## Quick Start

### 🚀 One-Click Installation (Easiest!)

**macOS Users:** Simply double-click the installer:
1. Download `setup-claude-chroma-oneclick-fixed.command`
2. Double-click to run
3. Enter your project name when prompted
4. Done! Use the created `launch-claude-here.command` to start Claude with memory

### Command Line Installation

Run the setup script from any directory:

```bash
# Basic setup (interactive mode)
./claude-chroma.sh

# With project name
./claude-chroma.sh "my_project"

# Non-interactive mode (auto-yes)
CHROMA_SETUP_YES=1 ./claude-chroma.sh

# Auto-install shell function
CHROMA_SETUP_ADD_SHELL_FN=1 ./claude-chroma.sh
```

## Features

- Automated ChromaDB MCP server setup
- Claude settings.json configuration
- Shell function for easy access
- Project memory initialization
- Comprehensive error handling

## Files

- `claude-chroma.sh` - Main setup script (self-contained with embedded templates)
- `example_usage.md` - Usage examples and documentation
- `troubleshooting.md` - Common issues and solutions
- `FUTURE_IMPROVEMENTS.md` - Roadmap and enhancement ideas
- `IMPROVEMENTS.md` - Completed improvements

## Requirements

- macOS or Linux
- [uv package manager](https://docs.astral.sh/uv/getting-started/installation/) (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- Claude Desktop app

**Note**: The script will check for `uvx` and guide you through installation if needed. Python is auto-downloaded by uvx when required.

**Network Filesystems**: If your project is on NFS, SMB, or similar network storage, file locking behavior may vary. The registry uses cross-platform locks for safety but network filesystems may introduce occasional delays in lock acquisition.

## Usage After Setup

Once setup is complete, you have several ways to start Claude with ChromaDB:

### Using the Shell Function (Recommended)

If you enabled the shell function during setup:

```bash
# Start Claude with ChromaDB in current directory
claude-chroma

# Start with additional Claude arguments
claude-chroma --help
claude-chroma --model sonnet
```

### Direct Command

```bash
# Start Claude with ChromaDB configuration
claude --mcp-config .claude/settings.local.json

# With additional Claude arguments
claude --mcp-config .claude/settings.local.json --model sonnet
```

### Using the Start Script

```bash
# Use the generated start script
./start-claude-chroma.sh

# With arguments
./start-claude-chroma.sh --model sonnet
```

**Note**: The shell function and start script will automatically detect if you're in a directory with ChromaDB configuration and use it.

## Repository

https://github.com/btangonan/claude-chroma