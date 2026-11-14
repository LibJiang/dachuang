# 2026-11-14 分支对齐静态检查与本机仿真入口

在仓库根目录运行以下 PowerShell 命令，复现 filelist 检查：

```powershell
$paths = Get-Content board/smoke/filelist.f | Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') }
$missing = @($paths | Where-Object { -not (Test-Path -LiteralPath $_.Trim()) })
if ($missing.Count) { $missing; throw 'Missing filelist paths' }
Write-Output "PASS: $($paths.Count)/$($paths.Count) filelist paths exist"
git diff --check
```

本轮结果：`PASS: 6/6 filelist paths exist`；`git diff --check` 无输出，退出码 0。
工程 top 为 `ac701_smoke_top`；静态核对 XDC 的 sys_clk_p/n、rst、uart_rxd/txd、led 六组端口名一致。

```powershell
.\sim\run.ps1 rtl tb_board_smoke
.\sim\run.ps1 rtl tb_smoke_axi_lite_regs
```

两条命令均退出 1，原始错误：

```text
Cannot find 'vivado'. Add it to PATH or set the VIVADO environment variable.
所在位置 E:\dachuang\dachuang\sim\run.ps1:45 字符: 5
```

新 wrapper 未编译/未综合，不能由静态检查判为功能 PASS。
