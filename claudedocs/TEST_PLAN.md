# Test Plan: Setup Script vs Plugin Validation

**Purpose**: Verify that the enhanced `/chroma:setup` plugin command achieves the same results as the `claude-chroma.sh` setup script.

**Date**: 2025-10-14
**Script Version**: v3.5.3 (1954 lines)
**Plugin Command**: `/chroma:setup` (enhanced)

---

## Test Environment Setup

### Prerequisites
- macOS or Linux system
- Clean test directory (no existing ChromaDB config)
- Dependencies: uvx, jq, python3
- Claude Code CLI installed

### Test Projects

Create three test scenarios:
1. **Fresh Project**: No existing configuration
2. **Existing Project**: Has CLAUDE.md and .gitignore
3. **Configured Project**: Already has .mcp.json

---

## Test Suite

### Test 1: Fresh Project Setup

#### Setup Script Test
```bash
# Create clean test directory
mkdir -p ~/test-chroma-script
cd ~/test-chroma-script

# Run setup script
bash /path/to/claude-chroma.sh

# Capture state
ls -laR > script-state.txt
cat .mcp.json | jq '.' > script-mcp.json
cat CLAUDE.md > script-claude.md
cat .gitignore > script-gitignore.txt
```

#### Plugin Test
```bash
# Create clean test directory
mkdir -p ~/test-chroma-plugin
cd ~/test-chroma-plugin

# Run plugin command via Claude
# Execute: /chroma:setup

# Capture state
ls -laR > plugin-state.txt
cat .mcp.json | jq '.' > plugin-mcp.json
cat CLAUDE.md > plugin-claude.md
cat .gitignore > plugin-gitignore.txt
```

#### Validation Checklist

| Item | Script | Plugin | Match? |
|------|--------|--------|--------|
| **Directory Structure** | | | |
| `.chroma/` exists | ✅ | ☐ | ☐ |
| `.chroma/context/` exists | ✅ | ☐ | ☐ |
| `claudedocs/` exists | ✅ | ☐ | ☐ |
| `bin/` exists | ✅ | ☐ | ☐ |
| `templates/` exists | ✅ | ☐ | ☐ |
| **Configuration Files** | | | |
| `.mcp.json` created | ✅ | ☐ | ☐ |
| MCP uses absolute path | ✅ | ☐ | ☐ |
| Timeout settings (KEEP_ALIVE=0) | ✅ | ☐ | ☐ |
| initializationOptions present | ✅ | ☐ | ☐ |
| **CLAUDE.md** | | | |
| Created from template | ✅ | ☐ | ☐ |
| PROJECT_COLLECTION substituted | ✅ | ☐ | ☐ |
| Memory checkpoint rules present | ✅ | ☐ | ☐ |
| Retrieval checklist present | ✅ | ☐ | ☐ |
| **Memory Discipline** | | | |
| `.claude/settings.local.json` created | ✅ | ☐ | ☐ |
| Memory instructions added | ✅ | ☐ | ☐ |
| MEMORY_CHECKPOINT_REMINDER.md (if needed) | ✅ | ☐ | ☐ |
| **Documentation** | | | |
| `.gitignore` updated | ✅ | ☐ | ☐ |
| `.chroma/` in gitignore | ✅ | ☐ | ☐ |
| `claudedocs/INIT_INSTRUCTIONS.md` created | ✅ | ☐ | ☐ |
| `start-claude-chroma.sh` created | ✅ | ☐ | ☐ |
| **Connection** | | | |
| ChromaDB MCP accessible | ✅ | ☐ | ☐ |
| Can list collections | ✅ | ☐ | ☐ |

**Expected Result**: All items marked ✅ for both script and plugin

---

### Test 2: Existing Project (with CLAUDE.md)

#### Setup
```bash
mkdir -p ~/test-chroma-existing
cd ~/test-chroma-existing

# Create existing CLAUDE.md
cat > CLAUDE.md <<'EOF'
# My Custom Instructions
Use TypeScript for all code.
Prefer functional programming patterns.
EOF

# Create existing .gitignore
cat > .gitignore <<'EOF'
node_modules/
.env
EOF
```

#### Run Both Tools
```bash
# Test with script
bash /path/to/claude-chroma.sh

# Test with plugin (in separate directory)
# Execute: /chroma:setup
```

#### Validation Checklist

| Item | Script | Plugin | Match? |
|------|--------|--------|--------|
| **Backup System** | | | |
| `CLAUDE.md.backup.YYYYMMDD` created | ✅ | ☐ | ☐ |
| `CLAUDE.md.original` created | ✅ | ☐ | ☐ |
| `.gitignore.backup.YYYYMMDD` created | ✅ | ☐ | ☐ |
| Original content preserved | ✅ | ☐ | ☐ |
| **Merge Behavior** | | | |
| New CLAUDE.md has project contract | ✅ | ☐ | ☐ |
| .gitignore has ChromaDB entries | ✅ | ☐ | ☐ |
| No duplicate gitignore entries | ✅ | ☐ | ☐ |
| User notified about backups | ✅ | ☐ | ☐ |

**Expected Result**: Original files backed up, new config added, no data loss

---

### Test 3: Project with Existing .mcp.json

#### Setup
```bash
mkdir -p ~/test-chroma-merge
cd ~/test-chroma-merge

# Create existing .mcp.json with different server
cat > .mcp.json <<'EOF'
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
EOF
```

#### Run Both Tools
```bash
# Test with script
bash /path/to/claude-chroma.sh

# Test with plugin
# Execute: /chroma:setup
```

#### Validation Checklist

| Item | Script | Plugin | Match? |
|------|--------|--------|--------|
| **MCP Merge** | | | |
| `.mcp.json.backup.YYYYMMDD` created | ✅ | ☐ | ☐ |
| `github` server preserved | ✅ | ☐ | ☐ |
| `chroma` server added | ✅ | ☐ | ☐ |
| Valid JSON structure | ✅ | ☐ | ☐ |
| No duplicate chroma entries | ✅ | ☐ | ☐ |

**Expected Result**: Both servers present in merged config, valid JSON

---

### Test 4: Content Validation

#### CLAUDE.md Template Rendering

**Verify**:
1. PROJECT_COLLECTION correctly derived from directory name
   - Test with: "My Project", "my-app", "test_project"
   - Expected: "my_project_memory", "my_app_memory", "test_project_memory"

2. All ${VARIABLE} placeholders resolved
   - Search for `${` in output
   - Should find zero instances

3. Content validation
   - Not empty (>10 chars)
   - Not whitespace-only
   - Contains memory checkpoint rules
   - Contains Chroma MCP calls

#### .mcp.json Configuration

**Verify**:
1. Command is `uvx` (or detected alternative)
2. Args include `chroma-mcp`, `--client-type persistent`
3. Data dir is absolute path ending in `/.chroma`
4. Environment variables:
   - `CHROMA_SERVER_KEEP_ALIVE=0`
   - `CHROMA_CLIENT_TIMEOUT=0`
   - `ANONYMIZED_TELEMETRY=FALSE`
5. initializationOptions:
   - `timeout: 0`
   - `keepAlive: true`
   - `retryAttempts: 5`

#### .claude/settings.local.json

**Verify**:
1. `instructions` array present
2. Contains memory checkpoint reminders
3. References ChromaDB MCP calls
4. Has proper JSON structure
5. Permissions object present (can be empty)

---

### Test 5: Prerequisites Check

#### Test Missing Dependencies

```bash
# Hide uvx temporarily
alias uvx='return 1'

# Run setup
bash /path/to/claude-chroma.sh  # Should fail with clear error
# Execute: /chroma:setup         # Should fail with clear error

# Restore
unalias uvx
```

**Expected Behavior**:
- Both tools should detect missing uvx
- Provide installation instructions
- Exit gracefully without creating partial config

---

### Test 6: Connection Test

After setup, verify ChromaDB MCP works:

```bash
# Start Claude in project directory
cd ~/test-chroma-script
claude

# In Claude, test connection
mcp__chroma__chroma_list_collections
```

**Expected Result**:
- Connection succeeds (may return empty list)
- No timeout errors
- MCP server remains responsive

---

## Comparison Matrix

### File-by-File Comparison

```bash
# After running both script and plugin:

# Compare directory structures
diff <(cd ~/test-chroma-script && find . -type d | sort) \
     <(cd ~/test-chroma-plugin && find . -type d | sort)

# Compare .mcp.json (normalize paths first)
diff <(cat ~/test-chroma-script/.mcp.json | jq --sort-keys '.') \
     <(cat ~/test-chroma-plugin/.mcp.json | jq --sort-keys '.')

# Compare CLAUDE.md (ignore whitespace differences)
diff -w ~/test-chroma-script/CLAUDE.md \
        ~/test-chroma-plugin/CLAUDE.md

# Compare .gitignore (sorted)
diff <(sort ~/test-chroma-script/.gitignore) \
     <(sort ~/test-chroma-plugin/.gitignore)

# Compare settings.local.json
diff <(cat ~/test-chroma-script/.claude/settings.local.json | jq --sort-keys '.') \
     <(cat ~/test-chroma-plugin/.claude/settings.local.json | jq --sort-keys '.')
```

**Pass Criteria**: No significant differences (path variations OK)

---

## Edge Cases

### Edge Case 1: Special Characters in Project Name

```bash
mkdir -p "~/test-chroma/My Project [2025]"
cd "~/test-chroma/My Project [2025]"
# Run setup
```

**Verify**:
- PROJECT_COLLECTION = "my_project_2025_memory"
- All files created successfully
- No path escaping issues

### Edge Case 2: No Global CLAUDE.md

```bash
# Temporarily rename global config
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak

# Run setup
# Restore after test
mv ~/.claude/CLAUDE.md.bak ~/.claude/CLAUDE.md
```

**Verify**:
- `MEMORY_CHECKPOINT_REMINDER.md` created
- Setup continues successfully
- Global file unchanged (never modified)

### Edge Case 3: Existing .claude/ directory

```bash
mkdir -p .claude
echo '{}' > .claude/settings.local.json

# Run setup
```

**Verify**:
- Existing settings.local.json backed up
- Memory instructions merged (not duplicated)
- No overwrite of user settings

---

## Performance Tests

### Test 7: Setup Speed

```bash
# Measure script execution time
time bash /path/to/claude-chroma.sh

# Measure plugin execution time
# (manually time Claude's response)
```

**Expected**: Plugin may be slower (interactive) but more helpful

---

## Regression Tests

### Features That Should Still Work

1. **Multiple Runs** (idempotency)
   ```bash
   # Run setup twice
   bash /path/to/claude-chroma.sh
   bash /path/to/claude-chroma.sh
   ```
   **Expected**: Second run detects existing config, asks to update

2. **Partial Setup** (recovery)
   ```bash
   # Create only .chroma/ directory
   mkdir .chroma

   # Run setup
   ```
   **Expected**: Completes remaining steps, doesn't fail

3. **Permission Issues**
   ```bash
   # Make directory read-only
   mkdir .chroma && chmod 444 .chroma

   # Run setup
   ```
   **Expected**: Graceful error message, doesn't crash

---

## Success Criteria Summary

### Critical Requirements (Must Pass)

✅ **Directory Structure**: All 5 directories created
✅ **MCP Configuration**: Valid JSON with absolute path and timeout settings
✅ **CLAUDE.md**: Rendered from template with PROJECT_COLLECTION substituted
✅ **Memory Discipline**: Project settings.local.json with instructions
✅ **Backup System**: Existing files preserved with timestamps
✅ **Connection Test**: ChromaDB MCP accessible

### Important Requirements (Should Pass)

✅ **Documentation**: INIT_INSTRUCTIONS.md and start script created
✅ **.gitignore**: ChromaDB entries added without duplication
✅ **Prerequisites**: Missing dependencies detected and reported
✅ **Merge Logic**: Existing configs properly merged, not overwritten

### Nice-to-Have (May Differ)

⚠️ **Output Format**: Plugin may have better formatting/explanations
⚠️ **Error Messages**: Plugin may provide more context-aware help
⚠️ **Interactivity**: Plugin is inherently more interactive

---

## Test Report Template

```markdown
# ChromaDB Setup Test Report

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Environment**: [OS, Claude version]

## Test Results Summary

| Test Case | Script | Plugin | Status |
|-----------|--------|--------|--------|
| Fresh Project Setup | ✅ | ✅ | PASS |
| Existing CLAUDE.md | ✅ | ✅ | PASS |
| Existing .mcp.json | ✅ | ✅ | PASS |
| Content Validation | ✅ | ✅ | PASS |
| Prerequisites Check | ✅ | ✅ | PASS |
| Connection Test | ✅ | ✅ | PASS |
| Edge Cases | ✅ | ✅ | PASS |

## Detailed Findings

### Test 1: Fresh Project
- [ ] All directories created
- [ ] .mcp.json valid and correct
- [ ] CLAUDE.md rendered properly
- [ ] Memory discipline configured
- [ ] Connection test passed

[Additional details...]

### Issues Found
1. [Issue description]
   - Severity: Critical | Major | Minor
   - Affects: Script | Plugin | Both
   - Recommendation: [Fix needed]

### Differences Noted
1. [Difference description]
   - Impact: None | Low | High
   - Acceptable: Yes | No
   - Action: [What to do]

## Conclusion

**Overall Assessment**: ✅ PASS | ⚠️ PASS WITH ISSUES | ❌ FAIL

**Recommendation**:
- Plugin achieves functional parity with setup script
- All critical features preserved
- Enhanced documentation and interactivity
- Ready for production use

**Next Steps**:
- [Action items if any issues found]
```

---

## Automation Script

```bash
#!/bin/bash
# test-setup-parity.sh - Automated comparison test

set -euo pipefail

SCRIPT_PATH="$1"
TEST_BASE="$HOME/test-chroma-comparison"

echo "=== ChromaDB Setup Parity Test ==="
echo ""

# Test 1: Fresh Project
echo "Test 1: Fresh Project Setup"
rm -rf "$TEST_BASE/script-fresh" "$TEST_BASE/plugin-fresh"
mkdir -p "$TEST_BASE/script-fresh"
cd "$TEST_BASE/script-fresh"

# Run script non-interactively
NON_INTERACTIVE=1 ASSUME_YES=1 bash "$SCRIPT_PATH"

echo "✅ Script completed"
echo ""
echo "Now run plugin manually in $TEST_BASE/plugin-fresh"
echo "Then run comparison:"
echo "  diff -r $TEST_BASE/script-fresh $TEST_BASE/plugin-fresh"
echo ""

# Additional tests follow same pattern...
```

---

## Notes for Testers

1. **Manual Plugin Testing**: Since plugin runs inside Claude, automate what you can but expect some manual steps

2. **Path Variations**: Absolute paths will differ between tests - that's expected and OK

3. **Timestamp Differences**: Backup files will have different timestamps - compare structure, not exact names

4. **Interactive Differences**: Plugin may provide more explanation - focus on functional output equality

5. **Documentation Check**: Read generated docs to ensure they make sense and are complete

6. **Real-World Test**: After passing automated tests, use setup in a real project for a week to validate practical usability

---

## Maintenance

Update this test plan when:
- Setup script version changes
- Plugin command is enhanced
- New features are added
- Issues are discovered in production

**Last Updated**: 2025-10-14
**Script Version Tested**: v3.5.3
**Plugin Version Tested**: Enhanced (2025-10-14)
