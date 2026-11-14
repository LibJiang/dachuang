# AC701 smoke testbench 说明

> 目标：RTL 线提供 `smoke_top` 后，用 xsim 验证 board smoke，不验证 HQC 功能。
> 本目录只放 testbench，不放 DUT 实现。

## 约定

- `smoke_top` 端口：
  - `sys_clk_p` / `sys_clk_n`：200 MHz 差分时钟；
  - `rst`：高有效复位；
  - `led[3:0]`：LED 输出；
  - `uart_txd`：FPGA 输出；
  - `uart_rxd`：FPGA 输入，testbench 固定为 1。
- UART：**115200 8N1，空闲高电平**。
- smoke 固件/逻辑应在启动后发送 ASCII 字符串 `SMOKE_PASS`（可带 `\r\n`）。
- LED 至少变化一次，否则 testbench 报 `FAIL: no LED change`。

## 通过标准

xsim 输出：

```text
PASS: smoke UART SMOKE_PASS + LED
```

失败会输出 `FAIL: ...`，并 `$finish`。

## 运行

```powershell
# 先创建工程（需要 RTL 线提供 filelist.f 中的文件）
vivado -mode batch -source board/smoke/scripts/create_project.tcl

# 跑仿真
vivado -mode batch -source board/smoke/scripts/run_sim.tcl
```

> `tb_smoke_top.v` 会直接例化 `smoke_top`；DUT 缺失时 xsim 会报找不到模块，这是预期的，等 RTL 线交付。
