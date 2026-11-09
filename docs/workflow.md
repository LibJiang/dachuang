# 开发流程与硬约束（开工前必读）

> 适用：**本仓库所有代码线**——Verilog RTL、testbench、C/C++ 黄金、KAT、Python、Tcl、shell/PowerShell 脚本。
> 不是只约束 RTL；只要会进入交付物，都适用。
> 配套技能：`skill/gufa-programming/`、`skill/understand-gate/`、`skill/contract-freeze-workflow/`。

---

## §1 开工三件事（缺一不可）

1. **读约束**：完整阅读 `plan.md`、`docs/12_FPGA_ASIC路线.md`、`docs/13_开工清单与近期任务.md`、`docs/14_总体工作计划.md`、本文，以及本次要改模块的 `docs/contracts/<模块>_v0.md`。
2. **核实现状**：跑
   ```bash
   git rev-parse --abbrev-ref HEAD
   git log --oneline -5
   git status
   ```
   回复开头贴三类清单：✅ 已实现并验证 / 🟡 已实现但未验证 / ⬜ 未实现。
3. **声明范围 + 契约状态**：一句话说明本次改哪些文件、验证方式、预估行数；
   并明确：**对应契约是否已冻结**。没有冻结契约 → 先冻结，不许写代码。

---

## §2 契约先行（硬性）

**规则：没有冻结契约，不许写任何模块/接口代码。**

流程：

1. 用 `docs/contracts/TEMPLATE.md` 起草契约；
2. 冻结前枚举全部用例（操作码、字段、位宽、状态、参数集）；
3. 至少 1 名非作者评审；
4. 评审通过 → 状态改 `冻结`，在 `docs/records/` 写“契约冻结”纪录；
5. 实现；
6. 契约变更 → 新版本 `_v1.md`，旧版本保留，**三处同步**：RTL、tb/系统仿真、C 黄金/KAT/脚本。

详细流程见 `skill/contract-freeze-workflow/SKILL.md`。

### HQC 最小契约集

| 契约 | 状态 |
|:---|:---|
| `docs/contracts/hqc_kem_v0.md` | 草案 |
| `docs/contracts/sparse_qc_mult_v0.md` | 草案 |
| `docs/contracts/rm_decoder_v0.md` | 草案 |
| `docs/contracts/axi_mmio_v0.md` | 草案 |
| `sha3_v0.md` / `sampler_v0.md` / `rs_codec_v0.md` | 待建 |

> 草案 ≠ 冻结。RTL 开工前必须先把对应契约冻结。

---

## §3 古法编程（硬性）

**规则：单步 ≤100 行；先设计后写码；每步讲解 + 2–3 道理解题；用户回答后才进下一步。**

流程：

1. **拆步**：先给步骤清单（文件、行数、验证方式），用户确认；
2. **单步实现**：只做当前步，≤100 行（不含注释空行）；
3. **本步自检**：给出命令 + 原始结果，禁止“应该没问题”；
4. **讲解 + 出题**：设计意图、关键信号、与契约对应；出 2–3 道题；
5. **等用户回答**：不通过 → 补讲 + 补题，直到通过；
6. **下一步**。

详细见 `skill/gufa-programming/SKILL.md`。

---

## §4 理解门槛（commit 前）

**规则：看不懂的代码不许 commit。**

- 逐段讲解 + 3 道理解题；
- 用户确认理解前，不得 `git commit` / `git push`；
- 通过后把讲解 + 题目 + 答案写入 `report/llm_log/`；
- 纯文档 / `.gitignore` / `llm_log` / `data` 记录类 commit 豁免。

详细见 `skill/understand-gate/SKILL.md`。

---

## §5 每步交付四件套

1. 改了哪些文件；
2. 验证命令 + 原始结果；
3. `git diff --check`；
4. 待办 / 未接入清单（明确标注“未实现 / 未验证”）。

---

## §6 分支与 PR

- `main` 受保护，不直接 push；只通过 PR 合并。
- 功能分支从 `feat/hqc-fpga-asic` 切；PR 目标也是 `feat/hqc-fpga-asic`。
- **不做 force push**（除非用户明确授权并说明原因）。
- 一个 PR 只做一件事；不同模块不要混。
- PR 必须附：验证命令、原始结果、契约状态、未完成项。
- 不覆盖别人的提交；不删除别人的分支/提交，除非用户明确要求。

---

## §7 验证与证据

- **RTL**：每个模块必须有自检 tb，xsim 输出 `PASS: N/N checks`；Icarus 只做 lint，不作为最终依据。
- **C/C++ 黄金**：每个程序支持 `--selftest`，输出 `PASS: N/N`。
- **完整 KEM**：官方 KAT 100/100；系统仿真 0 mismatch。
- **证据**：日志放 `data/logs/`，综合/ASIC 报告放 `data/evidence/`，协作纪录放 `docs/records/`。
- **禁止**用 `/tmp`、桌面临时文件、聊天里的代码作为“已验证”依据。
- 任何“已验证”必须能由仓库内命令一键复现。

---

## §8 代码风格

### Verilog / RTL

- 综合 RTL 用 **Verilog-2001**；禁止 `.*`、`logic`、`always_ff`、`always_comb` 等 SystemVerilog-only 语法。
- 禁止 latch：组合 `always @*` 所有分支必须赋值。
- 禁止在综合 RTL 中使用 `#delay`、`initial` 赋初值（BRAM 初始化需单独评审）。
- 位宽显式；禁止隐式截断/扩展；有符号运算显式 `signed`。
- 时钟/复位：同步设计；异步复位低有效 `rst_n`；跨时钟域必须显式同步器。
- **ASIC 导向**：核心 RTL 不使用 FPGA 原语（BRAM IP、DSP48、MMCM 等）；FPGA 专用封装放 `src/soc/` 或 `board/`。
- 每个 `always` 块说明状态/数据流/为什么这样寄存。

### C/C++

- C11；GCC/Clang；`-O2 -Wall -Wextra -Werror`。
- 禁止未定义行为；随机测试固定种子并打印。
- 与官方参考对拍时逐字节比较，不能只比“共享密钥相等”。

### Python / 脚本

- 参数解析、错误处理、退出码明确。
- 生成物放 `build/`，不入库；日志放 `data/logs/`。
- 不写死本机绝对路径。

---

## §9 Bug 修复流程

1. **复现**：写一个最小复现用例；
2. **留证**：先写会 FAIL 的测试，对旧代码跑出 FAIL；
3. **定位**：缩小到模块/信号/字段；
4. **修复**：只改必要范围；
5. **回归**：跑全量 + 定向用例；
6. **记录**：协作纪录写清现象 → 定位 → 修复 → 证据。

---

## §10 评审清单（PR 合入前）

- [ ] 契约已冻结；接口/位宽/时序与契约一致；
- [ ] 单步 ≤100 行；步骤清单和讲解齐全；
- [ ] 有自检 tb / 黄金 / KAT；`PASS` 证据在仓库内；
- [ ] 没有生成物、密钥、绝对路径、临时文件；
- [ ] `git diff --check` 通过；
- [ ] 未完成项明确标注；
- [ ] 理解门槛通过，llm_log 已记录；
- [ ] 没有覆盖别人的提交。

---

## §11 豁免

- 纯文档 / `.gitignore` / `llm_log` / `data` 记录类改动；
- 一行修复（typo、改常量）且用户认可；
- 用户显式说“快速模式 / 别出题 / 一次写完”——必须在协作纪录里留痕；
- 探索性 spike（注定要扔的代码）——转正式实现时补走流程。

---

## §12 参考

- `skill/gufa-programming/SKILL.md`
- `skill/understand-gate/SKILL.md`
- `skill/contract-freeze-workflow/SKILL.md`
- `docs/contracts/TEMPLATE.md`
- `docs/09_工程约束与验证规范.md`
