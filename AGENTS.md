---
description: AGENTS.md
alwaysApply: true
---

# Project

**age-pass** — a password manager using [age](https://github.com/FiloSottile/age) encryption, compatible with a subset of `pass` commands. Built for Termux on Android; no GPG agent needed. Also runs on macOS.

# Architecture

- `src/pass` — the main bash script (~80 LOC). Single file, no dependencies beyond `age` and `tree`.
- `src/pass-migrate` — migration script to copy passwords from original GPG pass to age-pass.
- `install.sh` — installs pass script + deps. Supports Termux (pkg) and macOS (brew). Saves install path to `~/.age/install-info.txt`.
- `tests/pass-test.sh` — pure bash test harness for `src/pass`.
- `tests/pass-migrate-test.sh` — tests for migration script (uses mock original pass).
- `tests/mock-orig-pass.sh` — mock original pass for testing migration (plaintext storage).
- Store layout: `~/.age/keys.txt` (keypair) + `~/.age/secrets/**/*.age` (encrypted files).

# Conventions

- **Bash only.** No Python, no external test frameworks.
- **Minimal dependencies.** Only `age`, `tree`, and standard coreutils.
- **Tests are assertions + helpers.** `assert_*` functions check exit codes, stdout, stderr, file existence. No mocking frameworks.
- **Each test does setup/teardown** via temp dirs — tests never touch real user data.
- Style: `set -euo pipefail`, double brackets, 4-space indent.

# Git

- **Conventional Commits** format: `<type>(<scope>): <summary>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Subject in **English**, imperative mood ("add" not "added")
- Scope optional but used for `pass`, `migrate`, `install`, `tests`
- Body only when subject isn't self-explanatory

# Commands

```bash
# Core pass
bash src/pass insert <name>      # add a password (reads from stdin)
bash src/pass show <name>        # decrypt and print
bash src/pass list               # tree view of secrets
bash src/pass rm <name>          # delete
bash src/pass help               # usage

# Migration
bash src/pass-migrate --orig-pass /path/to/pass --age-pass /path/to/age-pass
bash src/pass-migrate --dry-run  # preview only
bash src/pass-migrate --force    # overwrite existing entries

# Tests
bash tests/pass-test.sh          # run all pass tests
bash tests/pass-migrate-test.sh  # run migration tests
```

# Rules

1. **Single-file simplicity.** The main script should remain one file. Don't split into modules.
2. **No new dependencies.** If you think you need one, ask first.
3. **Tests must pass before merge.** Run both test scripts after any change.
4. **Preserve Termux compatibility.** Android's process model is the primary constraint.
5. **Test against real interfaces.** Original `pass list --flat` doesn't exist. Verify actual CLI behavior before assuming flags/features.
6. **Don't over-engineer.** This is a small utility. Keep it small.
