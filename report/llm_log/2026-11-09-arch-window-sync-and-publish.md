# 2026-11-09 初始架构窗口对账与发布

## 任务

读取大创仓库与「田静组密码方向FPGA大创初始架构」opencode 窗口，按仓库模板整理协作记录，并把内容发布到 GitHub 的 `feat/sys-jianglibo` 分支、`report/llm_log/`。

## 输入

- 窗口：田静组密码方向FPGA大创初始架构（219 条消息）
- `docs/08_HQC技术路线.md`、`docs/09_工程约束与验证规范.md`
- `docs/10_团队分工与国家级指标.md`、`docs/11_组内基线与差异表.md`
- `docs/12_FPGA_ASIC路线.md`、`docs/13_开工清单与近期任务.md`、`docs/14_总体工作计划.md`
- `docs/workflow.md`、`docs/contracts/README.md`
- `third_party/hqc/`、`models/kem/harness/`
- `docs/records/2026-11-06-jianglibo-hqc-kat-and-topic-switch.md`
- `docs/records/2026-11-06-jianglibo-teacher-constraints-and-plan-sync.md`
- `docs/records/2026-11-09-jianglibo-gufa-contract-workflow.md`
- `docs/records/2026-11-09-jianglibo-board-selection.md`

## 决策

- **以仓库最新文档为准**：窗口里的初始架构是「PS+PL 混合、仿真优先」；当前主线已演进为「完整 RTL HQC-128 KEM + FPGA/ASIC」。
- **窗口结论只作历史基线**：不能覆盖 `docs/12`、`docs/13`、`docs/14` 的最新结论。
- **原创边界不变**：组内 SOCC 2023 已做稀疏乘法、FHT、ePIBM、完整 FPGA KEM，四项不得当原创；增量在 ASIC 多工艺、FPGA/ASIC 设计空间、参数化/开源可复现。
- **记录位置**：按用户要求放 `report/llm_log/`，不放在 `docs/records/`；此前误放到 `docs/records` 的提交已在 `feat/hqc-fpga-asic` 上用新提交撤回（未 force push）。
- **分支**：只推 `feat/sys-jianglibo`；`main` 受保护，不直接 push。

### 窗口结论 → 仓库落点

| 窗口结论 | 仓库落点 | 当前状态 |
|:---|:---|:---|
| 方向：HQC-128 KEM 硬件加速 | `docs/08`、`plan.md` | 已落库 |
| 三步走 A/B/C | `docs/08`、`docs/12`、`README.md` | 已演进为 M0–M7 |
| 四人分工 A/B/C/D | `docs/10`、`docs/12` §4 | 已按老师约束调整 |
| SOCC 2023 四项不能当原创 | `docs/11` | 已落库 |
| 接口契约先行 | `docs/contracts/` | 草案，未冻结 |
| 稀疏乘法 baseline | `src/mult/`、`sim/tb_sparse_qc_mult*.v` | N=64 通过；N=17669 折叠在 `hqc-baseline` |
| 官方参考实现 + KAT | `third_party/hqc/`、`models/kem/harness/` | KAT 100/100（pk/sk/ss） |
| FPGA/ASIC 路线 | `docs/12`、`docs/14` | FPGA 硬目标；ASIC 条件 |
| 板卡选型 | `docs/12`、`board/README.md` | AC701 XC7A200T 主 |
| 古法编程 + 契约冻结 | `docs/workflow.md`、`skill/` | 已硬性化 |

## 理解门槛

能讲清：

- HQC-128 KEM 的 KeyGen / Encaps / Decaps 数据流，以及 Decaps 重加密与隐式拒绝；
- 稀疏乘法 `a·b = ⊕_{p∈supp(b)} (a <<< p) mod (X^n−1)`，为什么复杂度从 $O(n^2)$ 降到 $O(wn)$；
- 为什么 SOCC 2023 的稀疏乘法/FHT/ePIBM/完整 FPGA KEM 不能当原创；
- 为什么从「PS+PL 混合」切到「完整 RTL + FPGA/ASIC」；
- FPGA 硬目标与 ASIC 只做 55/28/90nm 综合、不流片的边界。

暂不能讲清 / 需要补：

- `encaps` 的 `ct` 字节级 KAT（当前只验证 pk/sk/ss）；
- ASIC 工具链（DC/Genus/OpenROAD）与 PDK 细节；
- 各模块契约冻结后的最终位宽/时序。

## 验证

- 官方 KAT：
  - 命令：`bash models/kem/harness/run.sh`
  - 结果：`PASS: 100/100 vectors (pk/sk/ss)`
- C/C++ 黄金：
  - 命令：`powershell -NoProfile -ExecutionPolicy Bypass -File sim/run.ps1 sw`
  - 结果：`PASS: 5/5 checks`
- RTL 仿真：
  - 命令：`powershell -NoProfile -ExecutionPolicy Bypass -File sim/run.ps1 rtl tb_sparse_qc_mult`
  - 结果：`PASS: 4/4 checks`，`XSIM_DONE: tb_sparse_qc_mult`
- 离线文档：
  - 命令：`node tools/build-offline-docs.mjs`
  - 结果：`26 篇文档, 300.8 KB`
- Markdown 链接检查：`missing=0`
- 分支状态：`## feat/sys-jianglibo...origin/feat/sys-jianglibo`

## 未完成 / 风险

- [ ] `hqc-baseline` 分支是否合并（未决定）
- [ ] `encaps` 的 `ct` 字节级 KAT（未验证）
- [ ] 冻结 `hqc_kem_v0`、`sparse_qc_mult_v0`、`rm_decoder_v0`、`axi_mmio_v0`（草案）
- [ ] 新建并冻结 `sha3_v0`、`sampler_v0`、`rs_codec_v0`（未建）
- [ ] 完整 RTL 模块：SHAKE/采样/RS/RM/KEM Top（未实现）
- [ ] FPGA 板端 KeyGen/Encap/Decap + KAT 100/100（未验证）
- [ ] ASIC 工具确认（DC/Genus/OpenROAD，未确认）
- [ ] 历史风险：`759457b` 曾把本记录误推到 `feat/hqc-fpga-asic`，已用 `d198e4f` 撤回；如需彻底抹除历史需 force push（未授权，不做）

## 参考

- <https://github.com/LibJiang/dachuang>
- <https://github.com/LibJiang/dachuang/tree/feat/sys-jianglibo>
- Chen Li et al., “An Efficient Hardware Design for Fast Implementation of HQC,” SOCC 2023, DOI `10.1109/SOCC58585.2023.10257054`
- 官方 HQC：<https://gitlab.com/pqc-hqc/hqc/>，commit `06567cc`
