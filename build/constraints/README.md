# 约束文件说明

> 本目录只放**手写、可评审**的约束。生成物（Vivado 自动生成的 XDC、报告）不入库。
> 目标板：PYNQ-Z2（Zynq-7020，`xc7z020clg400-1`）。

---

## 文件

| 文件 | 内容 | 状态 |
|:---|:---|:---|
| `timing.xdc` | 板载 125 MHz 主时钟、时钟不确定性、I/O 延迟占位 | 草案 |
| `pynq_z2_pins.xdc` | `clk` / `led[3:0]` / `btn0` 引脚 | 已按官方 master XDC 子集填写 |

引脚来源：官方 PYNQ-Z2 Master XDC v1.0
（成员 `PYNQ-Z2 v1.0.xdc`，SHA256 `07441e999bac956c77e78091c782cade278efc5a78affc51e5b12b4800b1fe73`）。
**其它引脚（HDMI、PMOD、UART、PS AXI）按需从 master XDC 追加，禁止猜。**
**不要同时加入官方 master XDC 和 `pynq_z2_pins.xdc`**，否则引脚/时钟会重复定义。

---

## 硬规则

1. **引脚约束不得猜**：只能来自官方 master XDC 或原理图；写错引脚可能损坏板卡。
2. **时序例外必须写理由**：每个 `set_false_path` / `set_multicycle_path` 必须有注释：为什么、谁评审、对应哪个 CDC/接口。
3. **禁止通配符豁免**：不允许 `set_false_path -from [all_clocks]` 之类“一键消时序”。
4. **每个里程碑归档时序报告**：`report_timing_summary` 输出放 `data/evidence/YYYY-MM-DD-<主题>/`。
5. **WNS/WHS 必须记录**：仿真、综合、实现、上板分开写，不得混用。

---

## V0 时序目标

| 时钟 | 频率 | 周期 | 说明 |
|:---|:---|:---|:---|
| 板载 `clk` | 125 MHz | 8.000 ns | PYNQ-Z2 H16 |
| 加速器时钟 | 125 MHz 或 MMCM 生成 | 按实际 | 不收敛先降频保功能 |

- 若用 MMCM 生成 100 MHz，注释 `timing.xdc` 的 `create_clock`，改用 `create_generated_clock`。
- 若 125 MHz 不收敛，先降频保功能，再优化关键路径；不得用 false path 掩盖真实违例。

---

## 使用方式

1. Vivado 工程加入 `timing.xdc` 与 `pynq_z2_pins.xdc`；
2. 顶层必须有 `clk`、`led[3:0]`、`btn0` 端口（否则引脚约束会报错）；
3. 综合/实现后跑：
   ```tcl
   report_timing_summary -file data/evidence/<日期>-<主题>/timing_summary.rpt
   report_utilization   -file data/evidence/<日期>-<主题>/utilization.rpt
   ```
4. 在协作纪录里链接报告路径，并写清 WNS/WHS、LUT/FF/BRAM/DSP。

---

## 待补信息

- [ ] PS-PL 接口（`M_AXI_GP0` / `S_AXI_HP0` / DMA）的时钟与位宽
- [ ] 是否使用 MMCM 生成 100 MHz，还是直接 125 MHz
- [ ] UART / PMOD / 其它调试引脚（按需追加）
