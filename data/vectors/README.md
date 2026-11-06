# 测试向量

## 格式

### 稀疏乘法

- 稠密多项式：十六进制，`bit i = X^i`；最右 nibble 对应 bit 0–3；
- 稀疏多项式：位置列表，逗号分隔，升序无重复；
- 例：`data/vectors/qc_mult_small.hex`
  ```text
  8 4D 1,4
  ```
  表示 n=8，dense=0x4D，pos={1,4}。

### KAT

- 直接使用官方 HQC KAT 文件，不要手改；
- 在 `README.md` 记录来源、版本、SHA256。

## 生成

- 稀疏乘法随机向量：`models/golden/src/qc_mult_ref.c` + 脚本（M1 补）；
- 完整 KEM KAT：官方 `PQCgenKAT_kem`（A1 补）。

## 规则

- 向量入库，生成脚本入库，生成物中的大文件不入库；
- 每个向量文件必须有对应的 `.expected`；
- 修改向量必须同步更新黄金输出和协作纪录。
