# AC701 约束说明

> 原则：**不猜引脚、不猜时钟、不照搬 PYNQ-Z2 XDC。**
> AC701 是官方 Artix-7 XC7A200T 评估板；本目录的 `ac701_smoke.xdc` 来自 **AMD/Xilinx 官方 XilinxBoardStore 的 AC701 board files**，只覆盖 smoke 所需引脚。

---

## 1. 当前文件

```text
board/smoke/constraints/ac701_smoke.xdc
```

来源：

- AMD/Xilinx 官方 `XilinxBoardStore`：
  <https://github.com/Xilinx/XilinxBoardStore/tree/2022.2/boards/Xilinx/ac701/1.4>
- 路径：`boards/Xilinx/ac701/1.4/part0_pins.xml`；
- part：`xc7a200tfbg676-2`；
- 仅提取 smoke 用到的 `SYSCLK`、`RESET`、`LED`、`RS232_UART` 引脚；
- 完整原理图/文档入口（AMD 需 JS/登录）：<https://docs.amd.com/v/u/en-US/AC701-Schematics-XTP218>；
- 完整 master XDC 在 AMD 账号/EULA 下载包 `ac701-schematic-xtp218_cluster.zip` 内，需登录 AMD 账号下载：
  <https://account.amd.com/en/forms/downloads/license-form-tip.html?cid=396443&filename=ac701-schematic-xtp218_cluster.zip&license=eula-design-license>
  （命令行无法绕过登录；拿到 zip 后把 XDC 放到本目录并合并）。

这不是完整 AC701 master XDC；如果后续需要 DDR3/HDMI/PCIe/FMC 等外设，再合并 AMD 官方 master XDC，不要在本文件里猜。

---

## 2. 已约束的引脚

| 信号 | 引脚 | IOSTANDARD | 备注 |
|:---|:---|:---|:---|
| `sys_clk_p` | R3 | LVDS_25 | 200 MHz 差分系统时钟 |
| `sys_clk_n` | P3 | LVDS_25 | 200 MHz 差分系统时钟 |
| `rst` | U4 | LVCMOS15 | 板上 RESET，**高有效** |
| `led[0]` | M26 | LVCMOS33 | 用户 LED |
| `led[1]` | T24 | LVCMOS33 | 用户 LED |
| `led[2]` | T25 | LVCMOS33 | 用户 LED |
| `led[3]` | R26 | LVCMOS33 | 用户 LED |
| `uart_txd` | T19 | LVCMOS18 | FPGA → USB-UART（完整 XDC: USB_UART_TX） |
| `uart_rxd` | U19 | LVCMOS18 | USB-UART → FPGA（完整 XDC: USB_UART_RX） |

时钟约束：`create_clock -period 5.000`（200 MHz）。

---

## 3. 完整 master XDC 核对结果（2026-11-13）

已核对下载包 `ac701-schematic-xtp218_cluster.zip`：

- 内含 `ac701-xdc-rdf0212.zip`；
- 解压得到 `AC701_Rev1_0_ucf.xdc`（45,873 bytes）；
- `readme.txt` 说明 Rev1.0 → Rev2.0 **XDC 无变化**；
- 下载包 SHA256：`8739C76E681F900923B900C9DF0EF75CF421D39CABB54650C4B9AD19B6A76D85`；
- XDC SHA256：`B773490AAA561A5D3628D486F197DF7B31BB074ACD7E9437BD7B9E04C9E9393C`；
- 关键引脚与当前 smoke XDC 一致：
  - `SYSCLK_P/N` = R3/P3，LVDS_25；
  - `CPU_RESET` = U4，LVCMOS15，高有效；
  - `GPIO_LED_0..3` = M26/T24/T25/R26，LVCMOS33；
  - `USB_UART_TX` = T19，`USB_UART_RX` = U19，LVCMOS18。

> 完整 XDC 受 AMD EULA/版权约束，未直接 vendor 进仓库；本目录只保留从官方 board file 提取的 smoke 最小约束，并用完整 XDC 核对过引脚。

---

## 4. 不要做什么

- 不要从 `build/constraints/pynq_z2_pins.xdc` 复制引脚；那是 PYNQ-Z2，不是 AC701。
- 不要根据“看起来像”的引脚号写 `PACKAGE_PIN`。
- 不要在没有原理图/官方 XDC 的情况下猜电压、时钟频率、UART/JTAG 引脚。
- 如果实验室用的是定制载板，先拿载板原理图/XDC，再写约束。

---

## 5. 如果要换成完整 master XDC

1. 从 AMD AC701 文档/board files 获取完整 master XDC；
2. 保留本文件中的 smoke 端口名，或同步修改 `smoke_top`；
3. 合并时避免重复 `PACKAGE_PIN`/`IOSTANDARD`；
4. 生成 bit 前检查 `check_timing` / `report_timing_summary` 无未约束关键路径。

---

## 6. 验收

- [x] XDC 来源可追溯（官方 board file）；
- [x] 时钟约束存在；
- [ ] 无未约束的 smoke 输入/输出（等 RTL 线端口确定后检查）；
- [ ] 综合/实现无 critical warning；
- [ ] 时序报告 WNS/WHS 入档。
