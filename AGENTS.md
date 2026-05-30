---
description: AGENTS.md
alwaysApply: true
---

# Project

**age-pass** — a password manager using [age](https://github.com/FiloSottile/age) encryption, compatible with a subset of `pass` commands. Built for Termux on Android; no GPG agent needed. Also runs on macOS.

# Architecture

- `src/pass` — the main bash script (~80 LOC). Single file, no dependencies beyond `age` and `tree`.
- `install.sh` — installs pass script + deps. Supports Termux (pkg) and macOS (brew).
- `tests/pass-test.sh` — pure bash test harness. No framework. Run with `bash tests/pass-test.sh`.
- Store layout: `~/.age/keys.txt` (keypair) + `~/.age/secrets/**/*.age` (encrypted files).

# Conventions

- **Bash only.** No Python, no external test frameworks.
- **Minimal dependencies.** Only `age`, `tree`, and standard coreutils.
- **Tests are assertions + helpers.** `assert_*` functions check exit codes, stdout, stderr, file existence. No mocking.
- **Each test does setup/teardown** via temp dirs — tests never touch real user data.
- Style: `set -euo pipefail`, double brackets, 4-space indent.

# Commands

```bash
bash tests/pass-test.sh          # run all tests
bash src/pass insert <name>      # add a password (reads from stdin)
bash src/pass show <name>        # decrypt and print
bash src/pass list               # tree view of secrets
bash src/pass rm <name>          # delete
bash src/pass help               # usage
```

# Rules

1. **Single-file simplicity.** The main script should remain one file. Don't split into modules.
2. **No new dependencies.** If you think you need one, ask first.
3. **Tests must pass before merge.** Run `bash tests/pass-test.sh` after any change.
4. **Preserve Termux compatibility.** Android's process model is the primary constraint.
5. **Don't over-engineer.** This is a small utility. Keep it small.
