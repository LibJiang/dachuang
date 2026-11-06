# HQC-KEM-FPGA：基于 PYNQ-Z2 的 HQC KEM 硬件加速

> 南京大学大创项目 · 田静老师课题组方向 · 后量子密码（PQC）· 码密码 HQC
> **方向状态：已确定（HQC KEM）**
> **实施策略：先把完整 KEM 在 C/C++ + Vivado xsim + 综合里做通，上板最后再定**
> 当前阶段：A 软件基线 / M0 启动

---

## 一、项目一句话

目标不是先点灯，而是先交付一个**完整、可复现、可对拍**的 HQC KEM：

- **C/C++ 软件仿真**：官方参考实现 + 独立黄金模型 + 官方 KAT；
- **Vivado xsim 硬件仿真**：稀疏乘法、RM FHT、KEM 数据通路的自检 testbench；
- **系统级协同仿真**：C 模型调度 + RTL 模块，跑通 KeyGen / Encaps / Decaps；
- **综合与 PPA**：Vivado 综合/实现报告，给出频率、面积、周期数；
- **上板**：作为最后的加分项，不作为 V0 的硬闸门。

> 导师意见：**先把完整的东西做出来，最后再考虑是否上板。** 本仓库按这个顺序组织。

---

## 二、为什么选 HQC

HQC（Hamming Quasi-Cyclic）是 NIST 2025 年选中的第五个后量子 KEM，安全性基于**准循环码的解码困难性**。它和 Kyber 是两条完全不同的技术路线：

| | Kyber（格密码） | HQC（码密码） |
|:---|:---|:---|
| 运算域 | $\mathbb{Z}_q$，$q=3329$ | $\mathrm{GF}(2)[X]/(X^n-1)$ |
| 核心运算 | NTT + 模约减 | 准循环乘法 + RM/RS 解码 |
| 本项目切入点 | 不适用 | **稀疏结构驱动的乘法器** |

HQC 的密钥与误差向量是**固定重量稀疏**的，因此所有乘法都是 **dense × sparse**，可以按稀疏位置做循环移位再 XOR 累加，把朴素 $O(n^2)$ 降到 $O(wn)$。这是本项目的核心架构洞察。

---

## 三、项目边界（仿真优先）

| 层级 | 内容 | V0 必做 |
|:---|:---|:---|
| **A 软件基线** | 官方 HQC-128 参考实现 + KAT + C/C++ 黄金 | ✅ |
| **B 单点加速** | PL 稀疏乘法替换 `vect_mul`，KAT 仍全过 | ✅ |
| **C 系统扩展** | RM FHT、KEM 数据通路、协同仿真、设计空间 | ✅（仿真/综合） |
| **D 上板** | PYNQ-Z2 实机演示 | 🟡 最后再定 |

**V0 明确不做**：全 RTL KEM、掩码/侧信道防护、ASIC、应用层协议。

**上板策略**：先把完整 KEM 在 C/C++ + xsim + 综合里跑通；导师确认后再决定是否上板。上板不是立项/结题的硬闸门。

---

## 四、系统架构

```mermaid
flowchart LR
    CM[C/C++ 参考实现 / 黄金模型<br/>SHAKE、采样、RS、FO、KAT] -->|文件 / DPI-C| TB[系统级 testbench]
    TB --> CTRL[KEM 控制 FSM]
    CTRL --> SM[稀疏 QC 乘法器<br/>dense × sparse]
    CTRL --> RM[RM(1,7) FHT 解码器<br/>+ 重复合并]
    SM <--> MEM[多项式 BRAM<br/>h,s,u,v,x,y,r1,r2,e]
    RM <--> MEM
    TB --> CHK[逐字节对拍 / PASS-FAIL]
```

职责划分：

| 任务 | V0 放置 | 说明 |
|:---|:---|:---|
| SHAKE256 / KDF | C/C++ 参考 | 保证 KAT 一致；V1 可选 RTL Keccak |
| 固定重量采样 | C/C++ 参考 | 禁止自行发明 |
| 稀疏乘法 | **RTL** | 核心加速对象 |
| RM(1,7) 解码 | **RTL** | FHT + 重复合并 |
| RS 编解码 | C/C++ 参考 | V1 再评估是否下沉 |
| FO 重加密 / 隐式拒绝 | C/C++ 或 RTL 控制 | 常数时间比较 |
| 系统调度 | C/C++ testbench / 可选自研 RISC-V | 上板时再替换 |

---

## 五、三步走

1. **A 基础闭环**：官方 HQC-128 参考实现 → KeyGen / Encaps / Decaps + FO + 隐式拒绝 → 官方 KAT 逐字节通过。
2. **B 单点加速**：把稀疏乘法搬到 RTL，其余不动；同一批 KAT 仍全过，测出加速比与资源。
3. **C 系统扩展**：RM FHT 下沉、KEM 数据通路、系统级协同仿真、HQC-192/256、设计空间与 Pareto；上板最后再定。

**硬闸门**：A 不过 KAT 不进 B；B 的 KAT 有 1 个字节不对不进 C；C 的协同仿真不通过不写上板。

---

## 六、国家级立项指标（目标）

> 以下为**目标值**，不是承诺；最终以 `data/logs/` 与 `data/evidence/` 的仿真/综合实测为准。
> 口径分三列：仿真（xsim/C）、综合（Vivado）、上板（可选）。不得混写。

### 6.0 组内基线（SOCC 2023）

组内 Chen Li et al. 已经在 **Artix-7 xc7a200t-3** 上完成 HQC-128 完整 KEM：

| 基线 | 器件 | LUT | FF | BRAM | Fmax | KeyGen / Encap / Decap |
|:---|:---|:---|:---|:---|:---|:---|
| SOCC 2023 | xc7a200t-3 | 19,794 | 11,079 | 68 | 178 MHz | 0.11 / 0.22 / 0.38 ms |

它已经使用了**稀疏乘法、RM FHT、RS ePIBM**。所以本项目**不主张**“稀疏乘法 / 完整 KEM / FHT”本身为原创；
我们的增量在**RISC-V 集成、参数化设计空间、混合软硬协同、可复现验证**。
详细差异见 [docs/11_组内基线与差异表.md](docs/11_组内基线与差异表.md)。

### 6.1 功能与正确性

| 指标 | 目标 | 证据 |
|:---|:---|:---|
| 完整 KEM | HQC-128 KeyGen / Encaps / Decaps + FO + 隐式拒绝 | 系统级协同仿真 |
| 官方 KAT | **100/100** 向量逐字节一致 | `data/logs/.../kat.log` |
| 单元随机 | 稀疏乘法、FHT 各 ≥1000 组随机对拍 | `data/logs/.../xsim.log` |
| 端到端 | ≥10 组协同仿真 KAT 全过 | `data/logs/.../system.log` |
| 负向 | 篡改密文 → 隐式拒绝 | `data/logs/.../negative.log` |
| 错误数 | 0 mismatch（硬闸门） | 所有回归日志 |

### 6.2 性能与 PPA（仿真/综合口径）

| 指标 | 目标 | 说明 |
|:---|:---|:---|
| 稀疏 vs 朴素乘法 | 周期数降低 **≥10×** | 理论 $O(wn)$ vs $O(n^2)$ 约两个数量级 |
| 4 路并行 | 吞吐 ≥3×，资源 ≤2× | 以 1 路为基线 |
| Decaps PL 数据通路 | ≤100k 周期（1 路）/ ≤30k（4 路） | 两次稀疏乘法 + 两次 FHT |
| Fmax | **≥100 MHz**（post-synthesis OOC） | 冲刺 125 MHz |
| PL 面积 | ≤35% LUT、≤30% BRAM、≤20% DSP | XC7Z020；混合架构只算 PL 部分 |
| 核心算子加速比 | ≥5×（vs C 参考） | 单独报告 |
| 端到端加速比 | ≥2×（冲刺 3×） | 混合架构 vs 纯软件基线 |
| 系统集成 | RISC-V + PL 协处理器（V1） | 可编程性/系统级差异 |

> 我们 V0 是**混合架构**（C/C++ SHAKE/RS + PL 稀疏乘法/FHT），PL 资源目标低于论文的全硬件 KEM；
> **不与论文比全硬件绝对延迟**，比的是资源受限平台、可编程性、设计空间和完整 KAT 证据链。

### 6.3 成果与冲刺

- 可复现仓库：RTL、C/C++ 黄金、xsim、KAT、综合报告、设计空间数据；
- 技术报告 + 答辩材料；
- **冲刺**：1 篇论文 / 1 项专利 / 1 次竞赛提交（国家级立项的加分项，不作为硬闸门）；
- 开源发布（许可证策略见第七节）。

---

## 七、四人分工

| 角色 | 负责 | 主要交付 | 依赖 |
|:---|:---|:---|:---|
| **A 算法与软件基线** | spec、官方参考实现、KAT、C/C++ 黄金、SHAKE/采样/RS、协同仿真 harness | `models/kem/`、`data/vectors/`、KAT 日志 | 无 |
| **B 稀疏乘法与存储** | `sparse_qc_mult`、dense 基线、循环移位/折叠、BRAM banking、LANES 设计空间 | RTL、tb、综合/Pareto | A 的黄金与向量 |
| **C FHT 与 KEM 数据通路** | `rm_fht128`、重复合并、KEM 控制 FSM、AXI/MMIO、系统集成 | RTL、tb、协同仿真 | A/B 的接口 |
| **D 验证与评测** | testbench 框架、随机向量、回归、xsim CI、PPA、报告、查新/原创性 | 回归套件、证据、报告、差异表 | 全员 |

- 每周一次集成：A 出向量 → B/C 出 RTL → D 跑回归 → 更新 `docs/records/`；
- 接口以 `docs/contracts/` 为准，冻结后改动必须同步；
- 人少时可合并：A+D、B+C。

详细分工与周节奏见 [docs/10_团队分工与国家级指标.md](docs/10_团队分工与国家级指标.md)。

---

## 八、仓库结构

```text
dachuang/
├─ README.md                 # 本文件
├─ plan.md                   # 项目主计划、里程碑、验收口径
├─ AGENTS.md                 # 工程硬约束（开工必读）
├─ docs/
│  ├─ 00_新队友阅读顺序.md
│  ├─ 01_田静老师资料与研究方向.md
│  ├─ 03_前置知识与学习路线.md
│  ├─ 04_GitHub与Git一天上手.md
│  ├─ 05_前置知识补全_从数电到Verilog实战.md
│  ├─ 06_协作纪录与技能提炼规范.md
│  ├─ 07_新手使用Agent教程.md
│  ├─ 08_HQC技术路线.md
│  ├─ 09_工程约束与验证规范.md
│  ├─ 10_团队分工与国家级指标.md
│  ├─ 11_组内基线与差异表.md   # SOCC 2023 对照与原创边界
│  ├─ contracts/              # 接口契约
│  └─ records/                # 协作纪录
├─ src/                       # 可综合 RTL
├─ sim/                       # testbench、xsim 脚本、软件仿真入口
├─ models/                    # C/C++ 黄金模型与官方参考实现 harness
├─ data/                      # 测试向量、黄金输出、日志、证据
├─ build/constraints/         # XDC 时序/引脚约束
├─ board/                     # 上板脚本与记录（最后再定）
├─ report/                    # 设计报告与 llm_log
├─ third_party/               # 第三方代码与许可证
├─ skill/                     # 团队技能
└─ tools/                     # 辅助脚本
```

---

## 九、快速开始

### 1. C/C++ 软件仿真（黄金模型）

```bash
# WSL / MSYS2
make -C models/golden
./build/golden/qc_mult_ref --selftest
./build/golden/qc_mult_ref 8 4D 1,4        # 期望输出 0x4E
```

### 2. Vivado 硬件仿真（xsim）

```bash
# WSL / Linux
vivado -mode batch -source sim/scripts/run_xsim.tcl -tclargs tb_counter

# Windows PowerShell
.\sim\run.ps1 rtl tb_counter
```

### 3. 一键入口

```bash
bash sim/run.sh sw                 # 编译并跑 C 黄金模型自检
bash sim/run.sh rtl tb_counter     # 调 Vivado xsim
bash sim/run.sh lint               # iverilog 快速 lint（可选）
```

通过标准：testbench 输出 `PASS: N/N checks`；KAT 输出 `PASS: N/N vectors`。

---

## 十、原创性与创新得分点

> 原则：**复现是基线，不是成果；参考必须引用，贡献必须量化。**

### 10.1 贡献边界

| 内容 | 来源 | 本项目的工作 |
|:---|:---|:---|
| HQC 算法与参数 | 官方 spec / 参考实现 | 复现、KAT 对拍 |
| **稀疏乘法** | **SOCC 2023 已做**；[8] LEAP | ❌ 不能当原创；只做参数化/设计空间 |
| **RM FHT 解码** | SOCC 2023 已做 | ❌ 不能当原创；实现/验证 |
| **RS ePIBM 解码** | SOCC 2023 已做 | ❌ 不能当原创；V0 放 C/C++ |
| **完整 HQC-128 KEM** | SOCC 2023 已做 | ❌ 不能当原创；做混合协同/KAT |
| 参数化设计空间 | 本项目 | 64/128-bit、1/2/4/8 路、BRAM banking、Pareto |
| 自研 RISC-V + HQC 协处理器 | 竞赛项目积累 | ✅ 系统级原创候选 |
| 混合软硬协同 + C/RTL 协同仿真 | 本项目 | ✅ 工程/系统贡献 |
| 恒定时间/故障检测 | 本项目（选做） | ✅ 安全方向候选 |

> **组内已做**：稀疏乘法、FHT、ePIBM、完整 HQC-128 KEM（`docs/11`）。
> **本项目不再主张**这四点是原创；申报书必须把“复现”和“增量”分开写。

### 10.2 创新得分点（候选，需查新确认）

| # | 得分点 | 为什么新 | 怎么证明 |
|:---|:---|:---|:---|
| 1 | **RISC-V + HQC 协处理器** | 组内是固定硬件 KEM；我们做可编程 SoC 集成 | MMIO/指令接口 + 完整 KAT + 软硬划分表 |
| 2 | **参数化稀疏乘法设计空间** | 组内是单一配置；我们给 1/2/4/8 路 Pareto | 周期/资源/时序对比 |
| 3 | **混合软硬协同 + C/RTL 协同仿真** | 组内是全硬件；我们给资源受限平台的混合方案 | 100 组 KAT + 10 组端到端 + 延迟分解 |
| 4 | HQC-192/256 参数化 | 组内只实现 HQC-128 | 三参数集资源/延迟对比 |
| 5 | 恒定时间/故障检测（选做） | 组内未涉及 | 侧信道/故障注入实验 |

> 这些是**候选**，必须用 `docs/11` 的差异表逐条确认；如果组内已经做过，就换角度，不硬写“原创”。

### 10.3 查新与许可证

- **查新**：组内 SOCC 2023 已经做了稀疏乘法/FHT/ePIBM/完整 HQC-128 KEM；差异表见 [docs/11_组内基线与差异表.md](docs/11_组内基线与差异表.md)。
- **不要写**：“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”。
- **许可证**：本项目代码沿用 MIT；官方 HQC / 第三方 IP 放 `third_party/`，保留原 LICENSE。
- **不确定许可证的代码不入库**：只记录获取方式、版本、SHA256；确认后再 vendor。

---

## 十一、文档导航

**新队友按顺序读**：

1. [GitHub 与 Git 一天上手指南](docs/04_GitHub与Git一天上手指南.md)
2. [田静老师资料与研究方向](docs/01_田静老师资料与研究方向.md)
3. [HQC 技术路线](docs/08_HQC技术路线.md) — **本项目主线**
4. [工程约束与验证规范](docs/09_工程约束与验证规范.md) — 动手前必读
5. [团队分工与国家级指标](docs/10_团队分工与国家级指标.md)
6. [组内基线与差异表](docs/11_组内基线与差异表.md) — **原创性必读**
7. [前置知识与学习路线](docs/03_前置知识与学习路线.md)
8. [前置知识补全：从数电到 Verilog 实战](docs/05_前置知识补全_从数电到Verilog实战.md)
9. [协作纪录与技能提炼规范](docs/06_协作纪录与技能提炼规范.md)
10. [新手使用 Agent 教程](docs/07_新手使用Agent教程.md)

**接口契约**：[docs/contracts/](docs/contracts/README.md)

**项目管理**：[plan.md](plan.md) · [AGENTS.md](AGENTS.md)

**工程入口**：[models/README.md](models/README.md) · [sim/README.md](sim/README.md) · [data/README.md](data/README.md) · [build/constraints/README.md](build/constraints/README.md) · [board/README.md](board/README.md) · [report/README.md](report/README.md) · [skill/README.md](skill/README.md)

---

## 十二、当前状态

- [x] 方向确定：HQC KEM 硬件加速
- [x] 仓库骨架、阅读顺序、协作规范、接口契约
- [x] C/C++ 稀疏乘法黄金模型 + 自检
- [x] Vivado xsim 批处理入口 + smoke test
- [x] 国家级立项指标与四人分工
- [x] 已读并分析组内 SOCC 2023 HQC 论文，差异表已建（`docs/11`）
- [x] 单路 `sparse_qc_mult` RTL baseline（N=64，4/4 checks）
- [ ] A1：官方 HQC-128 参考实现 + KAT 跑通
- [ ] A2：C/C++ 完整 KEM 黄金 + 系统协同仿真骨架
- [ ] B1：`sparse_qc_mult` 的 HQC-128（N=17669）随机 1000 组 + 综合
- [ ] B2：4 路并行 + 设计空间 + PPA
- [ ] C1：RM FHT + KEM 数据通路 + 端到端 KAT
- [ ] C2：HQC-192/256 / 自研 RISC-V / 上板（最后再定）
