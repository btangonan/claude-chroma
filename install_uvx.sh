#!/bin/bash

# ChromaDB Setup - UV/UVX Installation Helper
# This script helps install uv/uvx which is required for ChromaDB MCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_header "UV/UVX Installation Helper for ChromaDB"

# Check if uvx already exists
if command -v uvx >/dev/null 2>&1; then
    print_status "uvx is already installed at: $(which uvx)"
    uvx --version
    echo ""
    print_info "You're ready to run the ChromaDB setup!"
    echo "Run: ./chromadb_setup_fixed.sh"
    exit 0
fi

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    CYGWIN*|MINGW*|MSYS*) OS_TYPE=Windows;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

print_info "Detected OS: $OS_TYPE"
echo ""

# Function to test uvx after installation
test_uvx() {
    if command -v uvx >/dev/null 2>&1; then
        print_status "uvx installed successfully!"
        uvx --version
        return 0
    else
        return 1
    fi
}

# Function to add PATH and test
add_path_and_test() {
    local BIN_PATH="$1"
    export PATH="$BIN_PATH:$PATH"

    if test_uvx; then
        echo ""
        print_info "Add this to your shell configuration file:"
        echo "  export PATH=\"$BIN_PATH:\$PATH\""
        return 0
    fi
    return 1
}

# Method 1: Try with pip (most universal)
install_with_pip() {
    print_info "Attempting installation with pip..."

    # Check for Python and pip
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        print_error "Python is not installed. Please install Python 3.8+ first."
        return 1
    fi

    local PIP_CMD=""
    if command -v pip3 >/dev/null 2>&1; then
        PIP_CMD="pip3"
    elif command -v pip >/dev/null 2>&1; then
        PIP_CMD="pip"
    else
        print_error "pip is not installed. Installing pip..."
        python3 -m ensurepip --user 2>/dev/null || python -m ensurepip --user 2>/dev/null || {
            print_error "Could not install pip"
            return 1
        }
        PIP_CMD="python3 -m pip"
    fi

    # Install uv
    $PIP_CMD install --user uv || {
        print_error "Failed to install with pip"
        return 1
    }

    # Test different possible locations
    if add_path_and_test "$HOME/.local/bin"; then
        return 0
    elif add_path_and_test "$HOME/Library/Python/3.*/bin"; then
        return 0
    elif add_path_and_test "$HOME/.pyenv/shims"; then
        return 0
    fi

    print_error "uv installed but uvx not found in PATH"
    return 1
}

# Method 2: Homebrew (macOS/Linux)
install_with_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        print_info "Homebrew not found. Skipping this method."
        return 1
    fi

    print_info "Installing with Homebrew..."
    brew install uv || {
        print_error "Homebrew installation failed"
        return 1
    }

    test_uvx && return 0
    return 1
}

# Method 3: Official installer script
install_with_script() {
    print_info "Using official installation script..."

    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        print_error "Neither curl nor wget found"
        return 1
    fi

    # The installer adds to ~/.cargo/bin
    add_path_and_test "$HOME/.cargo/bin" && return 0
    add_path_and_test "$HOME/.local/bin" && return 0

    return 1
}

# Method 4: pipx
install_with_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        print_info "pipx not found. Skipping this method."
        return 1
    fi

    print_info "Installing with pipx..."
    pipx install uv || {
        print_error "pipx installation failed"
        return 1
    }

    test_uvx && return 0
    add_path_and_test "$HOME/.local/bin" && return 0

    return 1
}

# Main installation flow
echo "This script will help you install uv/uvx for ChromaDB MCP server."
echo ""

# Show installation methods
echo "Available installation methods:"
echo "  1) pip (Python package manager) - Recommended"
echo "  2) Homebrew (macOS/Linux)"
echo "  3) Official installer script (curl/wget)"
echo "  4) pipx (Python application installer)"
echo "  5) Manual installation instructions"
echo ""

read -p "Choose installation method (1-5): " METHOD

case $METHOD in
    1)
        install_with_pip && SUCCESS=true
        ;;
    2)
        install_with_homebrew && SUCCESS=true
        ;;
    3)
        install_with_script && SUCCESS=true
        ;;
    4)
        install_with_pipx && SUCCESS=true
        ;;
    5)
        echo ""
        print_header "Manual Installation Instructions"
        echo ""
        echo "Visit: https://github.com/astral-sh/uv"
        echo ""
        echo "Or run one of these commands:"
        echo ""
        echo "  # Using pip:"
        echo "  pip install --user uv"
        echo ""
        echo "  # Using Homebrew:"
        echo "  brew install uv"
        echo ""
        echo "  # Using installer script:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo ""
        echo "  # For Windows (PowerShell):"
        echo "  irm https://astral.sh/uv/install.ps1 | iex"
        echo ""
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Check if installation succeeded
if [ "${SUCCESS}" = "true" ]; then
    echo ""
    print_header "✅ Installation Successful!"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "  2. Run the ChromaDB setup: ./chromadb_setup_fixed.sh"
    echo ""
else
    echo ""
    print_error "Automatic installation failed."
    echo ""
    print_info "Try manual installation:"
    echo ""
    echo "  1. Visit: https://github.com/astral-sh/uv"
    echo "  2. Follow installation instructions for your OS"
    echo "  3. Make sure 'uvx' command is available"
    echo "  4. Run: ./chromadb_setup_fixed.sh"
    echo ""

    # Offer to try all methods automatically
    echo ""
    read -p "Would you like to try all methods automatically? (y/n): " TRY_ALL
    if [[ "$TRY_ALL" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Trying all installation methods..."

        for method in install_with_pip install_with_homebrew install_with_script install_with_pipx; do
            echo ""
            if $method; then
                print_header "✅ Installation Successful with $method!"
                echo ""
                print_info "Restart your terminal and run: ./chromadb_setup_fixed.sh"
                exit 0
            fi
        done

        print_error "All automatic methods failed. Please try manual installation."
    fi
fi

# Final check - update shell config
if command -v uvx >/dev/null 2>&1; then
    echo ""
    print_info "Updating shell configuration..."

    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            SHELL_CONFIG="$HOME/.bashrc"
            [ -f "$HOME/.bash_profile" ] && SHELL_CONFIG="$HOME/.bash_profile"
            ;;
        zsh)
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        fish)
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            ;;
        *)
            SHELL_CONFIG=""
            ;;
    esac

    if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
        # Check if PATH already contains uvx location
        UVX_PATH=$(dirname "$(which uvx)")
        if ! grep -q "$UVX_PATH" "$SHELL_CONFIG" 2>/dev/null; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by ChromaDB uvx installer" >> "$SHELL_CONFIG"
            echo "export PATH=\"$UVX_PATH:\$PATH\"" >> "$SHELL_CONFIG"
            print_status "Added uvx to PATH in $SHELL_CONFIG"
        fi
    fi
fi