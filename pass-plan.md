# pass 计划：用 age 替代 GPG 的密码管理方案

## 背景

GPG 在 Termux 中有进程端口、socket 等问题，需要一个更稳定的本地密码管理方案。`age` 是现代加密工具，无 agent 依赖，适合 Termux 环境。

## 目标

写一个 bash 脚本 `pass`（项目目录内），用 `age` 加密代替 GPG，实现 `pass` 的核心子集。附带 `install.sh` 安装脚本，可安装到任意目录。

## 命令规格

```
pass                         # 列出所有条目（树形）
pass list                    # 同上
pass show <name>             # 解密输出密码（单行）
pass insert <name>           # 交互式输入密码（单行）
pass rm / pass delete <name> # 删除条目（无确认）
pass help                    # 帮助信息
```

### 边界行为

- `pass show` / `pass insert` 缺参数 → 报错 + 打印用法
- `pass insert` 已存在同名条目 → 提示 `Overwrite? [y/N]`
- `pass rm` 直接删除，无确认

## 砍掉的功能（决策记录）

| 功能 | 砍掉原因 |
|---|---|
| find / grep | 单行条目无需内容搜索，文件名即索引 |
| edit | 单行场景 rm + insert 两步替代 |
| 多行支持 | 简化，只存密码 |
| env 集成 | 本次不涉及，聚焦 pass 本身 |
| env.conf 映射文件 | 随 env 集成一起砍掉 |
| .zshrc 修改 | 不在本次范围 |

## 架构

```
~/projects/age-pass/
├── pass                    # 主脚本（开发位置）
├── pass-test.sh            # 测试脚本
├── install.sh              # 安装脚本
├── pass-plan.md
└── handoff.md

~/.age/                     # 运行时数据（pass 自动创建）
├── keys.txt                # age 密钥对（私钥+公钥），chmod 600
└── secrets/
    ├── api-keys/
    │   ├── deepseek.age
    │   ├── minimax.age
    │   └── xiaomi-mimo.age
    └── email/
        └── lobstermail.age
```

- `pass show api-keys/deepseek` → 解密 `~/.age/secrets/api-keys/deepseek.age`
- 支持任意层级目录
- `install.sh [目标目录]` → 默认安装到 `$HOME/bin/`

## 依赖

- `age`（`pkg install age`，已安装）
- `tree`（`pkg install tree`，用于 `pass list` 树形显示）

## TDD 流程

采用 red-green-refactor 垂直切片：一个测试 → 一个实现 → 循环。

### 测试方式

用 bash 脚本做集成测试。每个测试：
1. 设置临时 `HOME` 目录（隔离 `~/.age`）
2. 运行 `pass` 命令（项目目录内的 `./pass`）
3. 断言输出 / 退出码 / 文件存在性
4. 清理临时目录

测试文件：`./pass-test.sh`（项目目录内）

### 行为清单（测试用例）

按优先级排序，每个行为对应一个 RED→GREEN 循环：

| # | 行为 | 测试要点 |
|---|---|---|
| 1 | 首次 insert 自动生成密钥对 | `~/.age/keys.txt` 不存在时 insert → 生成密钥 + 创建加密文件 |
| 2 | insert 创建加密条目 | `pass insert xxx` → `.age` 文件存在 + `pass show xxx` 输出正确密码 |
| 3 | show 输出解密内容 | insert 后 show → stdout 匹配原文 |
| 4 | list 显示所有条目 | insert 多个 → `pass list` 输出包含所有条目名 |
| 5 | rm 删除条目 | insert → rm → 文件不存在 + show 报错 |
| 6 | delete 等价于 rm | 同上，用 `pass delete` |
| 7 | show 缺参数报错 | `pass show` 无参数 → 退出码非 0 + stderr 有 usage |
| 8 | insert 缺参数报错 | `pass insert` 无参数 → 退出码非 0 + stderr 有 usage |
| 9 | insert 已存在提示覆盖 | insert 同名两次 → 第二次提示 overwrite |
| 10 | help 输出用法 | `pass help` → stdout 有 usage 信息 |
| 11 | 无条目时 list | 空 secrets 目录 → `pass list` 不报错 |

### 循环顺序

```
RED→GREEN #1:  首次 insert 自动生成密钥对
RED→GREEN #2:  insert + show 基本流程
RED→GREEN #3:  list 显示条目
RED→GREEN #4:  rm 删除
RED→GREEN #5:  边界：缺参数报错
RED→GREEN #6:  边界：已存在覆盖提示
RED→GREEN #7:  help + delete 别名 + 空 list
REFACTOR:      提取重复、整理代码
```

## 实施步骤

- [ ] 1. 编写测试框架 `pass-test.sh`（临时 HOME、断言函数）
- [ ] 2. RED→GREEN #1：首次 insert 自动生成密钥对
- [ ] 3. RED→GREEN #2：insert + show 基本流程
- [ ] 4. RED→GREEN #3：list 显示条目
- [ ] 5. RED→GREEN #4：rm 删除
- [ ] 6. RED→GREEN #5：缺参数报错
- [ ] 7. RED→GREEN #6：已存在覆盖提示
- [ ] 8. RED→GREEN #7：help + delete 别名 + 空 list
- [ ] 9. REFACTOR：整理代码
- [ ] 10. 编写 `install.sh` 安装脚本

## 决策清单

| 决策 | 结论 |
|---|---|
| 脚本路径 | 项目目录内 `./pass`，通过 `install.sh` 安装 |
| 脚本语言 | bash |
| 测试范围 | 仅测试 pass 功能，用模拟数据，不涉及用户真实环境 |
| 不做 | 不动 .zshrc、不迁移密码、不碰用户现有配置 |
| 首次运行 | 自动生成密钥对 + 打印公钥 |
| list 格式 | 树形（调 `tree`） |
| 删除确认 | 无确认，直接删 |
| 已存在插入 | 提示 Overwrite |
| 缺参数 | 报错 + 用法提示 |
| 命名冲突 | 覆盖原版 pass |
| 测试方式 | bash 集成测试，临时 HOME 隔离 |
| 开发流程 | TDD red-green-refactor |
