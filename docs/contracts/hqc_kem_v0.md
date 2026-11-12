# hqc_kem_v0 —— 完整 RTL HQC KEM 契约（草案）

> 状态：**草案**，V0 架构冻结前完成。
> 目标：HQC-128 的 **全 RTL** KeyGen / Encaps / Decaps + FO + 隐式拒绝；
> 官方 KAT 100/100；系统仿真 0 mismatch；**FPGA 板端全功能跑通**。
>
> 主题：完整 RTL → **FPGA 全功能跑通（硬目标）** + ASIC 综合评估（55/28/90nm，条件阶段；不流片）。
> 参考实现：`third_party/hqc/`（public domain，commit `06567cc`）。

---

## 1. API（RTL 侧抽象）

```text
keygen  : start_keygen  -> pk[2241B], sk[32B]
encaps  : start_encaps(pk) -> ct[4433B], ss[32B]
decaps  : start_decaps(sk, ct) -> ss[32B]
```

- 字节长度以官方 HQC-1 头文件为准；
- 所有模块在 PL 内；Host/Testbench 只负责灌 KAT、读结果；
- 不依赖 PS 做 SHAKE/RS/采样（与旧混合方案不同）。

---

## 2. 全 RTL 模块

| 模块 | 职责 | 负责人 |
|:---|:---|:---|
| `sha3_shared` | **三阶段共享 SHAKE256/Keccak**、XOF、PRNG | 骆弈宾 |
| `sampler` | 固定重量采样（w/w_r/w_e），常数时间 | 骆弈宾 |
| `poly_mult` | **低延迟 dense×sparse 主方案**（Karatsuba/Toom-Cook 仅为示例） | 曹子墨 |
| `sparse_qc_mult` | dense×sparse 核心实现（主方案） | 曹子墨 |
| `rs_codec` | RS 编码 + **ePIBM** 解码 | 曹子墨 |
| `rm_codec` | RM 编码 + FHT + 重复合并 | 曹子墨 |
| `hqc_kem_top` | KeyGen/Encaps/Decaps、FO、隐式拒绝、**常数时间比较** | 骆弈宾 |
| `axi_mmio` | 寄存器/BRAM/DMA | 骆弈宾 |

> **恒定时间是必做项**：FO 重加密比较、采样、解码、稀疏访问不得有秘密相关分支/提前返回；评估口径见 `docs/09`。

---

## 3. 数据格式

- 稠密多项式：n bit，`bit i = X^i` 系数；
- 稀疏多项式：位置列表（升序、无重复）；
- 字节序/填充/KAT：**以官方参考实现为准**；
- `sk` 是 32 B master seed；keygen 必须能从 `sk` 确定性重建 `pk`；
- `ct` 4433 B，`ss` 32 B（HQC-1）。

---

## 4. KAT 与验证

| 测试 | 方法 | 通过标准 |
|:---|:---|:---|
| keygen | 官方 KAT `sk` → `pk/sk` | 100/100 |
| decaps | 官方 KAT `sk/ct` → `ss` | 100/100 |
| encaps | 需要 NIST DRBG/OpenSSL | 待补 |
| 系统仿真 | 完整 RTL + KAT | 100/100，0 mismatch |
| 负向 | 篡改 ct | 隐式拒绝 |
| 常数时间 | 比较耗时 | V0 人工审查；V1 形式化 |

当前 A1 已通过 keygen + decaps 100/100（见 `models/kem/harness`）。

---

## 5. 性能/PPA 口径

| 指标 | 口径 |
|:---|:---|
| FPGA | LUT/FF/BRAM/DSP/Fmax/cycles；Vivado 综合/实现 |
| ASIC（条件） | area/power/fmax；综合，不跑 P&R |
| 延迟 | KeyGen/Encaps/Decaps 的 cycles 与 ms |
| 对比 | SOCC 2023（FPGA-only）作为基线；不承诺超过 |

> 所有指标必须注明：仿真 / FPGA 综合 / ASIC 综合，三者不可混写。

---

## 6. 错误处理

- 非法参数/越界 → `error=1`，不进入计算；
- 解密失败 → 隐式拒绝，不返回错误码给外部区分；
- AXI 超时 → 返回非 0，不得返回未初始化密钥。

---

## 7. 未决问题

- [ ] Keccak/SHAKE RTL：自研还是复用公开 IP（许可证）
- [ ] 采样器：拒绝采样 vs 恒定时间采样
- [ ] RS 解码：ePIBM vs BM；是否先复用公开 IP
- [ ] ASIC 工具（DC/Genus/OpenROAD）；PDK 已确认 55/28/90nm
- [ ] HQC-192/256 是否进 V0（默认不进）
- [x] FPGA 板端全功能跑通：**硬目标**（老师已确认）；主 AC701 XC7A200T
- [x] ASIC 不流片，只做综合评估
