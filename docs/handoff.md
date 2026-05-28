# Handoff: age-pass

## What Happened

继续开发 age-pass 密码管理器。安装了依赖（age, tree），编写了测试框架和 pass 脚本，完成了 6/7 个 RED→GREEN 循环。

## What's Done

- [x] 安装依赖：`pkg install age tree`
- [x] 测试框架 `pass-test.sh`（临时 HOME、断言函数、run_pass 封装）
- [x] RED→GREEN #1：首次 insert 自动生成密钥对
- [x] RED→GREEN #2：insert + show 基本流程（多条目）
- [x] RED→GREEN #3：list 显示条目（用 tree + sed 去 .age 后缀）
- [x] RED→GREEN #4：rm 删除条目（含 delete 别名）
- [x] RED→GREEN #5：缺参数报错（show/insert/rm 无参数 → stderr usage + exit 1）
- [x] RED→GREEN #6 测试已写：覆盖提示（已存在条目 → Overwrite? [y/N]）
- [x] pass 脚本已实现 insert/show/list/rm/delete/help

## What's Blocked

**RED→GREEN #6 测试失败** — "insert existing entry prompts overwrite" 测试报错：

```
FAIL: expected exit code 0, got 1
stderr: Usage: pass [show|insert|list|rm|delete|help] [name]
```

但手动运行 `echo "first" | bash pass insert dup-key && printf "y\nsecond\n" | bash pass insert dup-key` 完全正常。

**疑似原因**：`run_pass()` 函数的 `PASS_EXIT` 变量在 `assert_exit_code` 内部被意外修改。trace 显示 `PASS_EXIT=0` 被设置，但 `assert_exit_code` 读到的是 1。

尝试过的修复：
- `&& PASS_EXIT=$? || PASS_EXIT=$?` → 不行
- `set +u` / `set -u` 包裹 → 不行
- `PASS_EXIT=0; bash ... || PASS_EXIT=$?` → 不行

**可能方向**：重写 `run_pass()` 用子 shell 或临时文件保存退出码，避免全局变量被污染。

## Files

- `~/projects/age-pass/pass` — 主脚本（已实现 insert/show/list/rm/delete/help）
- `~/projects/age-pass/pass-test.sh` — 测试脚本（7 个测试，6 通过 1 失败）
- `~/projects/age-pass/pass-plan.md` — 完整计划
- `~/projects/age-pass/handoff.md` — 本文件

## Next Steps

1. **修复 run_pass() 的 PASS_EXIT 污染问题**，让测试 #7 通过
2. RED→GREEN #7：help + delete 别名 + 空 list
3. REFACTOR：整理代码
4. 编写 `install.sh` 安装脚本

## Skills to Use

- `tdd` — red-green-refactor 流程
- `karpathy-guidelines` — 避免过度设计

## Environment

- Termux on Android
- age 1.3.1 已安装
- tree 2.3.2 已安装
- 项目目录：`~/projects/age-pass/`
