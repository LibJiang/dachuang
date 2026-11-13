# board smoke 第 2 步原始检查记录

日期：2026-11-13；分支：`feat/sha3-luoyibin`。

## Icarus lint

命令：`./sim/run.ps1 lint uart_rx`

退出码：1。

```text
Cannot find 'iverilog'. Add it to PATH or set the VIVADO environment variable.
所在位置 E:\dachuang\dachuang\sim\run.ps1:45 字符: 5
```

结论：当前 PowerShell 环境找不到 Icarus，未进入 HDL 编译；`uart_rx.v` 为**未验证**。

## 静态检查

- `uart_rx.v`：110 个物理行、98 个非空代码行。
- 两个 `always` 块、一个 `case/endcase`、一个 `module/endmodule` 结构配对。
- `git diff --check`：退出码 0。
- `uart_rx.v` 与 `tb_board_smoke.v` 尾随空格扫描：无匹配。
