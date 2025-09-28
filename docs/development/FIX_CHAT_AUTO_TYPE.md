# Fix: Claude Auto-Typing "chat" (v3.3.4)

## The Bug
Claude was automatically typing "chat" when starting, causing it to create todo/chat applications.

## Root Cause
The CLAUDE.md file contained instructions that Claude was misinterpreting:

### Problem Phrases
1. **"Read this file at chat start"** → Claude extracted "chat" as a command
2. **"Follow this in every chat"** → Claude parsed "chat" as input

Claude was literally following the instruction to type "chat" at start!

## The Solution (v3.3.4)

### Changed Phrases
- ❌ "Read this file at **chat** start"
- ✅ "Read this file at **session** start"

- ❌ "Follow this in every **chat**"
- ✅ "Follow this in every **session**"

## Files Updated
- `claude-chroma.sh` - Version 3.3.4
- Modified CLAUDE.md template to avoid the word "chat" in instructions

## Testing
After updating, new projects will get CLAUDE.md without problematic phrases.

For existing projects, manually edit your CLAUDE.md:
```bash
# Replace in existing CLAUDE.md files
sed -i '' 's/chat start/session start/g' CLAUDE.md
sed -i '' 's/every chat/every session/g' CLAUDE.md
```

## Why This Happened
Claude's instruction parser was too literal - it saw "chat" in the instructions and executed it as a command. By avoiding the word "chat" in operational instructions, we prevent this misinterpretation.

## Verification
Run the updated script (v3.3.4) to create projects with fixed CLAUDE.md that won't trigger auto-typing.