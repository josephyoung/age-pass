# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.1.0] - 2026-05-30

### Added
- `pass-migrate` script to copy passwords from original GPG pass to age-pass
- `--dry-run` flag for previewing migration without writing
- `--force` flag for overwriting existing entries
- Auto-detect or prompt for both original pass and age-pass paths
- Install path saved to `~/.age/install-info.txt` for auto-detection
- Migration test suite with mock original pass

### Fixed
- `get_entries` now works with original GPG pass (no `--flat` support)
- Tree structure comparison strips ANSI color codes

## [1.0.0] - 2026-05-30

### Added
- Core `pass` script with `show`, `insert`, `list`, `rm`, `delete`, and `help` commands
- `ls` and `remove` as aliases for `list` and `rm`
- `install.sh` with dependency checking and custom bin/store directories
- `uninstall.sh`
- OS detection for Termux (Android), macOS, and Linux
- `PASS_AGE_DIR` environment variable support
- Bilingual documentation (English/Chinese)

### Fixed
- `sed -i` portability across macOS and Linux
- Password input prompt in `cmd_insert`
- `list` command output (root node, double slash, secrets path)

### Changed
- Project structure: source in `src/`, tests in `tests/`, docs in `docs/`

## [0.1.0] - 2026-05-30

### Added
- Initial implementation of `pass` script
- Test framework with 7 test cases (6 passing)
- Plan and handoff documents
