#!/usr/bin/env bash
# Mock original GPG pass — stores plaintext files in a temp dir.
# Used by pass-migrate-test.sh to simulate a real pass store.
set -euo pipefail

MOCK_STORE="${PASS_MOCK_STORE:?PASS_MOCK_STORE not set}"

case "${1:-}" in
    list)
        if [[ "${2:-}" == "--flat" ]]; then
            # Flat list: paths relative to store, no .gpg extension
            if [[ -d "$MOCK_STORE" ]]; then
                find "$MOCK_STORE" -type f -name "*.gpg" \
                    | sed "s|^${MOCK_STORE}/||;s|\.gpg$||" \
                    | sort
            fi
        else
            # Tree view
            if [[ -d "$MOCK_STORE" ]] && [[ -n "$(ls -A "$MOCK_STORE" 2>/dev/null)" ]]; then
                tree --noreport "$MOCK_STORE" | sed 's/\.gpg$//'
            else
                echo "(empty)"
            fi
        fi
        ;;
    show)
        name="${2:-}"
        if [[ -z "$name" ]]; then
            echo "Usage: pass show <name>" >&2
            exit 1
        fi
        file="$MOCK_STORE/${name}.gpg"
        if [[ ! -f "$file" ]]; then
            echo "Error: ${name} not found" >&2
            exit 1
        fi
        cat "$file"
        ;;
    *)
        echo "Usage: mock-orig-pass [list|show] [name]" >&2
        exit 1
        ;;
esac
