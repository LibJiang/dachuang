# 项目主计划：HQC-KEM-FPGA/ASIC

> 项目：**HQC-KEM-FPGA/ASIC：面向后量子密码 HQC 的完整 RTL 与 FPGA/ASIC 实现**
> 方向：田静老师课题组 · 后量子密码（PQC）· 码密码 HQC
> 更新：2026-11-09
> 总体排期：`docs/14_总体工作计划.md`（2026-11-06 → 2027-05-31，2027-06 只修 bug）
> 配套：`README.md`、`AGENTS.md`、`docs/12_FPGA_ASIC路线.md`、`docs/11_组内基线与差异表.md`、`docs/contracts/`

---

## §1 项目定义

### 1.1 一句话目标

用 **完整 RTL** 实现 HQC-128 KEM（KeyGen / Encaps / Decaps + FO + 隐式拒绝），
用官方 KAT 逐字节验证，**在 FPGA 上全功能跑通并给出 PPA**；
ASIC 只做综合评估（55nm 主 / 28nm 对比 / 90nm 兜底），**不跑 P&R、不流片**。

### 1.2 功能边界

| 层级 | 必须做到 | 不属于 V0 |
|:---|:---|:---|
| 算法 | HQC-128 完整 KEM | HQC-192/256（后续） |
| 软件 | 官方参考实现 + KAT + C 黄金 | 应用层协议 |
| 硬件 | 全 RTL：SHAKE、采样、RS、RM、稀疏乘法、控制、AXI | 掩码/侧信道 |
| 验证 | 系统仿真 + 官方 KAT 100/100 | 功耗采集 |
| FPGA | **板端全功能跑通 + KAT 100/100** + PPA | 主 AC701 XC7A200T；备 100T |
| ASIC | 55/28/90nm 综合 + area/power/fmax | P&R/流片（老师确认不做） |

> 组内 SOCC 2023 已经做了 FPGA 完整 KEM；本项目不把“稀疏乘法/完整 KEM”当原创，
> 差异点是 **完整 RTL + ASIC 评估 + 设计空间 + 开源可复现**。

### 1.3 交付物

- 完整 RTL：`src/` 下全部 KEM 模块；
- 官方 KAT 对拍：`models/kem/harness/` + `third_party/hqc/`；
- xsim 系统仿真 + 100/100 KAT；
- **FPGA 板端全功能跑通 + KAT 100/100**；
- Vivado 综合/实现报告：LUT/FF/BRAM/Fmax/cycles；
- ASIC 综合报告（条件允许）：55/28/90nm 的 area/power/fmax；
- 技术报告 + 答辩材料 + 协作纪录。

### 1.4 指标

| 类别 | 目标 |
|:---|:---|
| 功能 | HQC-128 完整 KEM；官方 KAT 100/100；0 mismatch；隐式拒绝 |
| RTL | 全 RTL；SHAKE/采样/RS/RM/乘法/控制/接口 |
| FPGA | **板端全功能跑通 + KAT 100/100**；记录 LUT/FF/BRAM/Fmax/cycles；参考 SOCC 2023：19,794 LUT / 11,079 FF / 68 BRAM / 178 MHz |
| ASIC | 55nm 主 / 28nm 对比 / 90nm 兜底；综合 + area/power/fmax；**不流片** |
| 原创 | ASIC 多工艺评估 + 设计空间 + 参数化/开源可复现 |

---

## §2 当前状态

> 更新：2026-11-09。开工前按 `docs/workflow.md` 更新本节，并贴 ✅ / 🟡 / ⬜ 三类清单。

- ✅ 主题切换：完整 RTL HQC-128 KEM + FPGA/ASIC；
- ✅ 四人分工定稿：江力博（系统/验证/Vivado）、房煦然（对接/架构/验收）、骆弈宾（RTL-A）、曹子墨（RTL-B）；
- ✅ 近期任务与验收：`docs/13_开工清单与近期任务.md`；
- ✅ 官方 HQC 参考实现 vendor（`third_party/hqc`，commit `06567cc`，public domain）；
- ✅ KAT：keygen + decaps `PASS 100/100 (pk/sk/ss)`；C 黄金 `PASS 5/5`；
- ✅ 单路 `sparse_qc_mult` baseline；N=17669 折叠 3 组边界 `831/831`（旧分支 `hqc-baseline`）；
- ✅ 板卡选型：**AC701 XC7A200T 主**；XC7A100T 备；常州 200T 备用；
- ✅ 古法编程 + 契约冻结流程（`docs/workflow.md`、`skill/`）；
- ✅ 协作纪录统一到 `report/llm_log/`；`docs/records/` 已废弃删除；
- 🟡 `sparse_qc_mult` N=64 xsim `PASS 4/4`；N=17669 随机 1000 组未跑；
- ⬜ `encaps` 的 `ct` 字节级一致（需 NIST DRBG/OpenSSL）；
- ⬜ 模块契约未冻结（SHAKE/采样/RS/RM/乘法/KEM Top/AXI）；
- ⬜ SHAKE/采样/RS/RM 未实现；
- ⬜ KEM Top / 系统仿真未实现；
- ⬜ FPGA 板端全功能 + PPA 未开始；
- ⬜ ASIC 55/28/90nm 综合未开始。

---

## §3 阶段与硬闸门（半年排期）

> 对齐 `docs/14_总体工作计划.md`：2026-11-06 → 2027-05-31 完成交付，2027-06 只修 bug/答辩。
> 先完整 RTL + KAT，再 FPGA 全功能，最后 ASIC 综合评估；ASIC 不跑 P&R、不流片。

### P0 启动与基线（2026-11-06 ~ 2026-11-30）

- 官方参考实现、KAT、C 黄金、xsim 环境；
- 契约草案（SHAKE/采样/RS/RM/乘法/KEM Top/AXI）；
- 分支、任务、证据目录、板卡借用登记。

**闸门**：KAT `100/100 (pk/sk/ss)`；契约草案齐；分支/任务/证据目录就绪。

### P1 核心模块 RTL（2026-12-01 ~ 2027-01-31）

- **第 1 周先冻结契约**；契约未冻结不写 RTL/C/脚本；
- 骆弈宾：SHAKE256/Keccak、固定重量采样、KEM 控制 FSM；
- 曹子墨：稀疏乘法、RS 编解码、RM FHT、重复合并；
- 江力博：系统仿真框架、Vivado 环境、周五 xsim/综合；
- 房煦然：KAT/C 黄金、契约冻结、验收清单、差异表。

**闸门**：模块 tb `PASS`；稀疏乘法 N=17669 随机 1000 组 0 mismatch。

### P2 完整 RTL 集成（2027-02-01 ~ 2027-03-15）

- KEM Top + FO + 隐式拒绝；
- 系统仿真（C 调度 + RTL 模块）；
- 完整 RTL KAT 对拍；
- 负向测试：篡改密文 → 隐式拒绝。

**闸门**：完整 RTL KAT `100/100`；0 mismatch；负向通过。

### P3 FPGA 全功能跑通 + PPA（2027-03-16 ~ 2027-04-30）

- **AC701 XC7A200T** bring-up（预留 4–6 周）；
- 板端 KeyGen/Encaps/Decaps + KAT `100/100`；
- Vivado 综合/实现/时序/资源；
- LUT/FF/BRAM/DSP/Fmax/cycles/WNS/WHS 入档。

**闸门**：板端 = 仿真；KAT `100/100`；PPA 报告可复现。

### P4 ASIC 综合评估（条件，2027-05-01 ~ 2027-05-15）

- 55nm 主 / 28nm 对比 / 90nm 兜底；
- 综合 + area/power/fmax；
- 工具可用才做；**不跑 P&R、不流片**；没有工具就写降级说明，不伪造数据。

**闸门**：ASIC 数据入档，或“条件未满足 + 后续计划”。

### P5 收尾/答辩（2027-05-16 ~ 2027-05-31）

- 技术报告、答辩 PPT、复现入口；
- 代码冻结（2027-05-24）、材料冻结（2027-05-31）；
- 2027-06 只修 bug/答辩，不加功能。

**闸门**：全套材料提交；`main` 冻结；仓库内命令可复现。

---

## §4 里程碑

| 里程碑 | 时间 | 交付 | 验收 |
|:---|:---|:---|:---|
| M0 基线 | 2026-11-30 | 参考实现、KAT、契约草案 | KAT `100/100 (pk/sk/ss)` |
| M1 模块 RTL | 2027-01-31 | SHAKE/采样/RS/RM/乘法 | 模块 tb `PASS`；0 mismatch |
| M2 完整 RTL | 2027-03-15 | KEM Top、系统仿真 | 完整 KAT `100/100`；0 mismatch |
| M3 FPGA | 2027-04-30 | 板端全功能 + PPA | 板端 KAT `100/100`；PPA 报告 |
| M4 ASIC（条件） | 2027-05-15 | 55/28/90nm 综合 | area/power/fmax 或降级说明 |
| M5 收尾 | 2027-05-31 | 报告/答辩/冻结 | 全套材料 |
| 缓冲 | 2027-06 | 只修 bug/答辩 | 不加功能 |

---

## §5 接口与契约

| 契约 | 内容 | 状态 |
|:---|:---|:---|
| `hqc_kem_v0.md` | KEM API、全 RTL 模块、数据格式、KAT | 草案（全 RTL） |
| `sparse_qc_mult_v0.md` | 稠密/稀疏、接口、延迟 | 草案 |
| `rm_decoder_v0.md` | RM FHT、重复合并 | 草案 |
| `axi_mmio_v0.md` | AXI4-Lite/BRAM | 草案 |
| 待建 | `sha3_v0.md`、`sampler_v0.md`、`rs_codec_v0.md` | 未建 |

**冻结规则**：模块 RTL 开始前冻结对应契约；冻结后改动同步所有依赖。

---

## §6 风险与取舍

| 风险 | 影响 | 应对 |
|:---|:---|:---|
| 完整 RTL 工作量大 | 做不完 | 先 HQC-128；模块并行；每周集成 |
| **FPGA 全功能跑通难** | 板级/时序/外设拖时间 | 主 AC701 200T；先仿真后上板；预留 4–6 周 bring-up |
| **板卡借用冲突** | 无法板级验收 | 备选 100T / 常州 200T；P0 预约 P3 窗口 |
| ASIC 工具不确定 | 无法做 ASIC | 假设至少一种可用；没有就降级为 ASIC 导向 RTL + FPGA PPA |
| 团队无 ASIC 经验 | 流程踩坑 | 只做综合评估；找师兄/老师带；不碰 P&R |
| SHAKE/RS 自研周期长 | 主线延期 | 先复用公开 IP 或 C 黄金对拍；RTL 逐步替换 |
| KAT 字节级对不上 | 无法证明完整 | 全用官方参考；先 pk/sk/ss，再补 encaps |
| 组内已做 FPGA 完整 KEM | 原创性弱 | 差异点放 ASIC 多工艺/设计空间/开源；写差异表 |
| 只有一台 Vivado | 单点瓶颈 | 江力博平台 owner；周五批处理；第二人装免费 Vivado |

---

## §7 原创性与创新得分点

组内 SOCC 2023 已做：稀疏乘法、RM FHT、RS ePIBM、完整 FPGA KEM。
**这四项不能当原创。**

| 候选增量 | 说明 | 证明 |
|:---|:---|:---|
| **ASIC 多工艺综合（55/28/90nm）** | 组内是 FPGA-only | 三个节点的 area/power/fmax |
| **FPGA/ASIC 设计空间** | 字宽/并行度/存储/流水线 | Pareto |
| **参数化/开源可复现** | HQC-128/192/256 + KAT + 脚本 | 仓库一键复现 |
| RISC-V 集成（可选） | 可编程 SoC | 接口/KAT |
| 恒定时间（可选） | 安全增强 | 侧信道实验 |

**不能写**：“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”“FPGA 全跑通是我们的创新”。
**FPGA 全功能跑通是硬目标，但组内 SOCC 2023 已做；国家级增量靠 ASIC 多工艺/设计空间/参数化/开源。**

---

## §8 团队分工

| 成员 | 角色 | 负责 | 交付 | 备注 |
|:---|:---|:---|:---|:---|
| **江力博** | 项目负责人 / FPGA 与系统集成 | 进度、Vivado 平台 owner、FPGA bring-up、系统仿真、PPA、repo/CI、ASIC 协调 | FPGA 板级日志、系统仿真、PPA 报告、周报 | **不写 RTL**；总览项目 |
| **房煦然** | 与老师对接 / 需求与验证 | 需求/范围、架构/契约、老师沟通、**C/C++ 黄金 + KAT/验证**、原创性/差异表、验收/答辩 | 需求文档、契约、KAT 日志、差异表、验收清单 | **不写 RTL**；总览项目 |
| **骆弈宾** | RTL-A：协议/SHAKE/控制 | SHAKE256/Keccak、固定重量采样、KEM/PKE 控制 FSM、FO/隐式拒绝 | RTL、tb、KAT 对拍 | RTL 主力 |
| **曹子墨** | RTL-B：算术/解码 | 稀疏乘法、RS 编解码、RM FHT、重复合并 | RTL、tb、PPA | RTL 主力 |

**硬分工**：

- **RTL 线由骆弈宾、曹子墨负责**；江力博不写 RTL，负责 FPGA bring-up / Vivado / 系统集成 / PPA。
- 房煦然不写 RTL，负责 C/C++ 黄金 + KAT/验证 + 需求/架构/契约/老师对接/验收/原创性。
- 江力博与房煦然共同维护 `plan.md` / `README.md` / `docs/`，确保两人了解全项目。
- 当前只有江力博的机器有 Vivado：他是 Vivado 平台 owner，周五统一跑 xsim + OOC 综合；其他人用 iverilog/Verilator 预检。
- 详细任务与验收见 `docs/13_开工清单与近期任务.md`。

### §8.1 RTL 线阶段分工与验收

> RTL 线只由 **骆弈宾（RTL-A）**、**曹子墨（RTL-B）** 写。
> 江力博负责系统集成/Vivado/PPA；房煦然负责契约、KAT/C 黄金、验收。
> **契约未冻结，不写 RTL；每步按古法编程，≤100 行，出题通过再继续。**

#### A. RTL 线职责边界

| 成员 | RTL 线 | 负责模块 | 不负责 |
|:---|:---|:---|:---|
| **骆弈宾** | RTL-A：协议/SHAKE/控制 | `sha3/keccak`、`sampler`、`hqc_kem_top`（KeyGen/Encaps/Decaps、FO、隐式拒绝）、`axi_mmio` | 稀疏乘法、RS/RM、FPGA 板级/PPA |
| **曹子墨** | RTL-B：算术/解码 | `sparse_qc_mult`、`rs_codec`、`rm_codec`（FHT+重复合并） | SHAKE/采样、KEM 控制、板级/PPA |

#### B. 分阶段任务与验收

| 阶段 | 时间 | 骆弈宾（RTL-A） | 曹子墨（RTL-B） | 阶段验收 |
|:---|:---|:---|:---|:---|
| **P0 契约** | 2026-11 | 起草 `sha3_v0`、`sampler_v0`；不写 RTL | 起草 `rs_codec_v0`；更新 `sparse_qc_mult_v0`、`rm_decoder_v0`；不写 RTL | 契约草案完成、评审通过、冻结记录 |
| **P1 模块** | 2026-12 ~ 2027-01 | SHAKE256/Keccak、固定重量采样、KEM 控制 FSM 第一版 | 稀疏乘法、RS 编码/解码、RM FHT、重复合并第一版 | 模块 tb 通过；稀疏乘法 1000 组随机 0 mismatch；SHAKE/采样/RS/RM 对官方向量 PASS |
| **P2 集成** | 2027-02 ~ 2027-03-15 | KEM Top、FO、隐式拒绝、AXI/MMIO 集成 | 乘法/RS/RM 接口集成、周期初测 | 完整 RTL KAT 100/100；系统仿真 0 mismatch；负向测试通过 |
| **P3 FPGA** | 2027-03-16 ~ 2027-04-30 | 控制/SHAKE 时序优化；板端调试支持 | 乘法/RS/RM 时序优化；板端调试支持 | 板端全功能跑通 + KAT 100/100；LUT/FF/BRAM/Fmax/cycles 入档 |
| **P4 ASIC** | 2027-05-01 ~ 2027-05-15 | ASIC 导向检查（无 FPGA 原语）、参数化 | 设计空间（字宽/1-2-4-8 路/BRAM banking） | 55/28/90nm 综合数据；Pareto 初稿 |
| **P5 冻结** | 2027-05-16 ~ 2027-05-31 | 代码冻结、模块 README/注释补齐 | 代码冻结、PPA/设计空间归档 | 冻结 commit；报告/答辩材料可复现 |

#### C. 模块级验收矩阵

| 模块 | 负责人 | 冻结契约 | 验证方式 | 通过标准 |
|:---|:---|:---|:---|:---|
| `sha3/keccak` | 骆弈宾 | `sha3_v0.md` | 官方 SHAKE/XOF 向量 | `PASS: N/N` |
| `sampler` | 骆弈宾 | `sampler_v0.md` | 官方 KAT 采样 | 与官方位置/字节一致 |
| `hqc_kem_top` | 骆弈宾 | `hqc_kem_v0.md` | 官方 KAT + 负向 | 100/100；隐式拒绝正确 |
| `axi_mmio` | 骆弈宾 | `axi_mmio_v0.md` | 系统 tb / 寄存器读写 | 读写/中断/错误行为符合契约 |
| `sparse_qc_mult` | 曹子墨 | `sparse_qc_mult_v0.md` | C 黄金 + 随机 | 1000 组 0 mismatch |
| `rs_codec` | 曹子墨 | `rs_codec_v0.md` | `rs.tv` | `PASS: N/N` |
| `rm_codec` | 曹子墨 | `rm_decoder_v0.md` | 官方 RM 向量 | 逐块一致 |
| 系统仿真 | 江力博 | `hqc_kem_v0.md` | 完整 RTL KAT | 100/100；0 mismatch |
| FPGA PPA | 江力博 | — | Vivado 综合/实现 | 资源/时序/周期入档 |
| 验收签字 | 房煦然 | 全部契约 | 按本表逐项核对 | 证据齐全、可复现 |

#### D. 交付与证据规则

- 每个模块必须有：冻结契约、RTL、自检 tb、日志、协作纪录。
- 每步结束四件套：改了哪些文件、验证命令与原始结果、`git diff --check`、未完成清单。
- 接口/格式变更必须三处同步：RTL、tb/系统仿真、C 黄金/KAT/脚本、契约。
- 周五集成：骆/曹交 RTL 与 tb → 江力博跑 xsim/综合/板端 → 房煦然验收。
- 没有“PASS”证据的模块，不算完成；没有冻结契约的模块，不许开工。

---

## §9 维护规则

- 本文件管全项目目标、里程碑、验收；
- 每次里程碑结束更新 §2，并在 `report/llm_log/` 留证据；
- 任何“已完成”必须有仓库内命令可复现；
- 完整 RTL + KAT 是 V0 硬闸门；FPGA 全功能跑通（V1）是硬目标；ASIC（V2）是条件阶段，不跑 P&R、不流片；
- 2027-06 只修 bug/答辩，不加功能。
