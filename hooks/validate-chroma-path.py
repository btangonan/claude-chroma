#!/usr/bin/env python3
"""
ChromaDB Path Validation Hook
Runs before ChromaDB MCP operations to ensure paths are valid and accessible.
Warns about external volumes that may become unavailable.
"""

import json
import sys
import os
from pathlib import Path

def load_mcp_config():
    """Load and parse .mcp.json from project root."""
    try:
        mcp_path = Path.cwd() / ".mcp.json"
        if not mcp_path.exists():
            return None

        with open(mcp_path) as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Could not load .mcp.json: {e}", file=sys.stderr)
        return None

def get_chroma_data_dir(config):
    """Extract ChromaDB data directory from MCP config."""
    if not config:
        return None

    try:
        chroma_server = config.get("mcpServers", {}).get("chroma", {})
        args = chroma_server.get("args", [])

        # Find --data-dir argument
        for i, arg in enumerate(args):
            if arg == "--data-dir" and i + 1 < len(args):
                return Path(args[i + 1])

        return None
    except Exception:
        return None

def validate_path(data_dir):
    """
    Validate ChromaDB data directory.

    Returns:
        0: Path is valid and local
        1: Warning - path is on external volume
        2: Error - path is invalid or inaccessible
    """
    if not data_dir:
        return 0  # No config, skip validation

    # Check if path exists
    if not data_dir.exists():
        print(f"ChromaDB path does not exist: {data_dir}", file=sys.stderr)
        print(f"Run /chroma:setup to configure properly", file=sys.stderr)
        return 2

    # Check if path is accessible
    if not os.access(data_dir, os.R_OK | os.W_OK):
        print(f"ChromaDB path is not accessible: {data_dir}", file=sys.stderr)
        print(f"Check permissions on {data_dir}", file=sys.stderr)
        return 2

    # Check if path is on external volume (macOS specific)
    data_dir_str = str(data_dir)
    if data_dir_str.startswith("/Volumes/"):
        print(f"⚠️  ChromaDB is on external volume: {data_dir}", file=sys.stderr)
        print(f"⚠️  Risk: Volume may be unmounted, causing connection failures", file=sys.stderr)
        print(f"⚠️  Recommendation: Run /chroma:migrate to move to local storage", file=sys.stderr)
        return 1  # Warning, but allow operation

    # Path is valid and local
    return 0

def main():
    """Hook entry point."""
    try:
        # Load input from stdin (Claude Code hook protocol)
        input_data = json.load(sys.stdin)

        # Only validate for ChromaDB MCP operations
        tool_name = input_data.get("tool_name", "")
        if not tool_name.startswith("mcp__chroma__"):
            sys.exit(0)  # Not a ChromaDB operation, skip

        # Load MCP configuration
        config = load_mcp_config()
        data_dir = get_chroma_data_dir(config)

        # Validate path
        exit_code = validate_path(data_dir)

        # Exit codes:
        # 0 = success (continue)
        # 1 = warning (print to stderr, continue)
        # 2 = error (block operation)
        sys.exit(exit_code if exit_code == 2 else 0)

    except Exception as e:
        # Don't block on hook errors, just warn
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)

if __name__ == "__main__":
    main()
