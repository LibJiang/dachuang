# C/C++ 软件仿真与黄金模型

> 本目录放**不依赖 Vivado** 的软件模型。用途：
> ① 作为 RTL 的逐 bit 黄金参考；② 作为“为什么需要硬件加速”的软件基线；
> ③ 作为 KAT / 回归的独立实现。

---

## 目录

| 目录 | 内容 | 阶段 |
|:---|:---|:---|
| `golden/` | 独立算术黄金模型（当前：稀疏 QC 乘法） | A/B |
| `kem/` | 官方 HQC 参考实现 harness、KAT 对拍 | A |
| `third_party/`（待建） | 官方参考实现 / 第三方 IP，保留许可证 | A |

---

## 规则

1. **C11**，GCC/Clang，`-O2 -Wall -Wextra -Werror`；
2. 每个程序支持 `--selftest`，输出 `PASS: N/N` / `FAIL: ...`；
3. 随机测试固定种子，并打印种子；
4. 与官方参考实现对拍时，**逐字节**比较，不能只比共享密钥；
5. 生成物放 `build/`，不入库；
6. 任何“黄金”结论必须在 `data/golden/` 留期望输出，并在协作纪录里链接命令。

---

## 快速开始

```bash
make -C models/golden
./build/golden/qc_mult_ref --selftest
./build/golden/qc_mult_ref 8 4D 1,4
```

---

## 与 RTL 的关系

- RTL 的 testbench 读取 `data/vectors/*.hex`，与 `data/golden/*.expected` 比较；
- C 黄金负责生成向量与期望输出；
- 不允许 RTL 与 C 共用同一份“可能有 bug”的生成逻辑而不做独立校验。
