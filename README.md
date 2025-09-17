# Claude-Chroma

A streamlined setup script for ChromaDB Model Context Protocol (MCP) server integration with Claude.

## Purpose

Claude-Chroma enables **persistent memory** for Claude Desktop projects. Instead of starting fresh every session, Claude can remember your project decisions, fixes, and preferences across conversations. This creates continuity that dramatically improves development workflows by maintaining context about your codebase, architecture choices, and project history.

## Quick Start

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
- `init_project_memory.py` - Initialize project memory collection
- `example_usage.md` - Usage examples and documentation
- `troubleshooting.md` - Common issues and solutions
- `FUTURE_IMPROVEMENTS.md` - Roadmap and enhancement ideas
- `IMPROVEMENTS.md` - Completed improvements

## Requirements

- macOS or Linux
- Python 3.8+
- uv package manager
- Claude Desktop app

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