# board smoke 平台 spike 最终检查记录

日期：2026-11-13；分支：`feat/sha3-luoyibin`。

## 交付入口

```powershell
.\sim\run.ps1 rtl tb_board_smoke
.\sim\run.ps1 rtl tb_smoke_axi_lite_regs
.\sim\run.ps1 lint tb_board_smoke
.\sim\run.ps1 lint tb_smoke_axi_lite_regs
```

## 原始结果

四条命令均退出 1：xsim 两条提示找不到 `vivado`，lint 两条提示找不到 `iverilog`。

```text
Cannot find 'vivado'. Add it to PATH or set the VIVADO environment variable.
Cannot find 'iverilog'. Add it to PATH or set the VIVADO environment variable.
```

因此当前结果为**代码与自检 tb 已交付，但未编译、未仿真、未上板**，不得写成 PASS。

另检查 `wsl bash -lc "command -v iverilog"`，退出码 1；本机未安装/启用 WSL，
因此无法从 WSL 补跑 Icarus。

## 已完成的静态检查

- `git diff --check`：退出码 0。
- `src/board/`、两个 smoke tb 与 `board_smoke_v0.md` 尾随空格扫描：无匹配。
- RTL 使用 Verilog-2001 端口/时序块；未使用 `logic`、`always_ff`、`always_comb` 或 `.*`。
