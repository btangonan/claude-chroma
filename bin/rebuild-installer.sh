#!/usr/bin/env bash
# Rebuild setup-claude-chroma.command installer with latest components
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔧 Rebuilding installer with latest components..."

# Validate source files exist
if [[ ! -f "claude-chroma.sh" ]]; then
    echo "❌ claude-chroma.sh not found"
    exit 1
fi

if [[ ! -f "templates/CLAUDE.md.tpl" ]]; then
    echo "❌ templates/CLAUDE.md.tpl not found"
    exit 1
fi

# Check if installer exists
INSTALLER_TEMPLATE="setup-claude-chroma.command"
if [[ ! -f "$INSTALLER_TEMPLATE" ]]; then
    echo "❌ $INSTALLER_TEMPLATE not found"
    exit 1
fi

# Extract the current embedded assets to preserve jq and uvx binaries
echo "📦 Extracting current embedded assets..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

# Extract everything after __EMBEDDED_ASSETS__
MARKER_LINE=$(grep -n "^__EMBEDDED_ASSETS__$" "$INSTALLER_TEMPLATE" | cut -d: -f1)
if [[ -z "$MARKER_LINE" ]]; then
    echo "❌ __EMBEDDED_ASSETS__ marker not found in installer"
    exit 1
fi

# Extract the tar.gz payload
tail -n +"$((MARKER_LINE + 1))" "$INSTALLER_TEMPLATE" | base64 -d | tar -xzf - -C "$TEMP_DIR"

echo "✓ Extracted existing assets to temp directory"

# Update claude-chroma.sh and templates/CLAUDE.md.tpl with current versions
echo "📝 Updating components..."
cp -f "claude-chroma.sh" "$TEMP_DIR/claude-chroma.sh"
mkdir -p "$TEMP_DIR/templates"
cp -f "templates/CLAUDE.md.tpl" "$TEMP_DIR/templates/CLAUDE.md.tpl"

echo "✓ Updated claude-chroma.sh"
echo "✓ Updated templates/CLAUDE.md.tpl"

# Repackage the assets
echo "📦 Repackaging assets..."
cd "$TEMP_DIR"
tar -czf "$TEMP_DIR/payload.tar.gz" .
PAYLOAD_BASE64=$(base64 < "$TEMP_DIR/payload.tar.gz")

cd "$PROJECT_ROOT"

# Build new installer
INSTALLER_OUTPUT="setup-claude-chroma.command.new"
echo "🔨 Building new installer..."

# Copy everything up to and including the __EMBEDDED_ASSETS__ marker
head -n "$MARKER_LINE" "$INSTALLER_TEMPLATE" > "$INSTALLER_OUTPUT"

# Append the new payload
echo "$PAYLOAD_BASE64" >> "$INSTALLER_OUTPUT"

# Make executable
chmod +x "$INSTALLER_OUTPUT"

echo ""
echo "✅ Rebuilt installer saved to: $INSTALLER_OUTPUT"
echo ""
echo "📊 Size comparison:"
echo "  Original: $(ls -lh "$INSTALLER_TEMPLATE" | awk '{print $5}')"
echo "  New:      $(ls -lh "$INSTALLER_OUTPUT" | awk '{print $5}')"
echo ""
echo "To test:"
echo "  mkdir -p /tmp/test-installer-$$ && cd /tmp/test-installer-$$ && \"$PROJECT_ROOT/$INSTALLER_OUTPUT\""
echo ""
echo "To replace original:"
echo "  mv \"$PROJECT_ROOT/$INSTALLER_OUTPUT\" \"$PROJECT_ROOT/$INSTALLER_TEMPLATE\""
