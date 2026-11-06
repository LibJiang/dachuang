# HQC 技术路线与原创点

> 本文是 HQC KEM 大创的技术主线。读完后应能回答：
> ① HQC 在算什么；② 瓶颈在哪；③ 为什么稀疏结构能救乘法；④ 你的原创点是什么。
> 参数、填充、重复码等细节**以官方 HQC spec 与参考实现为准**；本文只给工程所需的全局图。

---

## 一、HQC 是什么

HQC（Hamming Quasi-Cyclic）是**基于准循环码的 KEM**，NIST 于 2025 年将其选为第五个后量子密码标准算法。它的安全性来自“解码随机准循环码”的困难性，属于**码密码**，不是格密码。

| 维度 | HQC | Kyber |
|:---|:---|:---|
| 困难问题 | 准循环码解码 | Module-LWE |
| 运算域 | $\mathrm{GF}(2)[X]/(X^n-1)$ | $\mathbb{Z}_q$，$q=3329$ |
| 核心 | 准循环乘法 + RM/RS 解码 | NTT + 模约减 |
| 你的旧论文 | 不适用 | FLUT+KRED |

**结论**：Kyber 的 FLUT+KRED 不能直接搬；但“从算法结构里找硬件简化”的方法完全适用。

---

## 二、参数与码结构

| 参数集 | n | k（字节） | w | w_r | w_e | RS 的 n1 |
|:---|:---|:---|:---|:---|:---|:---|
| HQC-128 | 17669 | 16 | 66 | 75 | 75 | 46 |
| HQC-192 | 35851 | 24 | 100 | 114 | 114 | 56 |
| HQC-256 | 57637 | 32 | 131 | 149 | 149 | 90 |

- `w`：私钥 x / y 的固定重量；
- `w_r`：加密随机向量 r1 / r2 的固定重量；
- `w_e`：误差 e 的固定重量；
- 码：Reed-Solomon（GF(2⁸)）× Reed-Muller RM(1,7)[128,8,64] × 重复码；
- `n` 为素数，级联码长度略小于 n，存在填充/缩短规则，**以官方 spec 为准**。

---

## 三、KEM 流程

### KeyGen

1. 生成种子，采样 x、y（重量 w）；
2. 生成稠密 h；
3. `s = x + h·y`（dense × sparse）；
4. 输出 `pk = (h, s)`，`sk = (x, y)`。

### Encaps

1. 随机 m；SHAKE 生成 r1、r2、e；
2. `u = r1 + h·r2`（dense × sparse）；
3. `v = Encode(m) + s·r2 + e`（dense × sparse）；
4. `c = (u, v)`；`K = SHAKE(m || c)`。

### Decaps

1. `w = v - u·y`（dense × sparse）；
2. 重复合并 → RM FHT → RS 解码 → m'；
3. 用 m' 重加密得 c'；
4. 常数时间比较 `c == c'`：成功走 `K = SHAKE(m' || c)`，失败走隐式拒绝 `K = SHAKE(σ || c)`。

> **注意**：Decaps 有一次重加密，所以稀疏乘法与 FHT 各跑两次；延迟预算按两次算。

---

## 四、瓶颈与硬件映射

| 运算 | 复杂度 | 硬件映射 | V0 放置 |
|:---|:---|:---|:---|
| GF(2) 准循环乘法 | 朴素 $O(n^2)$；稀疏 $O(wn)$ | 循环移位 + XOR 累加 + 折叠 | **PL** |
| RM(1,7) 解码 | 每 128 bit 448 次加/减 | 128 点 FHT | **PL** |
| RS 解码 | GF(2⁸) BM/Chien/Forney | LUT/复合域乘法 | PS |
| SHAKE256 | Keccak-f[1600] | 专用核/软件 | PS |
| 固定重量采样 | 拒绝采样/位置生成 | 软件/恒定时间采样器 | PS |

### 关键结构性质 → 硬件

| HQC 性质 | 硬件含义 |
|:---|:---|
| GF(2)，无进位 | 乘法 = AND，加法 = XOR，无进位链 |
| $X^n \equiv 1$ | 高 half 循环折叠回低 half |
| 私钥/误差固定重量稀疏 | **dense × sparse：按位置移位-异或，$O(wn)$** |
| RM(1,7) 是 Hadamard 结构 | 解码 = 128 点快速 Hadamard 变换 |
| RS 在 GF(2⁸) | 查表/复合域乘法，BM 迭代 |
| 重复码 | 软值合并/多数表决 |

---

## 五、推荐架构（V0：混合 KEM）

```mermaid
flowchart LR
    PS[PS / ARM Cortex-A9<br/>SHAKE、采样、RS、FO、控制] -->|AXI4-Lite| CTRL[命令/状态]
    PS <-->|AXI/BRAM| MEM[多项式 BRAM<br/>h,s,u,v,x,y,r1,r2,e]
    CTRL --> SM[稀疏 QC 乘法器<br/>dense × sparse]
    CTRL --> RM[RM(1,7) FHT 解码器<br/>+ 重复合并]
    SM <--> MEM
    RM <--> MEM
    SM --> XOR[循环折叠 / 向量 XOR]
    XOR <--> MEM
```

### 模块清单

| 模块 | 功能 | 阶段 |
|:---|:---|:---|
| `sparse_qc_mult` | dense×sparse，移位-异或-折叠 | B |
| `dense_qc_mult_baseline` | 朴素 $O(n^2)$，只做对照 | B |
| `gf2_vec` | XOR、循环移位、位置表读取 | B |
| `rm_fht128` | 128 点 FHT | C |
| `repetition_combine` | 3/5 份重复软值合并 | C |
| `rm_encoder` | 8 bit → 128 bit | C |
| `rs_decoder` | GF(2⁸) BM/Chien/Forney | C（或 PS） |
| `keccak` | SHAKE256 | C（或 PS） |
| `hqc_ctrl` | 命令 FSM、地址、DMA | B/C |

---

## 六、为什么稀疏乘法是核心（但不是原创点）

> **重要**：组内 SOCC 2023 和 LEAP [8] 已经做了稀疏乘法；本节只解释它为什么是核心，
> **不把“稀疏乘法算法”本身当原创**。我们的增量在参数化/设计空间/系统集成。

HQC 的所有乘法都有一个**固定重量稀疏操作数**：

- KeyGen：`h·y`，y 重量 w；
- Encaps：`h·r2`、`s·r2`，r2 重量 w_r；
- Decaps：`u·y`，y 重量 w。

因此：

\[
a \cdot b = \bigoplus_{p \in \mathrm{supp}(b)} (a \lll p) \pmod{X^n-1}
\]

复杂度从 $O(n^2)$ 降到 $O(wn)$。以 HQC-128 为例：

- 朴素：$17669^2 \approx 3.1 \times 10^8$ 次 bit 运算；
- 稀疏：$75 \times 17669 \approx 1.33 \times 10^6$ 次 XOR，约 **两个数量级** 的下降。

**架构研究点（这些才是可写的增量）**：

1. 并行路数 L（1/2/4/8/16）与 BRAM 端口/ banking 的权衡；
2. 循环移位实现：桶形移位 vs 地址偏移 vs 位平面；
3. 位置表存储与读取（升序、无重复、16 bit）；
4. 循环折叠与累加的顺序；
5. 面积-时间 Pareto 与能效；
6. 与 RISC-V 的接口（MMIO/自定义指令）和软硬划分。

---

## 七、原创性与组内基线

> **必读**：田静组 2023 年 SOCC 论文
> “An Efficient Hardware Design for Fast Implementation of HQC”（`docs/01` 论文 #15，DOI 10.1109/SOCC58585.2023.10257054）。
> **组内已经做了**：稀疏乘法、128-bit/4-bank、RM FHT、RS ePIBM、完整 HQC-128 KEM。
> 结果：19,794 LUT / 11,079 FF / 68 BRAM / 178 MHz；KeyGen/Encap/Decap = 0.11/0.22/0.38 ms。
> **所以不能把上述点当原创。** 详细差异见 `docs/11_组内基线与差异表.md`。

建议的贡献表述（候选，需查新确认）：

1. **RISC-V + HQC 协处理器**：组内是固定硬件 KEM；我们做可编程 SoC 集成；
2. **参数化稀疏乘法设计空间**：1/2/4/8 路、64/128-bit、BRAM banking 的 Pareto；
3. **混合软硬协同 + C/RTL 协同仿真**：完整 KAT + 延迟分解；
4. **HQC-192/256 参数化**（增量）；
5. **恒定时间/故障检测**（选做，安全方向）。

**贡献边界表**必须出现在立项书和最终报告里；复现不能写成原创。
**不要写**：“首次实现 HQC 硬件”“稀疏乘法是我们的创新”“完整 KEM 是我们的创新”。

---

## 八、验证路线（仿真优先）

> 上板不是 V0 闸门。先把 L0–L4 在 C/C++ + xsim + 综合里跑通，再决定是否上板。

| 层级 | 对象 | 方法 | 通过标准 |
|:---|:---|:---|:---|
| L0 | C/C++ 黄金 | 独立实现 + 官方参考 | 逐 bit 一致 |
| L1 | 稀疏乘法 | 随机 dense + 稀疏位置 | 与黄金一致 |
| L2 | RM FHT | 随机 128 bit 块 | 与参考解码一致 |
| L3 | KeyGen/Encaps | 官方 KAT | 逐字节一致 |
| L4 | Decaps | KAT + 负向 + 隐式拒绝 | 逐字节一致；失败路径正确 |
| L5 | 系统协同仿真 | C 调度 + RTL 模块 | ≥10 组端到端 KAT 全过 |
| L6 | 综合/PPA | Vivado OOC | 资源/时序/周期数入档 |
| L7 | 上板（可选） | PYNQ 灌数/读回 | 板端 = 仿真；延迟/资源入档 |

国家级指标与证据口径见 `docs/10_团队分工与国家级指标.md`。

---

## 九、风险

- **范围**：完整 KEM + 多参数 + 全 RTL 做不完 → V0 只 HQC-128 + 混合。
- **KAT**：采样/填充/字节序必须官方；否则永远对不上。
- **RS/Keccak**：自研成本高 → V0 放 PS。
- **组内基线**：SOCC 2023 必须先读；否则原创性边界不清。
- **侧信道**：稀疏位置是秘密；V0 文档标注，C+ 再做恒定时间/地址混淆。
- **自研核**：不设为 V0 前置；C 阶段选做。

---

## 十、参考

- HQC 官方 spec 与参考实现（NIST 提交包 / HQC 官网）。
- 田静组论文 #15：An Efficient Hardware Design for Fast Implementation of HQC（SOCC 2023）。
- 田静组论文 #1/#2：Kyber 多项式乘法 / 可配置乘法器（方法论参考）。
- 田静组论文 #6：Kyber 模约减（“算法性质 → 硬件结构”的写法参考）。
- 本仓库：`docs/contracts/`、`docs/09_工程约束与验证规范.md`。
