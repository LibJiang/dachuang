# 2026-11-06 jianglibo HQC 初始架构与仓库基线

## 基本信息

- 日期：2026-11-06
- 成员：jianglibo
- 分支 / PR：`main`（本次提交）
- 关联阶段 / 任务（A/B/C/D）：立项启动，A/B/C/D 全线

## 本次目标

读完田静组 SOCC 2023 HQC 硬件论文后，把大创从「参考 FPGA 竞赛仓库」落成「HQC-128 KEM 硬件加速」的初始架构、工程约束、四人分工和可复现基线。

## 做了什么

- 重写 `README.md`：项目定位、系统架构、三步走（A 软件基线 → B 单点加速 → C 系统扩展）、国家级指标、原创边界；
- 新增 `plan.md`：功能边界、阶段硬闸门、里程碑 M0–M7、接口契约、风险与取舍；
- 新增 `docs/08_HQC技术路线.md`：HQC 流程、瓶颈、稀疏乘法原理、V0 混合架构与模块清单；
- 新增 `docs/09_工程约束与验证规范.md`：Verilog-2001、latch/复位/位宽红线、证据口径；
- 新增 `docs/10_团队分工与国家级指标.md`：A 算法、B 稀疏乘法、C FHT/KEM、D 验证四人分工与周节奏；
- 新增 `docs/11_组内基线与差异表.md`：逐项列出 SOCC 2023 已做内容、不能当原创的点、推荐增量；
- 新增 `docs/contracts/`：`hqc_kem_v0.md`、`sparse_qc_mult_v0.md`、`rm_decoder_v0.md`、`axi_mmio_v0.md`；
- 新增 `AGENTS.md`：开工三件事、目录边界、可复现性、交付纪律、HQC 专项红线；
- 新增 `src/mult/sparse_qc_mult.v` 与 `sim/tb_sparse_qc_mult.v`：单路 64-bit 稀疏乘法 baseline；
- 补齐 `models/golden/`、`sim/run.ps1`、`sim/scripts/`、`data/`、`build/constraints/` 等骨架；
- 删除过期的 `docs/02_大创推荐选题.md`，并同步 `docs/00` 阅读顺序与离线文档工具；
- 配套协作纪录：`report/llm_log/2026-11-06-jianglibo-hqc-baseline-and-sparse-mult.md`（RTL baseline 细节）。

## 验证证据

- C/C++ 黄金：
  - 命令：`powershell -NoProfile -ExecutionPolicy Bypass -File sim/run.ps1 sw`
  - 结果：`PASS: 5/5 checks`
- RTL 仿真：
  - 命令：`powershell -NoProfile -ExecutionPolicy Bypass -File sim/run.ps1 rtl tb_sparse_qc_mult`
  - 结果：`PASS: 4/4 checks`，`XSIM_DONE: tb_sparse_qc_mult`
- 离线文档：
  - 命令：`node tools/build-offline-docs.mjs`
  - 结果：`22 篇文档, 240.7 KB`
- Markdown 链接检查：
  - 命令：仓库内 Python 链接脚本（遍历 `**/*.md`）
  - 结果：`missing=0`
- 产物 / 链接：
  - 仓库：<https://github.com/LibJiang/dachuang>
  - 生成物 `build/offline/大创新手教程.html` 不入库，构建入口已入仓。

## 问题与解决

- 现象：按原计划写「稀疏乘法 + 完整 KEM 是我们的创新」，与组内工作存在撞题风险。
- 定位：读到田静组 SOCC 2023 论文，发现组内已完成稀疏乘法、128-bit/4-bank、RM FHT、RS ePIBM 和完整 HQC-128 KEM。
- 解决：新增 `docs/11` 差异表，明确这四项不能当原创；把增量改到 RISC-V + HQC 协处理器、参数化设计空间、混合软硬协同 + C/RTL 协同仿真、可复现 KAT 证据链、可选恒定时间/故障检测。
- 现象：HQC-128 的 `N=17669` 不是 64 的倍数，word-level 循环移位会把尾部填充位算进去。
- 定位：RTL 按 `WORDS=N/64` 组织，只验证了 `N=64`。
- 解决：V0 先限定 `N` 为 64 的倍数；`N=17669` 的尾部填充/折叠延后到 M2，并写进契约和待办。
- 现象：KAT 要求逐字节一致，采样/填充/字节序任一细节不同都会对不上。
- 定位：HQC 的 SHAKE、固定重量采样、编码、FO、隐式拒绝都有严格顺序。
- 解决：确定从 A1 起使用官方 HQC 参考实现与 KAT，禁止自行发明采样器；RTL 只替换稀疏乘法/FHT。
- 耗时：约 1 天（含论文精读、仓库改写与 RTL baseline）。

## 关键决策与理解

- **架构形态**：V0 采用混合架构——C/C++ 负责 SHAKE、采样、RS、FO/KAT，PL 负责稀疏乘法与 RM FHT；上板最后再定。理由是先保证完整协议正确，再逐步下沉硬件。
- **三步走**：A 软件基线 → B 稀疏乘法加速 → C 完整 KEM 与系统协同仿真；A 不过 KAT 不进 B，B 有 1 字节不对不进 C。
- **原创边界**：复现是基线，不是成果；组内 SOCC 2023 已做的稀疏乘法、FHT、ePIBM、完整 KEM 四项不得写成原创。
- **接口先行**：模块 RTL 开始前冻结 `docs/contracts/` 对应契约，改接口必须同步所有依赖与测试。
- **可讲清的核心公式**：`a·b = ⊕_{p∈supp(b)} (a <<< p) mod (X^n−1)`；把 $O(n^2)$ 降到 $O(wn)$，这是稀疏乘法数据通路和 testbench 的共同依据。
- **比较口径**：不与论文在更大 Artix-7 上的全硬件 KEM 硬拼绝对延迟；比资源受限的 Zynq-7020、可编程性、设计空间与完整 KAT 证据链。

## 未完成 / 待办

- [ ] A1：官方 HQC-128 参考实现 + KAT 入仓，跑通 100/100（未实现）
- [ ] `N=17669` 的尾部填充/折叠（未实现）
- [ ] 稀疏乘法 1000 组随机对拍（未实现）
- [ ] OOC 综合与 LUT/FF/BRAM/Fmax/周期数（未验证）
- [ ] 4 路并行 + BRAM banking + 设计空间 Pareto（未实现）
- [ ] `rm_fht128` + 重复合并（未实现）
- [ ] KEM 控制 FSM / 数据通路 / 端到端 KAT ≥10 组（未实现）
- [ ] RISC-V + PL 协处理器集成（V1，未实现）
- [ ] 上板 PYNQ-Z2（可选，未开始）
- [ ] 与田老师确认原创定位，避免与组内师兄师姐撞题（未确认）

## 可提炼经验

- 写「创新点」之前先读组内论文和最近基线，否则很容易把别人已做的工作当原创。
- 在 RTL 之前冻结接口契约，testbench 和 C 黄金都按契约写，能减少后期返工。
- 先做 C 黄金 + xsim + KAT 的完整证据链，再谈上板；没有仓库内命令可复现的「已验证」不算完成。
- word-level 循环移位要先确认 `N` 是否是字长的倍数；不是就要单独处理尾部，不能默认 `WORDS*64 == N`。
- 和更大的全硬件论文比较时，换赛道（资源受限平台/可编程性/设计空间），不要硬拼绝对延迟。

## 参考

- Chen Li, Suwen Song, Jing Tian, Zhongfeng Wang, Çetin Kaya Koç, “An Efficient Hardware Design for Fast Implementation of HQC,” IEEE SOCC 2023, DOI `10.1109/SOCC58585.2023.10257054`.
- HQC 官方 spec 与参考实现（NIST 提交包 / HQC 官网）。
- `docs/08_HQC技术路线.md`
- `docs/09_工程约束与验证规范.md`
- `docs/10_团队分工与国家级指标.md`
- `docs/11_组内基线与差异表.md`
- `docs/contracts/README.md`
- `report/llm_log/2026-11-06-jianglibo-hqc-baseline-and-sparse-mult.md`
- 参考工程：<https://github.com/never-die-cold/FPGA-Alittle-Design>
