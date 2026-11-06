# src/mult —— 稀疏准循环乘法

## 当前实现

`sparse_qc_mult.v`：单路、64-bit 字、行为级 baseline。

- 支持 `N` 为 64 的倍数；`WORDS = N/64`；
- 输入：`dense` 多项式写入 `dense_mem`，稀疏位置表写入 `pos_mem`；
- 计算：按位置 \(p\) 对 dense 做循环移位，XOR 累加到 `prod_mem`；
- 输出：`prod_rdata` 同步/组合读（V0 为组合读）；
- 延迟：`WORDS`（清零）+ `W × WORDS`（计算）+ 2 周期。

## 已知限制

- **HQC-128 的 N=17669 不是 64 的倍数**：当前 RTL 只验证 `N=64`；
  17669 需要尾部填充/折叠逻辑，M2 处理。
- `LANES` 参数已保留但未使用；M2 做 1/2/4/8 路。
- 未做恒定时间/地址混淆；V0 只做功能。

## 验证

```bash
sim/run.ps1 rtl tb_sparse_qc_mult
# PASS: 4/4 checks
```

C 黄金：

```bash
make -C models/golden
./build/golden/qc_mult_ref --selftest
# PASS: 5/5 checks
```

## 下一步

1. 加 HQC-128（N=17669）的尾部填充/折叠；
2. 加 1000 组随机对拍（C 黄金生成）；
3. 扩 `LANES` 与 BRAM banking；
4. OOC 综合，记录 LUT/FF/BRAM/Fmax/周期数。
