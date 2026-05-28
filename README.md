# age-pass

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

## Custom store

```bash
PASS_AGE_DIR=/custom/path pass list
```

Or set the default at install time via `install.sh` second argument.

## Structure

```
~/.age/
├── keys.txt          # age keypair (chmod 600)
└── secrets/          # encrypted password files (.age)
    ├── email/
    │   └── gmail.age
    └── github/
        └── token.age
```

## Tests

```bash
./pass-test.sh
```

## License

MIT
