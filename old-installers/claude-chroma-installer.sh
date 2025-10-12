#!/usr/bin/env bash
# Claude-Chroma One-File Installer
# Version: 3.5.3
# This is a self-extracting installer that contains all Option 2 components

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="${1:-./claude-chroma}"

print_header() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Function to extract embedded files
extract_files() {
    local target_dir="$1"

    # Create installation directory
    if [[ -d "$target_dir" ]]; then
        print_warning "Directory $target_dir already exists"
        read -p "Overwrite existing installation? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
        rm -rf "$target_dir"
    fi

    mkdir -p "$target_dir"
    mkdir -p "$target_dir/templates"

    print_info "Extracting claude-chroma.sh..."
    base64 -d <<'CLAUDE_CHROMA_BASE64' > "$target_dir/claude-chroma.sh"
$(base64 < claude-chroma.sh)
CLAUDE_CHROMA_BASE64
    chmod +x "$target_dir/claude-chroma.sh"
    print_status "Extracted claude-chroma.sh"

    print_info "Extracting templates/CLAUDE.md.tpl..."
    base64 -d <<'CLAUDE_TEMPLATE_BASE64' > "$target_dir/templates/CLAUDE.md.tpl"
$(base64 < templates/CLAUDE.md.tpl)
CLAUDE_TEMPLATE_BASE64
    print_status "Extracted CLAUDE.md template"

    print_info "Extracting README.md..."
    base64 -d <<'README_BASE64' > "$target_dir/README.md"
$(base64 < README.md)
README_BASE64
    print_status "Extracted README.md"
}

# Main installation flow
main() {
    print_header "🚀 Claude-Chroma One-File Installer"
    echo ""
    print_info "This will install the Claude-Chroma Option 2 package:"
    echo "  • claude-chroma.sh (main script)"
    echo "  • templates/CLAUDE.md.tpl (comprehensive template)"
    echo "  • README.md (documentation)"
    echo ""

    if [[ "$#" -eq 0 ]]; then
        print_info "No installation directory specified"
        echo "Usage: $0 [installation_directory]"
        echo "Default: ./claude-chroma"
        echo ""
        read -p "Install to default location ./claude-chroma? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter installation directory: " INSTALL_DIR
        fi
    fi

    # Validate installation directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"  # Expand tilde
    INSTALL_DIR="$(cd "$(dirname "$INSTALL_DIR")" 2>/dev/null && pwd)/$(basename "$INSTALL_DIR")" || {
        print_error "Invalid installation directory"
        exit 1
    }

    print_info "Installing to: $INSTALL_DIR"
    echo ""

    # Extract files
    extract_files "$INSTALL_DIR"

    echo ""
    print_header "✨ Installation Complete!"
    echo ""
    print_status "Claude-Chroma has been installed to:"
    echo "  $INSTALL_DIR"
    echo ""
    print_info "Files installed:"
    ls -la "$INSTALL_DIR" | grep -E "claude-chroma.sh|README.md"
    ls -la "$INSTALL_DIR/templates" | grep "CLAUDE.md.tpl"
    echo ""
    print_info "Next steps:"
    echo "  1. cd \"$INSTALL_DIR\""
    echo "  2. ./claude-chroma.sh [project_name] [project_path]"
    echo "  3. Follow the setup prompts"
    echo ""
    print_info "Quick start:"
    echo "  cd \"$INSTALL_DIR\" && ./claude-chroma.sh"
    echo ""
    print_info "For more information, see README.md"
}

# Run main function
main "$@"