# KAT 对拍 harness

## 作用

用官方 HQC-1（HQC-128）KAT 验证参考实现：

- 从 KAT 的 `sk`（32 B master seed）重新跑 keygen，比较 `pk/sk`；
- 用 KAT 的 `sk/ct` 跑 decaps，比较 `ss`；
- 输出 `PASS: 100/100 vectors (pk/sk/ss)`。

**不验证 encaps 的 `ct` 字节级一致**：encaps 需要 NIST AES-CTR DRBG 的随机流；
官方 `tests/kats/test_kat.c` 依赖 OpenSSL，当前环境没装 `libssl-dev`。
先验证 keygen + decaps，这两条覆盖了最复杂的数据通路。

## 构建与运行

在 WSL（Ubuntu-22.04）里，从仓库根目录：

```bash
bash models/kem/harness/run.sh
```

或手动：

```bash
gcc -O2 -std=c11 -DREF_MODE \
  -Ithird_party/hqc/src/common \
  -Ithird_party/hqc/src/common/hqc-1 \
  -Ithird_party/hqc/src/ref \
  -Ithird_party/hqc/src/ref/hqc-1 \
  -Ithird_party/hqc/lib/fips202 \
  third_party/hqc/src/common/*.c \
  third_party/hqc/src/ref/*.c \
  third_party/hqc/lib/fips202/fips202.c \
  models/kem/harness/kat_check.c \
  -o build/hqc_kat_check

./build/hqc_kat_check third_party/hqc/kats/ref/hqc-1/PQCkemKAT_32.rsp
```

## 原理

- `hqc_kem_keygen` 内部用 `randombytes` 生成 32 B `sk`；
  harness 用一个 stub 把 KAT 的 `sk` 喂给它，于是 keygen 可确定复现；
- `hqc_kem_decaps` 不需要 RNG，直接用 `sk/ct` 即可；
- 因此无需 OpenSSL/NIST DRBG 就能对拍 `pk/sk/ss`。

## 后续

- [ ] 安装 `libssl-dev` 后，跑官方 `test_kat.c`，补 encaps `ct` 字节级一致；
- [ ] 把 KAT 结果归档到 `data/logs/YYYY-MM-DD-hqc-kat/`；
- [ ] 把 `sk/ct/ss` 转成 `data/vectors/` 的 RTL 测试格式。
