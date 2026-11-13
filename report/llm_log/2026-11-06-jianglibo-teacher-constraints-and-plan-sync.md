# 2026-11-06 jianglibo 老师约束与计划同步

## 基本信息

- 日期：2026-11-06
- 成员：jianglibo
- 分支：`feat/hqc-fpga-asic`
- 关联阶段：P0 启动/基线

## 本次目标

根据与周老师确认的四点约束，修正仓库中“FPGA 可选/ASIC 并列”的不合理表述：

1. **不用流片**；
2. **FPGA 全功能跑通是硬目标**；
3. 实验室有 **28/90/55nm PDK**；
4. 工具暂未确认，但假设至少一种可用。

## 做了什么

- 更新 `README.md`：FPGA 硬目标、ASIC 55/28/90nm、分工、原创性；
- 更新 `plan.md`：目标、边界、指标、M6/M7、风险、分工；
- 更新 `docs/12`、`docs/14`：FPGA 全功能跑通 + PPA、ASIC 三节点、排期；
- 更新 `docs/10`、`docs/13`：江力博聚焦 FPGA/Vivado/系统；房煦然接 KAT/C 黄金/验证；
- 更新 `docs/09`、`docs/08`、`docs/11`：验证闸门、原创性边界；
- 更新 `board/README.md`、`asic/README.md`、`AGENTS.md`、`docs/contracts/hqc_kem_v0.md`、`docs/00`。

## 验证证据

- Markdown 链接检查：`missing=0`；
- 离线文档：`node tools/build-offline-docs.mjs` 通过；
- `git diff --check`：仅 CRLF 提示，无空白错误。

## 关键决策

- **FPGA 全功能跑通 = 硬目标**，不是可选加分；
- **ASIC 前端综合 + area/power/fmax 必做**；后端 P&R/STA 可选，不流片；
- **ASIC 主节点 55nm**，28nm 对比，90nm 兜底；
- **分工调整**：江力博 FPGA/Vivado/系统；房煦然 KAT/C 黄金/验证/需求验收；骆/曹 RTL；
- **原创性**：FPGA 全跑通是硬目标但 SOCC 2023 已做；国家级增量靠 ASIC 多工艺 + 设计空间 + 参数化/开源。

## 未完成 / 待办

- [ ] 确认 ASIC 工具（DC/Genus/OpenROAD）
- [ ] 确认 FPGA 板卡（PYNQ-Z2 / 实验室板卡）
- [ ] 完整 RTL 模块
- [ ] FPGA 板端全功能跑通
- [ ] ASIC 55/28/90nm 综合

## 风险

- 板卡未定 + FPGA bring-up 时间长；
- 只有一台 Vivado；
- 团队无 ASIC 经验；
- 国家级原创性仍需差异表支撑。

## 参考

- `docs/12_FPGA_ASIC路线.md`
- `docs/14_总体工作计划.md`
- `docs/11_组内基线与差异表.md`
