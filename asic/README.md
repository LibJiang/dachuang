# ASIC 综合评估（条件阶段）

> 目标：对 HQC KEM 的完整 RTL 做 **综合 + area/power/fmax 评估**。
> **老师已确认：不流片；不跑 P&R、DRC/LVS。**
> PDK：**55nm 主 / 28nm 对比 / 90nm 兜底**。
> 状态：**未开始**，取决于实验室 ASIC 工具是否可用（假设至少一种）。

---

## 前置条件

- [ ] 确认 ASIC 工具：Cadence Genus / Synopsys DC / OpenROAD；
- [x] PDK：55nm 主 / 28nm 对比 / 90nm 兜底（老师确认有 28/90/55nm）；
- [ ] 确认标准单元库与时序库（`.lib` / `.db`）；
- [ ] 有人能带流程（师兄/老师）；
- [ ] 核心 RTL 已通过 FPGA 综合与 KAT。

---

## 目录规划

```text
asic/
├─ README.md
├─ scripts/
│  ├─ synth_55.tcl       # 55nm 主
│  ├─ synth_28.tcl       # 28nm 对比
│  ├─ synth_90.tcl       # 90nm 兜底
│  └─ report.tcl         # area/power/timing 报告
├─ constraints/
│  └─ hqc_top.sdc        # ASIC 时钟/IO 约束（与 FPGA XDC 分开）
└─ README.md
```

报告放 `data/evidence/YYYY-MM-DD-asic-synth/`，不要把生成物入库。

---

## 指标

| 指标 | 说明 |
|:---|:---|
| Area | 标准单元面积 / gate count |
| Power | 动态/静态功耗（综合估计） |
| Fmax | 综合后时序估计 |
| Energy/op | 每次 KeyGen/Encap/Decap 的能量 |
| Comparison | 55/28/90nm 三节点 + FPGA PPA + SOCC 2023 |

---

## 风险

- 没有工具 → **不做**，只写“ASIC-oriented RTL + FPGA PPA”；
- 团队无经验 → 只做综合评估，不碰 P&R；
- 时间不够 → ASIC 作为加分项，不影响 FPGA 全功能跑通；
- 工艺差异 → 报告必须写清工艺节点/库版本，不能和 FPGA 数字直接比。
