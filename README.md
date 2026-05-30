# age-pass

**Version: 1.1.0**

A password manager using [age](https://github.com/FiloSottile/age) encryption, compatible with a subset of [pass](https://www.passwordstore.org/) commands. Built for Termux on Android — no GPG agent needed.

Why not the original `pass`? GPG requires `gpg-agent`, which relies on Unix sockets and process forking — both problematic under Android's process isolation and `proot` environment in Termux. `age` has no agent, no daemons, just file-based key pairs.

[中文版](README-zh.md)

## Install

```bash
git clone https://github.com/josephyoung/age-pass.git
cd age-pass
./install.sh                        # defaults: ~/bin, ~/.age
./install.sh /usr/local/bin         # custom bin dir
./install.sh ~/bin /mnt/custom-age  # custom age store dir
```

Requires `age` and `tree`. `install.sh` installs them via `pkg` if missing (Termux).

## Usage

```
pass [show|insert|list|rm|delete|help] [name]
```

```bash
pass insert github/token    # silent password input
pass show github/token      # decrypt and print
pass list                   # tree view
pass rm github/token        # delete
pass delete github/token    # alias for rm
pass help                   # show usage
```

## Migration from GPG pass

Copy all passwords from your existing GPG-based `pass` to age-pass:

```bash
./pass-migrate --orig-pass /path/to/pass --age-pass /path/to/age-pass
```

Options:

```
--orig-pass <path>    Path to original pass binary
--age-pass <path>     Path to age-pass binary
--dry-run             Preview migration, don't write
--force               Overwrite existing entries without prompting
```

The script will:
1. Auto-detect both pass binaries (or prompt if not found)
2. Read all entries from the original store
3. Re-encrypt and save to age-pass
4. Verify tree structure and values match

Example:

```bash
# Preview what would be migrated
./pass-migrate --orig-pass /opt/homebrew/bin/pass --age-pass ~/bin/pass --dry-run

# Run the migration
./pass-migrate --orig-pass /opt/homebrew/bin/pass --age-pass ~/bin/pass

# Re-migrate with overwrite
./pass-migrate --force
```

## Custom store

```bash
PASS_AGE_DIR=/custom/path pass list
```

Or set the default at install time via `install.sh` second argument.

## Structure

```
~/.age/
├── keys.txt          # age keypair (chmod 600)
├── install-info.txt  # installed path (for migration auto-detect)
└── secrets/          # encrypted password files (.age)
    ├── email/
    │   └── gmail.age
    └── github/
        └── token.age
```

## Tests

```bash
bash tests/pass-test.sh          # core pass tests
bash tests/pass-migrate-test.sh  # migration tests
```

## License

MIT

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
