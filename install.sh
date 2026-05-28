#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/bin}"
AGE_DIR="${2:-$HOME/.age}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Check & install dependencies ---

for dep in age tree; do
    if ! command -v "$dep" &>/dev/null; then
        echo "Installing $dep..."
        pkg install -y "$dep"
    fi
done

# --- Install script ---

mkdir -p "$TARGET_DIR"
cp "$SCRIPT_DIR/pass" "$TARGET_DIR/pass"

# Set age store directory default in installed script
sed -i "s|^AGE_DIR=.*|AGE_DIR=\"\${PASS_AGE_DIR:-$AGE_DIR}\"|" "$TARGET_DIR/pass"

chmod +x "$TARGET_DIR/pass"

# --- Set up default store directory ---

mkdir -p "$AGE_DIR"
chmod 700 "$AGE_DIR"

echo "Installed pass to $TARGET_DIR/pass"
echo "Password store: $AGE_DIR"
echo "Make sure $TARGET_DIR is in your PATH."
