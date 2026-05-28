#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$TARGET_DIR"
cp "$SCRIPT_DIR/pass" "$TARGET_DIR/pass"
chmod +x "$TARGET_DIR/pass"

echo "Installed pass to $TARGET_DIR/pass"
echo "Make sure $TARGET_DIR is in your PATH."
