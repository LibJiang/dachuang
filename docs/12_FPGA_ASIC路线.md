# HQC KEM 的 FPGA/ASIC 实现路线

> 主题变更：从“PS+PL 混合、仿真优先”改为 **完整 RTL 的 HQC KEM 实现**，
> 目标是 **FPGA 原型 + ASIC 综合评估**。
> 状态：路线草案；A1 的官方参考实现/KAT 已跑通（keygen+decaps 100/100）。
> 相关：`docs/11_组内基线与差异表.md`、`third_party/hqc/VENDORED.md`、`models/kem/harness/`。

---

## 1. 为什么换

- 组内 SOCC 2023 已经做了 **FPGA 完整 HQC-128 KEM**（稀疏乘法 + FHT + ePIBM + SHAKE）。
- 老师选题简介要求：**低延迟乘法器结构**（Karatsuba/Toom-Cook 仅示例）、ePIBM/FHT、SHAKE 三阶段复用、恒定时间；这些是基线，不是我们的原创。
- 继续做“混合 PS+PL”很难形成国家级增量；**完整 RTL + ASIC 评估**是更明确的差异点。
- ASIC 方向能回答组内论文没回答的问题：面积、功耗、频率、能效，以及 FPGA/ASIC 设计空间。
- 代价：工作量大、ASIC 工具/PDK 不确定、团队没有 ASIC 经验。因此 ASIC 设为**条件阶段**，不是 V0 硬闸门。

---

## 2. 范围分层

| 层级 | 内容 | 是否硬闸门 |
|:---|:---|:---|
| **V0 完整 RTL** | HQC-128 KeyGen / Encaps / Decaps 全 RTL；**三阶段共享 SHAKE**、采样、RS ePIBM、RM FHT、**低延迟 dense×sparse 乘法**、控制、**恒定时间比较** | ✅ |
| **V0 验证** | C/C++ 官方参考 KAT；RTL 系统仿真；100/100 KAT；恒定时间评估 | ✅ |
| **V1 FPGA** | **板端全功能跑通 + KAT 100/100** + Vivado PPA | ✅ **硬目标** |
| **V2 ASIC** | 55nm 主 / 28nm 对比 / 90nm 兜底；综合 + area/power/fmax | 🟡 条件允许 |
| **V3 ASIC P&R** | DRC/LVS/signoff/流片 | ⬜ **明确不做（老师已确认不流片）** |

**V0 不做**：掩码/侧信道、MPW、全参数集 192/256（先 HQC-128）。

---

## 3. 完整 RTL 架构

```text
                    ┌─────────────────────────────────────────┐
                    │              HQC-128 KEM Top            │
                    │  KeyGen / Encaps / Decaps control FSM   │
                    └───────┬───────────┬───────────┬─────────┘
                            │           │           │
                     ┌───────▼───┐ ┌─────▼─────┐ ┌───▼────────┐
                     │ Shared    │ │ Sampler   │ │ RS Enc/Dec │
                     │ SHAKE256  │ │ fixed wt  │ │ ePIBM      │
                     └───────────┘ └───────────┘ └───┬────────┘
                                                    │
                     ┌───────────┐ ┌───────────┐ ┌───▼────────┐
                     │ Low-lat.  │ │ RM FHT    │ │ Repetition │
                     │ d×s mult  │ │ Decoder   │ │ Combine    │
                     └───────────┘ └───────────┘ └────────────┘
                            │
                    ┌───────▼─────────────────────────────────┐
                    │ BRAM / AXI4-Lite / MMIO / 控制寄存器     │
                    └─────────────────────────────────────────┘
```

模块清单：

| 模块 | 职责 | 负责人 |
|:---|:---|:---|
| `sha3_shared` | 三阶段共享 SHAKE256/Keccak、XOF、PRNG | A |
| `sampler` | 固定重量采样（w/w_r/w_e），常数时间 | A |
| `poly_mult` | **低延迟 dense×sparse 主方案**（Karatsuba/Toom-Cook 仅为示例） | B |
| `sparse_qc_mult` | dense×sparse 核心实现（主方案） | B |
| `rs_codec` | RS 编码 + ePIBM 解码 | C |
| `rm_codec` | RM 编码 + FHT 解码 + 重复合并 | C |
| `hqc_kem_top` | KeyGen/Encaps/Decaps 控制、FO、隐式拒绝、**常数时间比较** | A/C |
| `axi_mmio` | 寄存器/BRAM/DMA（V1） | C |
| `tb/golden` | C 黄金、KAT、系统仿真、PPA | D |

---

## 4. 四人分工（调整版）

> 只有一台 Vivado：B 兼任 Vivado 平台 owner。

| 角色 | 负责 | 备注 |
|:---|:---|:---|
| **A 协议与 SHAKE/采样** | KEM/PKE 控制、FO、隐式拒绝、**三阶段共享 SHAKE256**、固定重量采样、**常数时间比较** | 不需要 Vivado |
| **B 低延迟乘法 + Vivado** | **低延迟 dense×sparse 主方案**、存储、设计空间；xsim/综合/PPA | RTL-B 主责 |
| **C RS/RM 数据通路** | RS ePIBM、RM FHT、重复合并、AXI/MMIO | 可用 iverilog 预检 |
| **D 验证与评测** | KAT、C 黄金、随机向量、回归、**恒定时间评估**、报告、ASIC 评估 | 与 A/C 配合 |

---

## 5. 里程碑（半年排期）

| 里程碑 | 时间 | 交付 | 验收 |
|:---|:---|:---|:---|
| M0 基线 | 2026-11-30 | 参考实现、KAT、契约草案 | KAT `100/100 (pk/sk/ss)` |
| M1 模块 RTL | 2027-01-31 | SHAKE/采样/RS/RM/乘法 | 模块 tb `PASS`；0 mismatch |
| M2 完整 RTL | 2027-03-15 | KEM Top、系统仿真 | 完整 KAT `100/100`；0 mismatch |
| M3 FPGA | 2027-04-30 | 板端全功能 + PPA | 板端 KAT `100/100`；LUT/FF/BRAM/Fmax/cycles |
| M4 ASIC（条件） | 2027-05-15 | 55/28/90nm 综合 | area/power/fmax 或降级说明 |
| M5 收尾 | 2027-05-31 | 报告/答辩/冻结 | 全套材料 |

---

## 6. 指标

### 6.1 功能

- HQC-128 完整 KEM，**全 RTL**；
- 官方 KAT **100/100**（先 keygen+decaps，再补 encaps ct）；
- RTL 系统仿真 100/100；0 mismatch；
- 负向：篡改 ct → 隐式拒绝；
- **恒定时间**：FO 比较/采样/解码/位置访问无秘密相关分支。

### 6.2 FPGA（V1）

| 指标 | 目标 |
|:---|:---|
| 器件 | **AC701 XC7A200T（主）**；小梅哥 XC7A100T（备）；常州 200T（备用） |
| 资源 | 参考 SOCC 2023：19,794 LUT / 11,079 FF / 68 BRAM / 178 MHz（xc7a200t-3） |
| **全功能跑通** | **板端 KeyGen/Encap/Decap + KAT 100/100** |
| 我们的目标 | 先做到“能放、能跑、KAT 过”，再谈优化；不承诺超过论文 |
| 周期/延迟 | KeyGen/Encap/Decap 的 cycles 与 ms |
| PPA | LUT/FF/BRAM/DSP/Fmax/cycles |

### 6.3 ASIC（V2，条件）

| 指标 | 目标 |
|:---|:---|
| 流程 | 综合 + area/power/fmax 评估（**不跑 P&R、不流片**） |
| PDK | **55nm 主 / 28nm 对比 / 90nm 兜底** |
| 工具 | 待确认；假设至少一种（DC/Genus/OpenROAD） |
| 输出 | 面积、功耗、频率、能效；与 FPGA 对比 |
| 风险 | 团队无 ASIC 经验；没有工具就降级为 ASIC 导向 RTL + FPGA PPA |

---

## 7. 原创性边界

组内 SOCC 2023 已做：稀疏乘法、FHT、ePIBM、完整 FPGA KEM。
**这些不能当原创。**

老师选题简介要求：低延迟乘法器结构（Karatsuba/Toom-Cook 仅示例）、ePIBM/FHT、SHAKE 三阶段复用、恒定时间。**这些也是基线，不能当原创。**

我们的候选增量：

1. **ASIC 多工艺综合（55/28/90nm）**（组内论文是 FPGA-only）；
2. **低延迟 dense×sparse FPGA/ASIC 设计空间**（LANES/BRAM/移位/流水线 Pareto）；
3. **SHAKE 共享/独立 + 恒定时间开销的联合评估**；
4. **参数化/开源可复现**（HQC-128/192/256 + 官方 KAT + 脚本 + 证据链）；
5. 可选：RISC-V 集成。

**不能写**：“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”“FPGA 全跑通是我们的创新”“低延迟乘法结构是我们的创新”“SHAKE 复用是我们的创新”“恒定时间是我们的创新”。

---

## 8. ASIC 可行性与风险

- 实验室有 **28/90/55nm PDK**（老师已确认）；**工具待确认**，假设至少有一种；
- 推荐主节点 **55nm**：比 28nm 成熟、工具/库更稳；比 90nm 更有面积/频率说服力；
- 28nm 作为对比；90nm 作为兜底；三者都只做综合，不跑 P&R、不流片；
- 团队没人做过 ASIC 流程：只做综合评估，找师兄/老师带；不碰 P&R；
- 如果工具最终不可用，退回“FPGA 完整 RTL + PPA + ASIC 导向设计”，不伪造 ASIC 数据。

---

## 9. 待确认

- [ ] ASIC 工具（DC/Genus/OpenROAD？）
- [x] PDK：28/90/55nm 可用；主推 55nm
- [x] FPGA 板卡：AC701 XC7A200T 主；XC7A100T 备；常州 200T 备用
- [ ] 是否要 HQC-192/256（先做 HQC-128）
- [x] FPGA 全功能跑通：硬目标；ASIC 不流片
- [ ] 团队 ASIC 经验/师兄带
- [ ] 时间节点（立项/中期/结题）

---

## 10. 参考

- Chen Li et al., “An Efficient Hardware Design for Fast Implementation of HQC,” SOCC 2023.
- 官方 HQC 参考实现：<https://gitlab.com/pqc-hqc/hqc/>，commit `06567cc`。
- `docs/11_组内基线与差异表.md`
- `models/kem/harness/README.md`
