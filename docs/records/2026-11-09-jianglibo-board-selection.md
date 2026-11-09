# 2026-11-09 jianglibo 板卡选型

## 基本信息

- 日期：2026-11-09
- 成员：jianglibo
- 分支：`feat/hqc-fpga-asic`
- 关联阶段：P0/P3

## 决策

| 优先级 | 板卡 | 用途 |
|:---|:---|:---|
| 主 | **AC701 Artix-7 XC7A200T（苏州）** | 完整 RTL、板端 KAT、PPA、192/256 |
| 备 | **小梅哥 XC7A100T（苏州）** | 早期 smoke、并行 bring-up、备份 |
| 备用 200T | **小梅哥 XC7A200T（常州-曹元老师处）** | AC701 被占用时 |
| 侧信道 | **CW305（苏州）** | C 阶段，不是主开发板 |

**V0 不用**：Alveo V80、Versal VPK180、VC709、PGL50H。

## 理由

- 论文基线是 Artix-7 XC7A200T；同档资源最稳；
- AC701 在苏州、官方套件、Vivado 资料全；
- 100T 能放 HQC-128，作为 early bring-up/备份；
- Alveo/Versal/VC709 资源过剩、工具链复杂；PGL50H 是 Pango 工具链。

## 时间安排

- P0：借 1–2 天做 smoke（时钟/复位/LED/UART/JTAG），预约 P3 窗口；
- P1–P2：以仿真为主，板子不占主线；
- P3：连续 4–6 周，完整 RTL 上板 + 板端 KAT + PPA。

## 待办

- [ ] AC701 官方 master XDC / 原理图 / 用户手册
- [ ] `build/constraints/ac701_pins.xdc`
- [ ] UART/JTAG 主机脚本
- [ ] 板卡借用登记

## 风险

- AC701 可能被其他项目占用 → 备选 100T / 常州 200T；
- Artix-7 无 ARM PS → 板端 KAT 走 UART/JTAG/AXI，不照搬 PYNQ overlay；
- 目标频率先按 100–125 MHz，不承诺 178 MHz。

## 参考

- `board/README.md`
- `build/constraints/README.md`
- `docs/12_FPGA_ASIC路线.md`
