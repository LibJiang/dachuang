# AGENTS.md —— 每次开工前必读（硬性）

> 适用：本仓库所有分支。项目方向：**HQC KEM 的完整 RTL 实现（FPGA/ASIC）**。
> 老师选题基线：**低延迟 dense×sparse 乘法（Karatsuba/Toom-Cook 仅示例，不是硬性要求）+ ePIBM/FHT + SHAKE 三阶段复用 + 恒定时间**。
> 目的：杜绝四类事故——① 用临时文件验证、结论不可复现；② 把“未实现 / 未验证”说成“已完成”；
> ③ 把复现写成原创；④ 跨目录乱改、破坏接口契约。
> **未完成下面「开工三件事」，不得开始任何编码或改动。**

---

## 一、开工三件事（缺一不可）

1. **读约束**：完整阅读 `docs/workflow.md`、`plan.md`、`docs/12_FPGA_ASIC路线.md`、
   `docs/11_组内基线与差异表.md`、`docs/08_HQC技术路线.md`、`docs/09_工程约束与验证规范.md`、
   `docs/10_团队分工与国家级指标.md`、`docs/16_基础补齐清单.md`，以及本次要改模块对应的 `docs/contracts/*.md`。
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
3. **声明范围 + 契约状态**：一句话说明本次改哪些文件、验证方式（C/C++ 黄金 / xsim / 板端）、预估行数；
   并明确对应契约是否已冻结。**没有冻结契约 → 不许写实现代码。**

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
  - 官方 KAT：`bash models/kem/harness/run.sh`
  - RTL 仿真：`bash sim/run.sh rtl <tb_top>` 或 Vivado xsim 脚本
  - 完整 RTL KAT：系统仿真 + `data/logs/` 原始输出
- 不允许声称“已验证”却拿不出日志 / 波形 / 报告路径。

### 3. 交付纪律

- **单步 ≤100 行**，先设计后写码，讲不清的代码不许提交。
- 每步结束固定汇报四件套：
  1. 改了哪些文件；
  2. 验证命令与原始结果；
  3. `git diff --check`；
  4. 待办 / 未接入清单（明确标注“未实现 / 未验证”）。
- 每次工作后在 `report/llm_log/` 写协作纪录（见 `docs/06`）。
- **未经用户确认理解，不得 `git commit` / `git push`。**

### 3.1 古法编程与契约冻结（硬性，适用于所有代码线）

> 适用于 Verilog RTL、testbench、C/C++、Python、Tcl、shell/PowerShell 脚本。
> 不是只约束 RTL。

- **契约先行**：没有冻结的 `docs/contracts/<模块>_v0.md`，不许写任何实现代码；
  先按 `skill/contract-freeze-workflow/SKILL.md` 起草、评审、冻结。
- **古法编程**：先给步骤清单；单步 ≤100 行；每步自检 + 讲解 + 2–3 道理解题；
  **等用户回答通过后才进下一步**。见 `skill/gufa-programming/SKILL.md`。
- **理解门槛**：commit 前逐段讲解 + 3 题；用户确认理解后才允许提交。
  见 `skill/understand-gate/SKILL.md`。
- **三处同步**：接口/数据格式变更必须同步 RTL、tb/系统仿真、C 黄金/KAT/脚本、契约。
- **不允许**“先写代码、后补契约”；契约未冻结时只允许写契约和验证计划。

### 4. 编码与综合约束

- 进入综合的 RTL 必须是 **Verilog-2001** 可解析：
  - 禁止 `.*`、`logic`、`always_ff`、`always_comb` 等 SystemVerilog-only 语法；
  - 例外：testbench 可在 xsim 中显式按 SystemVerilog 编译，但必须在脚本里写明。
- 禁止 latch：组合 `always @*` 必须覆盖所有分支，或使用 `default`。
- 时钟/复位：同步设计；异步复位统一低有效 `rst_n`；跨时钟域必须显式同步器并写注释。
- 禁止在综合 RTL 中使用 `#delay`、`initial` 赋初值（FPGA 可用 `initial` 初始化 BRAM 的场景需单独评审）。
- 位宽必须显式；禁止依赖隐式截断/扩展；有符号运算统一用 `$signed` / `signed` 并写注释。
- **ASIC 导向**：核心 RTL 不使用 FPGA 原语（BRAM IP、DSP48、MMCM 等）；
  FPGA 专用封装放 `src/soc/` 或 `board/`，核心模块保持可综合的通用 RTL。

### 5. HQC 专项约束

- **先完整 RTL 协议，再 FPGA 全功能跑通**：FPGA 是硬目标；ASIC 只做综合、**不流片**。
- **“完整”的判定**：全 RTL KeyGen/Encaps/Decaps；官方 KAT 100/100；**FPGA 板端 KAT 100/100**；系统仿真 0 mismatch。
- **老师已确认**：不流片；PDK 55/28/90nm；FPGA 全功能跑通是硬目标。
- **老师选题基线**：低延迟 dense×sparse 乘法（Karatsuba/Toom-Cook 仅示例，不是硬性要求）、ePIBM/FHT、SHAKE 三阶段复用、恒定时间；这些是要求/基线，不能写成我们的原创。
- **ASIC 节点**：55nm 主 / 28nm 对比 / 90nm 兜底；只做综合 + area/power/fmax。
- **参数集**：V0 只做 HQC-128（官方 HQC-1）；HQC-192/256 后续，不得为此牺牲正确性。
- **参考实现只读**：`third_party/hqc/` 是官方 public domain 代码，不得改算法；本地修改用 patch 记录。
- **数据表示**：稠密多项式按 bit 存储，`bit i = X^i` 的系数；稀疏多项式存位置列表（升序、无重复）。
  详细定义见 `docs/contracts/sparse_qc_mult_v0.md`。
- **KAT 字节级一致**：PRNG、采样、编码、填充、字节序必须使用官方参考实现；**禁止自行发明采样器**。
- **常数时间**：FO 重加密后的比较必须常数时间；解密失败走隐式拒绝；采样/解码/稀疏位置访问不得有秘密相关分支；V0 至少不得出现“提前 return 泄漏”。
- **秘密数据**：稀疏位置、私钥、随机数不得出现在 `$display` / 日志 / 波形文件名中。

### 6. 原创性与引用

- 复现官方 HQC 参考实现、田静组 SOCC 2023 HQC 硬件论文、任何第三方 IP，必须注明来源与许可证。
- **许可证不明确**：不要把代码直接 vendor 进仓库；先记录获取方式、版本、SHA256，确认许可证后再放。
- 本项目代码沿用仓库 MIT；第三方代码放 `third_party/`，保留原 LICENSE。
- 申报书 / 报告必须包含“贡献边界表”：复现 / 改进 / 原创分别是什么。
- **组内 SOCC 2023 已经做了稀疏乘法、RM FHT、RS ePIBM、完整 HQC-128 KEM**；
  这四项不得当本项目原创。差异表见 `docs/11_组内基线与差异表.md`。
- **老师选题简介的低延迟乘法结构、ePIBM/FHT、SHAKE 三阶段复用、恒定时间也是基线**，不得当本项目原创。
- 不得写“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”“FPGA 全跑通是我们的创新”“低延迟乘法结构是我们的创新”“SHAKE 复用是我们的创新”“恒定时间是我们的创新”。
- **FPGA 全功能跑通是硬目标，但组内 SOCC 2023 已做**；不能当唯一原创。
- 候选增量应落在：**ASIC 多工艺（55/28/90nm）**、FPGA/ASIC 设计空间、SHAKE 共享/独立 + 恒定时间联合评估、参数化/开源可复现、RISC-V 集成（可选）。

---

## 三、工具链约束

| 用途 | 工具 | 入口 |
|:---|:---|:---|
| 软件黄金模型 | GCC / Clang（C11） | `make -C models/golden` |
| 官方参考实现 / KAT | 官方 HQC C 代码（public domain） | `third_party/hqc/` + `bash models/kem/harness/run.sh` |
| RTL 仿真 | **Vivado xsim** | `sim/scripts/run_xsim.tcl` |
| 快速 lint（可选） | Icarus Verilog | `bash sim/run.sh lint` |
| FPGA 综合 / 实现 | Vivado 2026.1 | `build/` + `build/constraints/` |
| ASIC 综合（条件） | Cadence/Synopsys/OpenROAD（待确认）；PDK 55/28/90nm | `asic/` |
| FPGA 板级验证 | AC701 XC7A200T（主）/ XC7A100T（备） | `board/`（**硬目标**） |

- 不以 Icarus 替代 xsim 作为最终 RTL 验证依据；Icarus 只用于快速 lint。
- 所有仿真日志放 `data/logs/`，FPGA/ASIC 报告放 `data/evidence/`。
- 先完成完整 RTL + KAT，再完成 FPGA 全功能跑通；ASIC 是后置/条件阶段，且不流片。

---

## 四、参考入口

- **开发流程（必读）**：`docs/workflow.md`
- 主计划：`plan.md`
- HQC 技术路线：`docs/08_HQC技术路线.md`
- 组内基线与差异：`docs/11_组内基线与差异表.md`
- **FPGA/ASIC 路线**：`docs/12_FPGA_ASIC路线.md`
- 工程约束：`docs/09_工程约束与验证规范.md`
- 分工与指标：`docs/10_团队分工与国家级指标.md`
- 接口契约：`docs/contracts/README.md` + `docs/contracts/TEMPLATE.md`
- **古法编程**：`skill/gufa-programming/SKILL.md`
- **理解门槛**：`skill/understand-gate/SKILL.md`
- **契约冻结**：`skill/contract-freeze-workflow/SKILL.md`
- 官方参考实现：`third_party/hqc/VENDORED.md`
- 协作纪录：`report/llm_log/RECORDS-README.md` + `TEMPLATE.md`
- 阅读顺序：`docs/00_新队友阅读顺序.md`
