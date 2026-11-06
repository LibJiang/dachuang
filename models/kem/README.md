# 完整 KEM 软件基线（A 阶段）

> 目标：先跑通**官方 HQC-128 参考实现**，生成/校验官方 KAT，作为后续 RTL 加速的黄金基线。
> 状态：**骨架，A1 补齐**。本目录当前没有可运行的 HQC 代码。
> **仿真优先**：先在 PC / WSL 上跑通，再考虑 PYNQ；上板最后再定。

---

## 目录规划

```text
models/kem/
├─ README.md              # 本文件
├─ third_party/
│  └─ hqc/                # 官方参考实现（保留 LICENSE / 版本说明）
├─ harness/
│  ├─ kat_check.c         # 读 KAT，逐字节比较 pk/sk/ct/ss
│  ├─ roundtrip.c         # keygen -> encaps -> decaps
│  └─ bench.c             # 延迟/吞吐基线
└─ Makefile
```

---

## A1 任务

1. 从官方 HQC 提交包获取参考实现与 KAT（记录版本、SHA256、许可证）。
2. 在 PC 上编译，跑通 `PQCgenKAT_kem`，确认 `PASS`。
3. 交叉编译到 PYNQ-Z2 的 ARM（或直接在 PS 的 Linux 上编译）。
4. 写 `kat_check`：逐字节比较 `pk/sk/ct/ss`，输出 `PASS: N/N vectors`。
5. 写 `roundtrip`：keygen → encaps → decaps，比较共享密钥。
6. 写 `bench`：记录 KeyGen / Encaps / Decaps 的耗时（ARM 基线）。
7. 把原始日志放 `data/logs/YYYY-MM-DD-hqc-baseline/`。

---

## 硬约束

- **不要自己重写采样器/SHAKE/编码**：KAT 字节级一致依赖官方实现的每个细节。
- 官方代码的许可证必须保留；在 `third_party/hqc/LICENSE` 放原文件。
- 任何本地修改（如日志、计时）必须用 patch 形式记录，不得静默改算法。
- 与 PL 对拍时，PL 只替换 `vect_mul` 或 RM 解码；其余仍用官方代码。

---

## 与 `models/golden/` 的分工

| 目录 | 作用 |
|:---|:---|
| `models/golden/` | 独立算术黄金（稀疏乘法、FHT），用于 RTL 单模块对拍 |
| `models/kem/` | 官方完整 KEM 基线，用于 KAT 与端到端对拍 |

两者不能互相替代：黄金模型证明“算术对”，官方实现证明“协议对”。

---

## 待补信息

- [ ] 官方 HQC 参考实现版本 / spec 版本
- [ ] KAT 文件来源与 SHA256
- [ ] PYNQ-Z2 上的编译方式（本机 ARM / 交叉编译）
- [ ] 是否允许把官方代码 vendored 进仓库（许可证）
