# board smoke 第 1 步原始检查记录

日期：2026-11-13；分支：`feat/sha3-luoyibin`。

## xsim

命令：`./sim/run.ps1 rtl tb_board_smoke`

退出码：1。

```text
Cannot find 'vivado'. Add it to PATH or set the VIVADO environment variable.
所在位置 E:\dachuang\dachuang\sim\run.ps1:45 字符: 5
```

结论：未进入 HDL 编译，不能据此证明 `smoke_top` 缺失负例成立。

## Icarus lint

命令：`./sim/run.ps1 lint tb_board_smoke`

退出码：1。

```text
Cannot find 'iverilog'. Add it to PATH or set the VIVADO environment variable.
所在位置 E:\dachuang\dachuang\sim\run.ps1:45 字符: 5
```

结论：当前 PowerShell 环境同时找不到 Vivado 和 Icarus；本步为**未验证**，不是测试 FAIL/PASS。
