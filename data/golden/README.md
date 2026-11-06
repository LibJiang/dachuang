# 黄金输出

> 黄金 = 独立实现的期望结果。不能由被测 RTL 自己生成。

## 规则

- 与 `data/vectors/` 同名、同顺序；
- 每个文件在首行注明生成器、版本、命令、随机种子；
- 提供 `manifest.sha256`；
- 修改黄金必须写协作纪录，并说明为什么改。

## 当前

| 文件 | 生成器 | 说明 |
|:---|:---|:---|
| `qc_mult_small.expected` | `models/golden/src/qc_mult_ref.c` | 稀疏乘法小用例 |
| `hqc128_kat_*.expected` | 官方 HQC 参考实现（A1 补） | 完整 KEM KAT |

## 生成命令（示例）

```bash
make -C models/golden
./build/golden/qc_mult_ref 8 4D 1,4
```
