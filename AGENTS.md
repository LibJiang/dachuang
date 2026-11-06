# AGENTS.md —— 每次开工前必读（硬性）

> 适用：本仓库所有分支。项目方向：**HQC KEM 硬件加速（PYNQ-Z2 / Zynq-7020）**。
> 目的：杜绝四类事故——① 用临时文件验证、结论不可复现；② 把“未实现 / 未验证”说成“已完成”；
> ③ 把复现写成原创；④ 跨目录乱改、破坏接口契约。
> **未完成下面「开工三件事」，不得开始任何编码或改动。**

---

## 一、开工三件事（缺一不可）

1. **读约束**：完整阅读 `plan.md`、`docs/08_HQC技术路线.md`、`docs/09_工程约束与验证规范.md`、
   `docs/10_团队分工与国家级指标.md`，以及本次要改模块对应的 `docs/contracts/*.md`。
2. **核实现状**：先跑
   ```bash
   git rev-parse --abbrev-ref HEAD
   git log --oneline -5
   git status
   ```
   然后在开工回复开头贴出三类清单：
   - ✅ 已实现并验证
   - 🟡 已实现但未验证
   - ⬜ 未实现 / 未接入
3. **声明范围**：一句话说明本次改哪些文件、验证方式（C/C++ 黄金 / xsim / 上板）、预估行数。

---

## 二、硬红线

### 1. 目录边界

- 默认允许改：`src/`、`sim/`、`models/`、`data/`、`docs/`、`build/constraints/`、`report/`、`skill/`。
- **只读**：`docs/01_田静老师资料与研究方向.md`（导师与论文清单）。
- 冻结后的 `docs/contracts/*.md` 改动，必须先说明理由并同步所有依赖模块，不得默默修改。
- 超出上述范围 → 先说明再改。

### 2. 可复现性（最关键）

- **禁止**用 `/tmp`、桌面临时文件、聊天里的代码作为“已验证”依据。
- 任何“已验证”的结论，必须能由**仓库内命令**一键复现：
  - C/C++ 黄金：`make -C models/golden && ./build/golden/qc_mult_ref --selftest`
  - RTL 仿真：`bash sim/run.sh rtl <tb_top>` 或 Vivado xsim 脚本
  - 完整 KEM：官方 KAT 脚本 + `data/logs/` 原始输出
- 不允许声称“已验证”却拿不出日志 / 波形 / 报告路径。

### 3. 交付纪律

- **单步 ≤100 行**，先设计后写码，讲不清的代码不许提交。
- 每步结束固定汇报四件套：
  1. 改了哪些文件；
  2. 验证命令与原始结果；
  3. `git diff --check`；
  4. 待办 / 未接入清单（明确标注“未实现 / 未验证”）。
- 每次工作后在 `docs/records/` 写协作纪录（见 `docs/06`）。
- **未经用户确认理解，不得 `git commit` / `git push`。**

### 4. 编码与综合约束

- 进入综合的 RTL 必须是 **Verilog-2001** 可解析：
  - 禁止 `.*`、`logic`、`always_ff`、`always_comb` 等 SystemVerilog-only 语法；
  - 例外：testbench 可在 xsim 中显式按 SystemVerilog 编译，但必须在脚本里写明。
- 禁止 latch：组合 `always @*` 必须覆盖所有分支，或使用 `default`。
- 时钟/复位：同步设计；异步复位统一低有效 `rst_n`；跨时钟域必须显式同步器并写注释。
- 禁止在综合 RTL 中使用 `#delay`、`initial` 赋初值（FPGA 可用 `initial` 初始化 BRAM 的场景需单独评审）。
- 位宽必须显式；禁止依赖隐式截断/扩展；有符号运算统一用 `$signed` / `signed` 并写注释。

### 5. HQC 专项约束

- **仿真优先**：先完成 C/C++ + xsim + 综合的完整 KEM；上板最后再定，不作为 V0 硬闸门。
- **“完整”的判定**：官方 KAT 100/100 逐字节通过 + ≥10 组端到端协同仿真通过 + 0 mismatch。
- **参数集**：V0 只做 HQC-128；HQC-192/256 属于 C 阶段，V0 不得为此牺牲正确性。
- **数据表示**：稠密多项式按 bit 存储，`bit i = X^i` 的系数；稀疏多项式存位置列表（升序、无重复）。
  详细定义见 `docs/contracts/sparse_qc_mult_v0.md`。
- **KAT 字节级一致**：PRNG、采样、编码、填充、字节序必须使用官方参考实现；**禁止自行发明采样器**。
- **常数时间**：FO 重加密后的比较必须常数时间；解密失败走隐式拒绝；V0 至少不得出现“提前 return 泄漏”。
- **秘密数据**：稀疏位置、私钥、随机数不得出现在 `$display` / 日志 / 波形文件名中。

### 6. 原创性与引用

- 复现官方 HQC 参考实现、田静组 SOCC 2023 HQC 硬件论文、任何第三方 IP，必须注明来源与许可证。
- **许可证不明确**：不要把代码直接 vendor 进仓库；先记录获取方式、版本、SHA256，确认许可证后再放。
- 本项目代码沿用仓库 MIT；第三方代码放 `third_party/`，保留原 LICENSE。
- 申报书 / 报告必须包含“贡献边界表”：复现 / 改进 / 原创分别是什么。
- **组内 SOCC 2023 已经做了稀疏乘法、RM FHT、RS ePIBM、完整 HQC-128 KEM**；
  这四项不得当本项目原创。差异表见 `docs/11_组内基线与差异表.md`。
- 不得写“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”。
- 候选增量应落在：RISC-V 集成、参数化设计空间、混合软硬协同、协同仿真、参数化/安全。

---

## 三、工具链约束

| 用途 | 工具 | 入口 |
|:---|:---|:---|
| 软件黄金模型 | GCC / Clang（C11） | `make -C models/golden` |
| 完整 KEM 软件基线 | 官方 HQC 参考实现（C） | `models/kem/`（A1 补齐） |
| RTL 仿真 | **Vivado xsim** | `sim/scripts/run_xsim.tcl` |
| 快速 lint（可选） | Icarus Verilog | `bash sim/run.sh lint` |
| 综合 / 实现 | Vivado 2026.1 | `build/` + `build/constraints/` |
| 上板（可选） | PYNQ-Z2 | `board/`（最后再定） |

- 不以 Icarus 替代 xsim 作为最终 RTL 验证依据；Icarus 只用于快速 lint。
- 所有仿真日志放 `data/logs/`，综合/时序报告放 `data/evidence/`。
- 上板不是 V0 闸门；先完成 C/C++ + xsim + 综合的完整 KEM。

---

## 四、参考入口

- 主计划：`plan.md`
- HQC 技术路线：`docs/08_HQC技术路线.md`
- 工程约束：`docs/09_工程约束与验证规范.md`
- 分工与指标：`docs/10_团队分工与国家级指标.md`
- 接口契约：`docs/contracts/README.md`
- 协作纪录：`docs/records/README.md` + `TEMPLATE.md`
- 阅读顺序：`docs/00_新队友阅读顺序.md`
