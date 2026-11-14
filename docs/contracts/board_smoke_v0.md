# board_smoke_v0 —— AC701 板级 smoke 契约（草案）

> 状态：**草案**；负责人：骆弈宾；非作者评审：江力博或房煦然。
> 目标：只验证时钟/复位、计数器/LED、UART 回显和最小 AXI4-Lite 从接口。
> 本契约不承载 HQC 算法功能，也不替代 `axi_mmio_v0.md`。

---

## 1. 模块与边界

| 模块 | 职责 | 是否接板级引脚 |
|:---|:---|:---|
| `ac701_smoke_top` | AC701 差分时钟/复位转换，实例化通用 top | 是 |
| `smoke_top` | 单时钟、计数器、LED、UART 回显 | 经板级 wrapper |
| `uart_rx` / `uart_tx` | 参数化 8N1 收发 | 仅经 `smoke_top` |
| `smoke_axi_lite_regs` | 独立的最小 AXI4-Lite 寄存器从机 | 否 |
| JTAG-to-AXI/调试桥 | 后续集成层，不在本契约实现 | 否 |

- 单时钟域；核心 RTL 使用 Verilog-2001。
- 复位统一为低有效异步 `rst_n`；复位后所有状态回到定义值。
- XDC 的管脚号、电压标准、板载时钟频率由江力博确认，本契约禁止猜测。
- 曹子墨的计数器通过明确端口接入；不得复制其未冻结的内部实现。

---

## 2. `smoke_top` 外部接口

```text
input  wire       clk
input  wire       rst_n
input  wire       uart_rx_i
output wire       uart_tx_o
output wire [3:0] led_o
```

| 参数 | V0 默认值 | 说明 |
|:---|:---|:---|
| `CLK_HZ` | `100000000` | 输入时钟频率；上板前由 XDC/板卡资料确认 |
| `BAUD` | `115200` | UART 波特率；tb 可覆盖为 `1000000` 加速仿真 |
| `COUNTER_WIDTH` | `32` | 心跳计数器位宽 |
| `LED_COUNT_BIT` | `25` | 映射到 `led_o[0]` 的计数位 |

- `led_o[0]`：计数器的可见分频位，用于确认时钟持续运行。
- `led_o[1]`：收到至少一个合法 UART 字节后置 1，复位清零。
- `led_o[2]`：UART 发送忙；`led_o[3]`：保留，固定为 0。
- 若最终板级 LED 数量不是 4，只允许在板级 wrapper 映射，不改内部语义。

---

## 3. UART 契约

- 参数：`CLK_HZ`、`BAUD`；当前默认值只服务于仿真/骨架，上板 wrapper 必须按已确认的
  时钟/XDC 显式覆盖，不能把默认值当成板卡事实。
- 帧格式：8 data bits、无校验、1 stop bit；空闲高；LSB first。
- 每收到一个合法字节，按原值回显；发送尚忙时不得覆盖待发送字节。
- V0 只允许一个字节的 pending 缓冲；连续输入导致溢出时置内部 sticky `overflow`，
  不得静默把两个字节合并。是否将该状态映射到 LED 由评审决定。
- 起始位在半 bit 处确认，数据位在 bit 中心采样；分频误差必须记录在验证报告。
- UART 输入需经过两级同步器；同步延迟不改变 8N1 字节语义。
- `uart_rx` 输出 `data_o[7:0]`、单周期 `data_valid_o` 和单周期
  `framing_error_o`；仅停止位合法时数据有效。
- `uart_tx` 输入 `data_i[7:0]`、单周期 `data_valid_i`，输出串行 `tx_o` 和
  `busy_o`；忙期间不接受新请求，由 `smoke_top` 的单字节 pending 缓冲承接。

---

## 4. `smoke_axi_lite_regs` 接口与地址图

- AXI4-Lite：32-bit data、32-bit address、单时钟、最多 1 个未完成读和 1 个未完成写。
- 复位端口为 `s_axi_aresetn`，与 `s_axi_aclk` 同域；状态输入为
  `counter_i[31:0]`、`uart_seen_i`、`uart_busy_i`、`overflow_i`。
- 必须独立接收 AW 与 W；支持任意先后次序，并正确承受 BREADY/RREADY 背压。
- `WSTRB` 按 byte lane 生效；非 32-bit 对齐或未映射访问返回 `SLVERR`。

| 偏移 | 名称 | 访问 | 复位值/语义 |
|:---|:---|:---|:---|
| `0x00` | `ID` | R | `0x534D4F4B`（ASCII `SMOK`） |
| `0x04` | `SCRATCH` | RW | `0x00000000`，按 `WSTRB` 更新 |
| `0x08` | `COUNTER` | R | 外部计数器低 32 bit 的一致性快照 |
| `0x0C` | `STATUS` | R | bit0 `uart_seen`；bit1 `uart_busy`；bit2 `overflow` |
| `0x10` | `VERSION` | R | `0x00000000`（V0） |

- 只读寄存器写入返回 `SLVERR`；保留位读 0。
- AXI 寄存器从机与 `smoke_top` 分开验证；AC701 无 PS，不能假定板上天然存在 AXI master。

---

## 5. 验证与验收

| 层级 | 用例 | 通过标准 |
|:---|:---|:---|
| xsim UART | `tb_board_smoke`：`00/55/AA/FF`、复位、超时 | 回显逐字节一致，无重复发送 |
| xsim AXI | `tb_smoke_axi_lite_regs`：AW/W 顺序、WSTRB、B/R 背压、非法地址 | 响应和寄存器值符合本契约 |
| xsim top | 计数器/LED、UART 活动、复位 | 无 X 扩散，复位值正确 |
| 板端 | LED 心跳 + 主机发送/接收 UART 字节 | 连续 100 字节 0 mismatch |

- 最终 RTL 仿真入口必须是 `bash sim/run.sh rtl <tb_top>` 或仓库内 xsim 脚本。
- 原始日志放 `data/logs/`；板端串口记录和 Vivado 报告放 `data/evidence/`。
- Icarus 只可作 lint，不得替代 xsim 验收。

---

## 6. 冻结前未决项

- [x] 已导入江分支 `7ff56af` 的时钟/复位和引脚资料，路径为
  `board/smoke/constraints/ac701_smoke.xdc`；按队友记录与官方资料核对，尚未实板验证。
- [x] AC701 wrapper 使用 `sys_clk_p/n`、高有效 `rst`、`uart_rxd/txd`、`led[3:0]`，
  通过 IBUFDS/BUFG 输入 200 MHz；内部 `CLK_HZ=200000000`、`BAUD=115200`。
- [ ] 确认 `CLK_HZ`、`BAUD` 与 UART 分频误差上限。
- [ ] 曹子墨确认计数器对外端口、位宽和可用于 LED 的分频位。
- [ ] 确认 AXI smoke 只做 xsim，还是接入选定的 JTAG-to-AXI/调试桥做板端访问。
- [ ] 确认 UART pending 溢出时 `overflow` 是否占用 `led_o[3]`。
- [ ] 至少一名非作者完成接口、地址图和验证用例评审后，状态才可改为“冻结”。

> 当前 RTL 是用户明确允许的板级平台探索性 spike；契约仍未冻结，且尚无 xsim PASS，
> 不得作为正式实现或板端验收证据。

## 7. 11-14 对齐状态

- 工程 top 为 `src/soc/ac701_smoke_top.v`；通用模块与原 tb 仍使用 §2 的接口。
- 板级 wrapper 依赖 Vivado UNISIM 原语；需要显式按 RESET 初始化，复位同步释放为两拍。
- AXI smoke 仍是独立从机单测；板端访问桥、IRQ 与 KEM MMIO 均未接入。
- 远端导入日志表明原有 RTL/tb 已通过 xvlog；xelab 生成 C 文件编译失败，尚无 xsim PASS。
  新增 wrapper 不在该次编译覆盖范围内，需重新编译。
