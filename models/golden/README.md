# qc_mult_ref —— 稀疏准循环乘法黄金模型

> 语义：\(c = \bigoplus_{p \in \mathrm{supp}(b)} (a \lll p) \bmod (X^n-1)\)。
> 稠密 \(a\)：n bit，`bit i = X^i`；稀疏 \(b\)：位置列表（升序、无重复）。

## 构建

```bash
make -C models/golden
```

产物：`build/golden/qc_mult_ref`（Windows 下为 `qc_mult_ref.exe`）。

## 用法

```bash
# 自检
./build/golden/qc_mult_ref --selftest

# 单次计算：N  DENSE_HEX  POS_LIST
./build/golden/qc_mult_ref 8 4D 1,4
# 输出：0x4E
```

- `DENSE_HEX` 可带 `0x` 前缀；最右 nibble 对应 bit 0–3；
- `POS_LIST` 逗号分隔，位置从 0 开始；
- 输出为固定宽度的十六进制（`(N+3)/4` 个 nibble），带 `0x`；
- 非法输入返回非 0。

## 自检覆盖

| 用例 | 说明 |
|:---|:---|
| n=8, a=0x4D, pos=1,4 | 基本循环折叠 |
| n=8, a=0x01, pos=0,1,7 | 跨 X^7 → X^0 折叠 |
| n=16, a=0x0001, pos=0 | 单位元 |
| n=16, a=0x0001, pos=15 | 最高位 |
| n=64, a=0x1, pos=0,1,63 | 64 bit 边界 |

## 说明

- 这是**功能黄金模型**，用一 byte 存一个系数，优先正确性，不追求性能；
- 真实 HQC 的 n=17669 也能跑，只是内存/时间更大；
- 与官方 HQC 参考实现的关系：本模型只验证乘法；完整 KEM 的黄金在 `models/kem/` 用官方实现。
