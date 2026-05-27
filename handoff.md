# Handoff: age-pass

## What Happened

用户想用 `age` 替代 GPG 做本地密码管理（`pass` 命令）。原因：GPG 在 Termux 中有进程端口/socket 问题。

经过 grill-me 流程，逐个决策敲定了方案，写入 `pass-plan.md`。

## What's Done

- [x] 需求澄清（grill-me 15 轮问答）
- [x] 方案设计 → `pass-plan.md`
- [x] 项目目录 `~/projects/age-pass/` + git init
- [x] 安装 `age`（pkg install age，已完成）
- [x] 安装 TDD skill（`~/.agents/skills/tdd`）

## What's Next

按 `pass-plan.md` 的 TDD 流程开始实现：

1. 写测试框架 `pass-test.sh`（临时 HOME、断言函数）
2. RED→GREEN #1：首次 insert 自动生成密钥对
3. RED→GREEN #2：insert + show 基本流程
4. ...（详见 plan 的循环顺序）

## Key Decisions

- 脚本路径：`$HOME/bin/pass`
- 命令集：list / show / insert / rm / delete / help（砍掉 find / grep / edit）
- 单行条目，不做多行
- 无 env 集成，聚焦 pass 本身
- 首次 insert 自动生成密钥对
- list 用 tree 命令树形显示
- 删除无确认，已存在插入提示覆盖

## Files

- `~/projects/age-pass/pass-plan.md` — 完整计划（含 TDD 流程）
- `~/projects/age-pass/pass-test.sh` — 待创建，测试文件
- `$HOME/bin/pass` — 待创建，最终脚本
- `$HOME/bin/pass-test.sh` — 待创建，测试脚本（或放项目目录）

## Skills to Use

- `tdd`（`~/.agents/skills/tdd`）— red-green-refactor 流程
- `karpathy-guidelines`（`~/.agents/skills/karpathy-guidelines`）— 避免过度设计

## Environment

- Termux on Android
- age 已安装（`pkg install age`）
- 需确认 `tree` 是否已安装（`pkg install tree`）
- 当前 `.zshrc` 中有明文 API Key 待迁移
