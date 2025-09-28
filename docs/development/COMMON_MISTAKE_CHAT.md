# Common Mistake: "chat" Causing Hallucinations

## The Problem
Users see Claude creating random todo apps or chat applications when they type "chat".

## What's Happening
**WRONG** ❌
```bash
$ claude            # Starts Claude
> chat              # User types this INSIDE Claude
# Claude interprets "chat" as a request to build something
```

**CORRECT** ✅
```bash
$ claude chat       # Single command at terminal
# Claude starts with ChromaDB properly loaded
```

## The Confusion
The instructions say `claude chat` but users are:
1. Running `claude` (which starts Claude)
2. Then typing `chat` as input
3. Claude thinks they want to build a chat/todo application

## The Fix
**`claude chat` is a SINGLE COMMAND** - "chat" is a subcommand, not something you type after starting.

### Clear Instructions
- ✅ Run: `$ claude chat` (at your terminal)
- ✅ Or run: `$ ./start-claude-chroma.sh`
- ❌ Do NOT: Run `claude` then type `chat`

## Why This Happens
- `claude` alone starts Claude in a default mode
- `claude chat` starts Claude in chat mode with MCP support
- The word "chat" is a subcommand like `git commit` or `npm install`

## Updated in v3.3.3
The script now shows:
```
2. Run ONE of these commands:
   $ claude chat      (single command - do NOT type 'chat' after starting)
   $ ./start-claude-chroma.sh
```

## If You See This Issue
You're running the command wrong. Press Ctrl+C to exit Claude, then run the full command `claude chat` at your terminal.