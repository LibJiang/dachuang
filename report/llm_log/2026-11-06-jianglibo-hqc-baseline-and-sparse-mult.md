# 2026-11-06 jianglibo HQC 基线与稀疏乘法 baseline

## 基本信息

- 日期：2026-11-06
- 成员：jianglibo
- 分支 / PR：`main` 工作区（未提交）
- 关联阶段 / 任务（A/B/C/D）：A/B1

## 本次目标

1. 读组内 SOCC 2023 HQC 论文，确认哪些不能当原创；
2. 更新仓库的原创性表述与差异表；
3. 写一个单路 `sparse_qc_mult` RTL baseline，用 xsim 对拍小用例。

## 做了什么

- 新增 `docs/11_组内基线与差异表.md`；
- 更新 `README.md` / `plan.md` / `AGENTS.md` / `docs/08` / `docs/10` 的原创性与指标表述；
- 新增 `src/mult/sparse_qc_mult.v`（单路、64-bit 字、N 为 64 的倍数）；
- 新增 `sim/tb_sparse_qc_mult.v`（N=64，W=3，4 个用例）；
- 新增 `src/mult/README.md`；
- 更新 `docs/contracts/sparse_qc_mult_v0.md` 的 N 限制说明；
- 更新 `docs/00`、`tools/build-offline-docs.mjs`。

## 验证证据

- C 黄金：
  - 命令：`sim/run.ps1 sw`
  - 结果：`PASS: 5/5 checks`
- RTL：
  - 命令：`sim/run.ps1 rtl tb_sparse_qc_mult`
  - 结果：`PASS: 4/4 checks`
  - 日志：`build/xsim/tb_sparse_qc_mult/...`（生成物不入库）
- 链接：
  - Markdown 链接检查 `missing=0`；
  - 离线文档 `22 篇文档, 240.0 KB`。

## 问题与解决

- 现象：一开始想把 N=17669 直接塞进 word-level 移位公式。
- 定位：17669 不是 64 的倍数，word-level 公式会按 `WORDS*64` 循环，尾部填充位会污染结果。
- 解决：V0 只支持 N 为 64 的倍数；HQC-128 的尾部填充/折叠放到 M2。
- 耗时：约 1 小时。

## 关键决策与理解

- 组内 SOCC 2023 已经做了稀疏乘法/FHT/ePIBM/完整 HQC-128 KEM，**这四项不能当原创**。
- 候选增量改为：RISC-V + HQC 协处理器、参数化设计空间、混合软硬协同 + C/RTL 协同仿真。
- V0 先做 64-bit 单路 baseline，优先功能；M2 再做 128-bit/4-bank 与多路并行。
- 能向队友讲清：`dst[i] ^= src[(i - p + n) % n]` 与 word-level `(d << s) | (d[prev] >> (64-s))` 的等价关系。

## 未完成 / 待办

- [ ] 官方 HQC 参考实现 + KAT 入仓（A1）
- [ ] N=17669 的尾部填充/折叠（未实现）
- [ ] 1000 组随机对拍（未实现）
- [ ] OOC 综合/PPA（未实现）
- [ ] 4 路并行 + BRAM banking（未实现）
- [ ] 与 SOCC 2023 的逐项差异表细化（已建初稿，待补作者/代码/许可证信息）

## 可提炼经验

- 先读组内论文再写“创新点”，否则容易把别人已做的工作当原创。
- word-level 循环移位要先确认 N 是否是 64 的倍数；不是就要单独处理尾部。
- testbench 先做 4 个边界用例，跑通再扩随机；比一上来 1000 组更容易定位。

## 参考

- Chen Li et al., “An Efficient Hardware Design for Fast Implementation of HQC,” SOCC 2023, DOI `10.1109/SOCC58585.2023.10257054`.
- `docs/11_组内基线与差异表.md`
- `docs/contracts/sparse_qc_mult_v0.md`
- `docs/09_工程约束与验证规范.md`
