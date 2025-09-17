# ChromaDB MCP Setup

A streamlined setup script for ChromaDB Model Context Protocol (MCP) server integration with Claude.

## Quick Start

Run the setup script from any directory:

```bash
# Basic setup (interactive mode)
"/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh"

# With project name
"/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh" "my_project"

# Non-interactive mode (auto-yes)
CHROMA_SETUP_YES=1 "/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh"

# Auto-install shell function
CHROMA_SETUP_ADD_SHELL_FN=1 "/Users/bradleytangonan/Desktop/my apps/chromadb/claude-chroma.sh"
```

Note: Quotes are required around the path due to the space in "my apps".

## Features

- Automated ChromaDB MCP server setup
- Claude settings.json configuration
- Shell function for easy access
- Project memory initialization
- Comprehensive error handling

## Files

- `claude-chroma.sh` - Main setup script
- `init_project_memory.py` - Initialize project memory collection
- `quick_start.sh` - Quick setup wrapper
- `CLAUDE.md.template` - Claude configuration template
- `settings.local.json.template` - Settings template
- `example_usage.md` - Usage examples and documentation
- `troubleshooting.md` - Common issues and solutions
- `FUTURE_IMPROVEMENTS.md` - Roadmap and enhancement ideas
- `IMPROVEMENTS.md` - Completed improvements

## Requirements

- macOS or Linux
- Python 3.8+
- uv package manager
- Claude Desktop app

## Repository

https://github.com/btangonan/chromadb-mcp