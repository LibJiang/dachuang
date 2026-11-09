# 2026-11-09 jianglibo 初始架构窗口对账与发布

## 基本信息

- 日期：2026-11-09
- 成员：jianglibo
- 分支 / PR：`feat/hqc-fpga-asic`（PR 目标同分支；`main` 受保护）
- 关联阶段 / 任务（A/B/C/D）：P0/P1

## 本次目标

把「田静组密码方向FPGA大创初始架构」窗口里的架构结论与当前仓库逐项对账，补一篇协作纪录，并把当前分支的全部内容发布到 GitHub。

## 做了什么

- 完整读取窗口 219 条消息，提取初始架构结论：HQC-128 KEM、三步走、四人分工、SOCC 2023 原创边界、契约先行、稀疏乘法 baseline；
- 对账窗口 → 仓库，确认当前主线已从「PS+PL 混合、仿真优先」演进为「完整 RTL HQC-128 KEM + FPGA/ASIC」；
- 核对 `docs/08`、`docs/09`、`docs/10`、`docs/11`、`docs/12`、`docs/13`、`docs/14`、`docs/workflow.md` 与 `docs/contracts/`；
- 核对官方 HQC 参考实现与 KAT harness：`third_party/hqc/`、`models/kem/harness/`；
- 核对板卡与流程结论：`board/README.md`、`build/constraints/`、`skill/`、`AGENTS.md`；
- 新增本记录，更新 `docs/records/README.md` 索引；
- 将本次文档提交并推送到 `origin/feat/hqc-fpga-asic`。

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

## 验证证据

- 仓库状态：
  - 命令：`git status -sb`
  - 结果：`## feat/hqc-fpga-asic...origin/feat/hqc-fpga-asic`（无 ahead/behind）
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
- Markdown 链接检查：
  - 命令：仓库内 Python 链接脚本
  - 结果：`missing=0`
- 产物 / 链接：
  - 仓库：<https://github.com/LibJiang/dachuang>
  - 生成物 `build/offline/大创新手教程.html` 不入库。

## 问题与解决

- 现象：窗口里的初始架构是「PS+PL 混合、仿真优先」，当前仓库主线却是「完整 RTL + FPGA/ASIC」。
- 定位：窗口之后，老师确认「FPGA 全功能跑通是硬目标、ASIC 只做 55/28/90nm 综合、不流片」，且组内 SOCC 2023 已做 FPGA 完整 KEM，混合架构撑不起国家级增量。
- 解决：以当前仓库最新文档为唯一口径，把窗口结论标为历史基线；差异写入本记录，避免新旧文档互相打架。
- 现象：`hqc-baseline` 分支保存了 N=17669 稀疏乘法折叠，但未并回集成分支。
- 定位：主题切换时按流程保留旧实现，避免覆盖；当前主线先做完整 RTL。
- 解决：记录为待办，单独评审后再决定是否合并；不做 force push、不删除旧分支。
- 现象：官方 KAT 目前只验证到 `pk/sk/ss` 100/100，`encaps` 的 `ct` 字节级一致尚未验证。
- 定位：完整 `test_kat.c` 依赖 OpenSSL/NIST DRBG；现有 `kat_check.c` 用 KAT 的 `sk` 复现 keygen/decaps。
- 解决：在待办中明确标注「encaps ct 未验证」，不写成 100/100 全通过。
- 耗时：约 30 分钟。

## 关键决策与理解

- **当前架构**：完整 RTL HQC-128 KEM（SHAKE/采样/RS/RM/稀疏乘法/控制），FPGA AC701 XC7A200T 是硬目标，ASIC 55/28/90nm 综合是条件阶段。
- **窗口定位**：窗口的混合架构不再作为主线，只保留为历史与回退参考；当前文档以 `docs/12`、`docs/13`、`docs/14` 为准。
- **原创边界**：组内 SOCC 2023 已做稀疏乘法、FHT、ePIBM、完整 FPGA KEM，四项不得当原创；增量在 ASIC 多工艺、FPGA/ASIC 设计空间、参数化/开源可复现。
- **流程**：没有冻结契约不写实现代码；单步 ≤100 行；纯文档/记录提交可豁免理解门槛。
- **发布口径**：只推 `feat/hqc-fpga-asic`，不直接 push `main`；功能线后续按 PR 合入。

## 未完成 / 待办

- [ ] `hqc-baseline` 分支是否合并（未决定）
- [ ] `encaps` 的 `ct` 字节级 KAT（未验证）
- [ ] 冻结 `hqc_kem_v0`、`sparse_qc_mult_v0`、`rm_decoder_v0`、`axi_mmio_v0`（草案）
- [ ] 新建并冻结 `sha3_v0`、`sampler_v0`、`rs_codec_v0`（未建）
- [ ] 完整 RTL 模块：SHAKE/采样/RS/RM/KEM Top（未实现）
- [ ] FPGA 板端 KeyGen/Encap/Decap + KAT 100/100（未验证）
- [ ] ASIC 工具确认（DC/Genus/OpenROAD，未确认）
- [ ] 达到里程碑后向 `main` 提 PR（未开始）

## 可提炼经验

- 窗口里的架构结论会随导师约束和查新结果变化；对账时以仓库最新文档为准，并把历史决策写清楚，避免新旧文档互相打架。
- 发布前固定跑五件事：`git status -sb`、链接检查、离线文档构建、KAT、C/RTL 回归；几分钟就能发现大部分不一致。
- 主题切换时把旧方案留在独立分支，比直接覆盖安全；是否合并单独评审，不做 force push。
- KAT 的「100/100」必须写清验证范围（这里是 pk/sk/ss），不能默认 encaps ct 也过了。

## 参考

- 窗口：田静组密码方向FPGA大创初始架构（219 条消息）
- `docs/08_HQC技术路线.md`、`docs/09_工程约束与验证规范.md`
- `docs/10_团队分工与国家级指标.md`、`docs/11_组内基线与差异表.md`
- `docs/12_FPGA_ASIC路线.md`、`docs/13_开工清单与近期任务.md`、`docs/14_总体工作计划.md`
- `docs/workflow.md`、`docs/contracts/README.md`
- `docs/records/2026-11-06-jianglibo-hqc-kat-and-topic-switch.md`
- `docs/records/2026-11-06-jianglibo-teacher-constraints-and-plan-sync.md`
- `docs/records/2026-11-09-jianglibo-gufa-contract-workflow.md`
- `docs/records/2026-11-09-jianglibo-board-selection.md`
- Chen Li et al., “An Efficient Hardware Design for Fast Implementation of HQC,” SOCC 2023, DOI `10.1109/SOCC58585.2023.10257054`
- 官方 HQC：<https://gitlab.com/pqc-hqc/hqc/>，commit `06567cc`
- 仓库：<https://github.com/LibJiang/dachuang>
