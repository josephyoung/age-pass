# age-pass

A password manager using [age](https://github.com/FiloSottile/age) encryption, compatible with a subset of [pass](https://www.passwordstore.org/) commands. Built for Termux on Android — no GPG agent needed.

用 [age](https://github.com/FiloSottile/age) 加密的密码管理器，兼容 [pass](https://www.passwordstore.org/) 的部分命令。专为 Termux on Android 打造，无需 GPG agent。

## Install / 安装

```bash
git clone https://github.com/josephyoung/age-pass.git
cd age-pass
./install.sh                        # defaults: ~/bin, ~/.age
./install.sh /usr/local/bin         # custom bin dir
./install.sh ~/bin /mnt/custom-age  # custom age store dir
```

Requires `age` and `tree`. `install.sh` installs them via `pkg` if missing (Termux).

依赖 `age` 和 `tree`，未安装时 `install.sh` 会自动通过 `pkg` 安装。

## Usage / 用法

```
pass [show|insert|list|rm|delete|help] [name]
```

```bash
pass insert github/token    # silent password input / 静默输入密码
pass show github/token      # decrypt and print / 解密输出
pass list                   # tree view / 树形列出所有条目
pass rm github/token        # delete / 删除
pass delete github/token    # alias for rm / 同上
pass help                   # show usage / 帮助
```

## Custom store / 自定义存储目录

```bash
PASS_AGE_DIR=/custom/path pass list
```

Or set the default at install time via `install.sh` second argument.

或安装时通过 `install.sh` 第二个参数指定默认值。

## Structure / 结构

```
~/.age/
├── keys.txt          # age keypair (chmod 600)
└── secrets/          # encrypted password files (.age)
    ├── email/
    │   └── gmail.age
    └── github/
        └── token.age
```

## Tests / 测试

```bash
./pass-test.sh
```

## License

MIT
