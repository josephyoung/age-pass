#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/bin}"
TARGET="$TARGET_DIR/pass"

if [[ -f "$TARGET" ]]; then
    rm "$TARGET"
    echo "Removed $TARGET"
else
    echo "pass not found at $TARGET"
    exit 1
fi
