# Claude-Chroma Installer Documentation

## Available Installers

### 🚀 One-Click Installer (Recommended)
**File:** `setup-claude-chroma-oneclick-fixed.command` (88KB)
- **Platform:** macOS
- **Method:** Double-click to run
- **Features:** Fully automated, creates launcher, no TTY issues

### Self-Extracting Installer
**File:** `claude-chroma-installer-full.sh` (91KB)
- **Platform:** macOS/Linux
- **Method:** Command line
- **Features:** Portable, self-contained, scriptable

## One-Click Installer Details

The `setup-claude-chroma-oneclick-fixed.command` provides the easiest installation experience.

## Contents
The installer contains:
- **claude-chroma.sh** (60KB) - Main setup script
- **templates/CLAUDE.md.tpl** (2KB) - Comprehensive project contract template
- **README.md** (3KB) - User documentation

All files are base64-encoded and embedded within the installer script.

## Installation

### Quick Install
```bash
# Download the installer (from releases or distribution)
curl -O https://example.com/claude-chroma-installer-full.sh
chmod +x claude-chroma-installer-full.sh

# Run with default location (./claude-chroma)
./claude-chroma-installer-full.sh

# Or specify custom location
./claude-chroma-installer-full.sh /path/to/install
```

### Interactive Mode
When run without arguments, the installer will:
1. Prompt for installation location
2. Ask for confirmation before overwriting existing installations
3. Extract all files with proper permissions
4. Display installation summary

### Non-Interactive Mode
```bash
# Auto-confirm with 'yes' for scripted installations
echo "y" | ./claude-chroma-installer-full.sh /opt/claude-chroma
```

## What Happens During Installation

### One-Click Installer Process
1. **Extraction**: Unpacks embedded claude-chroma.sh and templates
2. **Dependency Check**: Verifies jq, uvx, python3, claude CLI
3. **Configuration**: Creates .mcp.json with ChromaDB settings
4. **Project Setup**: Generates CLAUDE.md with memory instructions
5. **Launcher Creation**: Makes launch-claude-here.command for easy startup
6. **Cleanup**: Removes temporary files

### Self-Extracting Installer Process
1. **Directory Creation**: Creates target directory and `templates/` subdirectory
2. **File Extraction**: Base64-decodes and extracts all embedded files
3. **Permission Setting**: Sets executable permission on `claude-chroma.sh`
4. **Verification**: Lists installed files and provides next steps

## Troubleshooting Common Issues

### TTY/Raw Mode Error
**Problem:** "Raw mode is not supported on the current process.stdin"
**Solution:** Use `setup-claude-chroma-oneclick-fixed.command` which creates a separate launcher

### Path with Spaces
**Problem:** Installation fails in directories with spaces
**Solution:** The fixed installer properly quotes all paths. Ensure using latest version.

### Missing Dependencies
**Problem:** "command not found: uvx"
**Solution:** Install uv package manager:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Permission Denied
**Problem:** Can't execute installer
**Solution:** Make it executable:
```bash
chmod +x setup-claude-chroma-oneclick-fixed.command
```

## Post-Installation Usage

After installation, navigate to the installation directory and run:

```bash
cd /path/to/installation

# Set up in current directory
./claude-chroma.sh

# Create new project
./claude-chroma.sh my_project

# Specify custom path
./claude-chroma.sh my_project /custom/path
```

## Technical Details

### Architecture
- **Self-Extracting**: Uses base64 encoding with heredoc markers
- **Portable**: Pure bash, works on macOS and Linux
- **Safe**: Validates paths, confirms overwrites, preserves permissions
- **Size**: ~91KB total (60KB script + 31KB overhead)

### Requirements
- Bash 4.0+
- base64 command (standard on macOS/Linux)
- No internet connection needed (fully offline)

## Distribution

The installer is ideal for:
- **Single-file downloads**: Users only need one file
- **Offline installations**: No internet required after download
- **Automated deployments**: Scriptable with proper exit codes
- **Version control**: Easy to track single file in git

## Creating the Installer

To rebuild the installer from source:

```bash
# From the claude-chroma directory with all Option 2 files:
./create-installer.sh  # (Would need to be created)

# Or manually:
cat installer-header.sh > claude-chroma-installer-full.sh
base64 < claude-chroma.sh >> claude-chroma-installer-full.sh
# ... (add markers and other files)
chmod +x claude-chroma-installer-full.sh
```

## Troubleshooting

### Installation Fails
- Ensure parent directory exists
- Check write permissions
- Verify base64 command availability

### Files Not Executable
- Installer sets permissions automatically
- Manual fix: `chmod +x claude-chroma.sh`

### Corrupt Extraction
- Re-download installer
- Check file integrity: `sha256sum claude-chroma-installer-full.sh`

## Advantages Over Multi-File Distribution

1. **Simplicity**: One file to manage instead of directory structure
2. **Integrity**: All components stay together
3. **Versioning**: Single file with embedded version
4. **Distribution**: Easy to share, email, or host
5. **Offline**: No dependency downloads needed

## Security Notes

- Verify installer source before running
- Review code if uncertain: `less claude-chroma-installer-full.sh`
- Installer only writes to specified directory
- No network connections made
- No system modifications outside target directory