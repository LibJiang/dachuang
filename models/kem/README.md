# 完整 HQC KEM 软件基线（A1）

> 目标：用官方 HQC 参考实现建立 KAT 基线，作为 RTL 的黄金。
> 状态：**A1 已跑通 keygen + decaps 的 100/100 KAT（pk/sk/ss）**；
> encaps 的 ct 字节级一致待补（需要 NIST DRBG/OpenSSL）。

---

## 目录

```text
models/kem/
├─ README.md              # 本文件
├─ harness/
│  ├─ kat_check.c         # 读 KAT，验 keygen + decaps
│  ├─ run.sh              # 一键编译 + 跑 100 组
│  └─ README.md
└─ third_party/           # 已改到仓库根 third_party/hqc
```

官方参考实现已 vendor 到 **`third_party/hqc/`**（public domain，commit
`06567ccbad10580d78dd7863b15d23f41076d57f`）。命名映射：

| 官方 | 本仓库 |
|:---|:---|
| HQC-1 | HQC-128 |
| HQC-3 | HQC-192 |
| HQC-5 | HQC-256 |

---

## 快速验证

WSL：

```bash
bash models/kem/harness/run.sh
# PASS: 100/100 vectors (pk/sk/ss)
```

## 已验证 / 未验证

- ✅ keygen：从 KAT 的 32 B `sk` 重新生成 `pk/sk`，100/100；
- ✅ decaps：用 KAT 的 `sk/ct` 生成 `ss`，100/100；
- ⬜ encaps：`ct` 字节级一致，需要 NIST AES-CTR DRBG（OpenSSL）；
- ⬜ HQC-192/256 KAT（暂未 vendor）；
- ⬜ 把 KAT 转成 RTL 测试向量。

## 规则

- 官方参考实现的抽样/编码/字节序**不要重写**；
- 任何本地修改用 patch 记录，不静默改算法；
- 原始日志放 `data/logs/`，不要只贴一句“通过了”。
