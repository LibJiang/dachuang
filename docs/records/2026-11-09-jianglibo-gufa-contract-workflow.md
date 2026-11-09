# 2026-11-09 jianglibo 古法编程与契约冻结流程

## 基本信息

- 日期：2026-11-09
- 成员：jianglibo
- 分支：`feat/hqc-fpga-asic`
- 关联阶段：P0/P1

## 本次目标

把“古法编程 + 契约先行”变成硬性流程，适用于 RTL 和全部代码线，而不是只写在口头上。

## 做了什么

- 新增 `skill/gufa-programming/SKILL.md`；
- 新增 `skill/understand-gate/SKILL.md`；
- 新增 `skill/contract-freeze-workflow/SKILL.md`；
- 新增 `.opencode/skill/` 三个自动触发包装；
- 新增 `docs/workflow.md`（开工三件事、契约冻结、古法编程、理解门槛、分支/PR、验证、代码风格、Bug 修复）；
- 新增 `docs/contracts/TEMPLATE.md`；
- 更新 `docs/contracts/README.md`、`skill/README.md`；
- 更新 `AGENTS.md`：契约未冻结不许写代码；单步 ≤100 行；commit 前 3 题；
- 更新 `docs/09`、`docs/13`、`docs/14`、`README.md`、`docs/00`；
- 新增本记录。

## 验证证据

- Markdown 链接检查：`missing=0`；
- 离线文档：`node tools/build-offline-docs.mjs` 通过；
- 本次为文档/流程改动，无 RTL 代码。

## 关键决策

- **没有冻结契约，不许写任何实现代码**（RTL、C/C++、Python、Tcl、脚本）。
- **古法编程**：先拆步；单步 ≤100 行；每步自检 + 讲解 + 2–3 题；用户回答后才继续。
- **理解门槛**：commit 前逐段讲解 + 3 题；用户确认后才提交。
- **契约变更三处同步**：RTL、tb/系统仿真、C 黄金/KAT/脚本、契约。
- 纯文档/记录类改动可豁免。

## 未完成 / 待办

- [ ] 冻结 `hqc_kem_v0`、`sparse_qc_mult_v0`、`rm_decoder_v0`、`axi_mmio_v0`
- [ ] 新建并冻结 `sha3_v0`、`sampler_v0`、`rs_codec_v0`
- [ ] RTL 开工前逐项确认契约状态

## 参考

- `docs/workflow.md`
- `skill/gufa-programming/SKILL.md`
- `skill/understand-gate/SKILL.md`
- `skill/contract-freeze-workflow/SKILL.md`
