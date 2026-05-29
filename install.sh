#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/bin}"
AGE_DIR="${2:-$HOME/.age}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_SRC="$SCRIPT_DIR/src/pass"

# --- OS detection ---

install_deps_termux() {
    for dep in age tree; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Installing $dep..."
            pkg install -y "$dep"
        fi
    done
}

install_deps_macos() {
    for dep in age tree; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Installing $dep via Homebrew..."
            if ! brew install "$dep"; then
                echo "Error: Failed to install $dep with Homebrew."
                echo "Please install manually:"
                echo "  brew install age tree"
                exit 1
            fi
        fi
    done
}

show_help() {
    echo "OS detected: $(uname -s)"
    echo ""
    echo "This script currently supports:"
    echo "  - Termux (Android)"
    echo "  - macOS"
    echo ""
    echo "Please install dependencies manually:"
    echo "  - age: https://github.com/FiloSottile/age#installation"
    echo "  - tree: https://linux.die.net/man/1/tree"
    echo ""
    echo "Then re-run this script."
    exit 1
}

# --- Check & install dependencies ---

if [ -d "/data/data/com.termux" ]; then
    # Termux environment
    install_deps_termux
elif [ "$(uname -s)" = "Darwin" ]; then
    # macOS
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew is not installed."
        echo "Please install Homebrew first:"
        echo "  https://brew.sh"
        echo ""
        echo "Then re-run this script."
        exit 1
    fi
    install_deps_macos
else
    # Other OS
    show_help
fi

# --- Install script ---

mkdir -p "$TARGET_DIR"
cp "$PASS_SRC" "$TARGET_DIR/pass"

# Set age store directory default in installed script
sed -i "s|^AGE_DIR=.*|AGE_DIR=\"\${PASS_AGE_DIR:-$AGE_DIR}\"|" "$TARGET_DIR/pass"

chmod +x "$TARGET_DIR/pass"

# --- Set up default store directory ---

mkdir -p "$AGE_DIR"
chmod 700 "$AGE_DIR"

echo "Installed pass to $TARGET_DIR/pass"
echo "Password store: $AGE_DIR"
echo "Make sure $TARGET_DIR is in your PATH."
