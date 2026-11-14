# AC701 board smoke

> 目标：只验证 **Vivado + AC701 + 下载线 + 串口** 这条板级链路，不验证 HQC 功能。
> 不是 HQC KEM，不是完整 RTL，不是 KAT。
> 当前状态：**骨架**。smoke 最小 XDC 已从官方 board file 提取；等 RTL 线提供 smoke RTL、拿到 AC701 实物后再综合/下载。

---

## 1. 分工

| 成员 | 职责 |
|:---|:---|
| 骆奕宾 | `smoke_top`、UART、AXI-Lite 寄存器读写骨架 |
| 曹子墨 | 计数器、LED、时钟/复位骨架 |
| 江力博 | Vivado 工程/约束/XDC/下载脚本/评审；不写 smoke RTL |
| 房煦然 | smoke 验收清单，收 Vivado/串口日志 |

---

## 2. 目录

```text
board/smoke/
├─ README.md                 # 本文件
├─ filelist.f                # RTL 线提供文件的清单
├─ constraints/
│  ├─ README.md              # 官方 XDC 获取说明；不猜引脚
│  └─ ac701_smoke.xdc        # smoke 最小约束
├─ tb/
│  ├─ README.md              # tb 约定
│  └─ tb_smoke_top.v         # smoke 自检 tb
└─ scripts/
   ├─ create_project.tcl     # Vivado 工程创建
   ├─ run_sim.tcl            # xsim 仿真
   ├─ build_bitstream.tcl    # synth/impl/bit
   └─ program.tcl            # bit 下载模板
```

RTL 线后续提供：

```text
board/smoke/rtl/smoke_top.v
board/smoke/rtl/smoke_counter.v
board/smoke/rtl/uart_tx.v
board/smoke/rtl/uart_rx.v
board/smoke/rtl/axi_lite_smoke.v
```

本目录**不创建**这些 RTL 文件；江力博不写 smoke Verilog。

### smoke_top 端口约定

`board/smoke/constraints/ac701_smoke.xdc` 已按官方 AC701 board file 的引脚写好，RTL 线按下面端口名连接：

| 端口 | 方向 | 引脚 | IOSTANDARD | 说明 |
|:---|:---|:---|:---|:---|
| `sys_clk_p` / `sys_clk_n` | in | R3 / P3 | LVDS_25 | 200 MHz system clock |
| `rst` | in | U4 | LVCMOS15 | 板上 RESET，**高有效** |
| `led[3:0]` | out | M26/T24/T25/R26 | LVCMOS33 | 4 个用户 LED |
| `uart_txd` | out | T19 | LVCMOS18 | FPGA → USB-UART（完整 XDC: USB_UART_TX） |
| `uart_rxd` | in | U19 | LVCMOS18 | USB-UART → FPGA（完整 XDC: USB_UART_RX） |

> 如果 RTL 线改用 `rst_n`，请在 `smoke_top` 内取反；XDC 仍按板上 `rst` 高有效约束。

---

## 3. smoke 范围

允许：

- LED 闪烁；
- 计数器运行；
- UART 输出 `SMOKE_PASS` 或回环；
- 时钟/复位正常；
- JTAG 下载 bit；
- 可选 AXI-Lite 寄存器读写。

不允许：

- SHAKE、采样、乘法、RS/RM、KEM Top；
- “先写一版 HQC 再说”；
- 把“板子亮了”说成“HQC 跑通”。

---

## 4. 通过标准

- [ ] Vivado 工程能创建；
- [ ] xsim 仿真输出 `PASS: smoke UART SMOKE_PASS + LED`；
- [ ] 综合/实现/生成 bitstream 无 error；
- [ ] JTAG 能识别 AC701；
- [ ] bit 下载成功；
- [ ] UART 输出 `SMOKE_PASS`（115200 8N1，空闲高）；
- [ ] LED/计数器可见；
- [ ] 日志存入 `data/logs/YYYY-MM-DD-board-smoke/`。

---

## 5. 前置条件

1. 拿到 AC701 实物，登记板卡编号/借用窗口；
2. `constraints/ac701_smoke.xdc` 已按官方 AC701 board file 提供 smoke 引脚；如需完整外设再合并 AMD 官方 master XDC；
3. RTL 线提供 `filelist.f` 中的 smoke RTL；
4. 确认下载线、电源、串口线；
5. 确认 Vivado 2026.1 可用。

**没有板子只做仿真/工程骨架，不下载；没有 RTL 线 smoke RTL，不综合。**

---

## 6. 使用顺序

```powershell
# 1. 创建工程（Vivado batch）
vivado -mode batch -source board/smoke/scripts/create_project.tcl

# 2. 仿真（不接板）
vivado -mode batch -source board/smoke/scripts/run_sim.tcl

# 3. 综合/实现/生成 bitstream
vivado -mode batch -source board/smoke/scripts/build_bitstream.tcl

# 4. 下载（bit 路径按实际替换）
vivado -mode batch -source board/smoke/scripts/program.tcl -tclargs build/vivado/smoke/smoke.runs/impl_1/smoke_top.bit
```

> UART 约定：115200 8N1、空闲高，发送 ASCII `SMOKE_PASS`。
> `create_project.tcl` 会在 RTL 文件缺失时直接报错，这是有意的：smoke RTL 由 RTL 线提供，江力博不代写。

---

## 7. 证据

- Vivado 工程日志、综合/实现/时序报告；
- 下载成功截图/日志；
- UART 原始输出；
- 板卡接线照片；
- 统一放 `data/logs/YYYY-MM-DD-board-smoke/`，不要只放聊天记录。
