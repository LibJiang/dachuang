# 板级与 FPGA 全功能跑通

> 主开发板：**Artix-7 XC7A200T（苏州 AC701 评估套件）**。
> 备选：**小梅哥 Artix-7 XC7A100T（苏州 5F-17）**；备用 200T：**小梅哥 XC7A200T（常州-曹元老师处）**。
> 侧信道后续：**ChipWhisperer CW305（苏州 3F-18）**。
> **老师已确认：不用流片；FPGA 全功能跑通是硬目标。**
> 当前状态：**未开始**；P0 先借 1–2 天做 smoke test，P3 连续借用 4–6 周。
> **板级 smoke 入口：[board/smoke/README.md](smoke/README.md)**；smoke RTL 由 RTL 线写，江力博只做 Vivado 工程/约束/XDC/下载/评审。

---

## 为什么选 AC701 200T

- 和组内 SOCC 2023 论文同档 **XC7A200T**（论文：19,794 LUT / 11,079 FF / 68 BRAM / 178 MHz）；
- 200T 资源足够 HQC-128，并给 HQC-192/256 留余量；
- 苏州本地、官方评估套件、Vivado 支持好、资料全；
- 100T 作为早期 bring-up / 备份（HQC-128 也放得下），200T 作为正式全功能跑通板。

## 板卡分工

| 板卡 | 用途 |
|:---|:---|
| **AC701 XC7A200T（苏州）** | 正式主开发板：完整 RTL、板端 KAT、PPA、192/256 |
| **小梅哥 XC7A100T（苏州，3 块）** | 早期 smoke、并行 bring-up、备份 |
| **小梅哥 XC7A200T（常州）** | AC701 被占用时的 200T 备用 |
| **CW305（苏州）** | 侧信道/恒定时间（C 阶段，不是主开发板） |

**V0 不使用**：Alveo V80、Versal VPK180、VC709、PGL50H（资源过剩/工具链复杂/Pango 非 Vivado）。

---

## 目标

1. 板端 KeyGen / Encaps / Decaps 全功能跑通；
2. 板端 KAT **100/100**；
3. 记录 LUT/FF/BRAM/Fmax/cycles 与延迟；
4. 生成 bitstream + 可复现脚本。

## 主机接口（Artix-7 无 ARM PS）

- 不照搬 PYNQ overlay；
- 用 **UART / JTAG-to-AXI / AXI-Lite + BRAM** 做 KAT 灌数与读回；
- 上位机用 Python/C 脚本；
- 具体接口在 `docs/contracts/axi_mmio_v0.md` 冻结。

## 借用与 bring-up 时间表

| 阶段 | 板子 | 目的 |
|:---|:---|:---|
| P0（2026-11） | 借 1–2 天 | smoke：时钟、复位、LED、UART、JTAG；确认 XDC/手册 |
| P1–P2（2026-12 ~ 2027-03） | 以仿真为主 | RTL/系统仿真/KAT 在 xsim 完成；板子只偶尔 smoke |
| P3（2027-03 ~ 2027-04） | 连续 4–6 周 | 完整 RTL 上板、板端 KAT、PPA、调试 |
| P4（2027-05） | 按需 | ASIC 综合/答辩/演示 |

## 约束

- **引脚约束不得猜**：AC701 用官方 master XDC；`build/constraints/pynq_z2_pins.xdc` 只作 PYNQ-Z2 备用，不用于 AC701。
- 目标频率先按 **100–125 MHz**，不承诺 178 MHz（速度等级/板级不同）。
- 上板前确认电压/时钟；不要热插拔。
- 不要把私钥、种子、KAT 明文密钥提交到仓库或贴在截图里。

## 待补

- [x] AC701 smoke 最小 XDC（官方 board file 提取：`board/smoke/constraints/ac701_smoke.xdc`）
- [ ] AC701 完整 master XDC / 原理图 / 用户手册（如需 DDR/HDMI/FMC 等外设）
- [ ] 板卡借用登记（AC701 P3 窗口）
- [ ] UART/JTAG 主机脚本
- [ ] 时钟频率与引脚
- [ ] 板端 KAT 流程
