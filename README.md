# age-pass

用 [age](https://github.com/FiloSottile/age) 加密的密码管理器，兼容 [pass](https://www.passwordstore.org/) 的部分核心功能。

GPG 在 Termux 中有进程/socket 问题，age 无 agent 依赖，更适合 Android 环境。

## 安装

```bash
git clone https://github.com/josephyoung/age-pass.git
cd age-pass
./install.sh                        # 默认 ~/bin, ~/.age
./install.sh /usr/local/bin         # 自定义 bin 目录
./install.sh ~/bin /mnt/custom-age  # 自定义 age 目录
```

依赖 `age` 和 `tree`，未安装时 `install.sh` 会自动通过 `pkg` 安装（Termux）。

## 用法

```
pass [show|insert|list|rm|delete|help] [name]
```

```bash
pass insert github/token    # 静默输入密码
pass show github/token      # 解密输出
pass list                   # 树形列出所有条目
pass rm github/token        # 删除
pass delete github/token    # 同上
pass help                   # 帮助
```

## 自定义存储目录

```bash
PASS_AGE_DIR=/custom/path pass list
```

安装时也可以通过 `install.sh` 第二个参数指定默认值。

## 结构

```
~/.age/
├── keys.txt          # age 密钥对 (chmod 600)
└── secrets/          # 加密后的密码文件 (.age)
    ├── email/
    │   └── gmail.age
    └── github/
        └── token.age
```

## 测试

```bash
./pass-test.sh
```

## License

MIT
