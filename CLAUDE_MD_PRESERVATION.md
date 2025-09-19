# CLAUDE.md Preservation Feature (v3.3.2)

## Overview
Version 3.3.2 introduces improved CLAUDE.md handling that preserves existing user instructions while setting up ChromaDB configuration.

## The Problem
Previously, when adding ChromaDB to an existing project with CLAUDE.md, users had to choose between:
- Keeping their existing instructions (losing ChromaDB setup)
- Overwriting with ChromaDB instructions (losing custom content)

## The Solution
The script now **automatically preserves** existing CLAUDE.md content:

1. **Creates two backups** when CLAUDE.md exists:
   - `CLAUDE.md.original` - Easy-to-find reference copy
   - `CLAUDE.md.backup.YYYYMMDD_HHMMSS` - Timestamped safety backup

2. **Clear user messaging**:
   ```
   📁 Preserved your existing CLAUDE.md:
     → CLAUDE.md.original (your custom instructions)
     → CLAUDE.md.backup.20250918_234802 (timestamped backup)
   ```

3. **Reference in new file**:
   - New CLAUDE.md includes footer note about preserved content
   - Points users to CLAUDE.md.original for their custom instructions

## How It Works

### Function: `backup_claude_md()`
```bash
backup_claude_md() {
    if [[ -f "CLAUDE.md" ]]; then
        # Create timestamped backup for safety
        local timestamped_backup="CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"

        # Create timestamped backup
        cp -p "CLAUDE.md" "$timestamped_backup"

        # Also create .original for easy user reference
        cp -p "CLAUDE.md" "CLAUDE.md.original"

        print_info "📁 Preserved your existing CLAUDE.md:"
        print_info "  → CLAUDE.md.original (your custom instructions)"
        print_info "  → $timestamped_backup (timestamped backup)"
    fi
}
```

### Updated `create_claude_md()` Flow
1. Checks if CLAUDE.md exists
2. If exists, automatically backs up (no prompt)
3. Creates new CLAUDE.md with ChromaDB instructions
4. Adds footer note about preserved content
5. Displays message about where originals are stored

## User Experience

### Before v3.3.2
```
CLAUDE.md already exists
Update with ChromaDB instructions? [y/N]: y
[File completely replaced, user content lost]
```

### After v3.3.2
```
CLAUDE.md already exists
Backing up your existing instructions and creating ChromaDB configuration...
📁 Preserved your existing CLAUDE.md:
  → CLAUDE.md.original (your custom instructions)
  → CLAUDE.md.backup.20250918_234802 (timestamped backup)
✓ Created CLAUDE.md with ChromaDB instructions
💡 Your original instructions are preserved in: CLAUDE.md.original
   You can manually merge them if needed
```

## Testing

### Test Command
```bash
# Create test directory with existing CLAUDE.md
mkdir test-project && cd test-project
cat > CLAUDE.md << 'EOF'
# My Custom Instructions
Important project documentation
EOF

# Add ChromaDB (will preserve existing)
./claude-chroma.sh

# Verify preservation
ls -la CLAUDE.md*
cat CLAUDE.md.original  # Shows original content
```

### Expected Results
```
CLAUDE.md                         # New ChromaDB instructions
CLAUDE.md.original                # Your original content
CLAUDE.md.backup.20250918_234802  # Timestamped backup
```

## Benefits

1. **Zero Data Loss**: Original content always preserved
2. **Clear Recovery Path**: Easy-to-find .original file
3. **Safety Net**: Timestamped backups for recovery
4. **No Surprises**: Automatic preservation, no confusing prompts
5. **Manual Merge Option**: Users can combine content if desired

## Migration Path

For users with existing projects:
1. Run the updated script (v3.3.2+)
2. Original CLAUDE.md automatically backed up
3. Review CLAUDE.md.original
4. Optionally merge custom content back if needed

## Technical Details

- **Idempotent**: Running multiple times won't create duplicate backups
- **Safe Operations**: Uses `cp -p` to preserve permissions
- **Dry-run Compatible**: Respects DRY_RUN mode
- **Clear Messaging**: Users always informed about backups

## Version History

- **v3.3.1**: Character validation improvements
- **v3.3.2**: CLAUDE.md preservation feature
  - Added `backup_claude_md()` function
  - Updated `create_claude_md()` to use new backup
  - Improved user messaging
  - Added .original reference file

## Best Practices

1. **Always check CLAUDE.md.original** after setup
2. **Manually merge** important custom instructions if needed
3. **Keep backups** until you've verified the new setup
4. **Use dry-run** first if unsure: `DRY_RUN=1 ./claude-chroma.sh`

## Future Improvements

Potential enhancements for future versions:
- Smart merge that appends custom content automatically
- Interactive merge tool for combining instructions
- Automatic detection of ChromaDB sections to avoid duplication
- Version control integration for better diff management