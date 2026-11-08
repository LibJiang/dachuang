# Vendored HQC reference implementation

| 项 | 内容 |
|:---|:---|
| 来源 | <https://gitlab.com/pqc-hqc/hqc/> |
| Commit | `06567ccbad10580d78dd7863b15d23f41076d57f` |
| 获取日期 | 2026-11-06 |
| 许可证 | Public domain（见 `LICENSE`） |
| 用途 | A1 官方参考实现、KAT、C 黄金基线 |

## 保留了哪些

- `src/common/`、`src/ref/`：参考 C 实现；
- `lib/fips202/`、`lib/nist-rng/`：SHA-3/SHAKE 与 NIST RNG；
- `tests/`、`tools/`：官方测试与工具；
- `kats/ref/hqc-1/`、`kats/rs/hqc-1/`：**HQC-1（HQC-128）** KAT 与 RS 测试向量；
- `LICENSE`、`README.md`、`CHANGELOG`、`CMakeLists.txt`。

## 没有保留

- `src/x86_64/`（AVX2 优化实现）；
- `kats/ref/hqc-3`、`kats/ref/hqc-5`（HQC-192/256 KAT）；
- `packaging/`。

需要 HQC-192/256 时再按同一 commit 追加。

## 命名映射

官方新命名 **HQC-1 / HQC-3 / HQC-5** 对应旧命名 **HQC-128 / HQC-192 / HQC-256**。
本仓库默认做 **HQC-1 = HQC-128**。

## 构建说明

官方完整 KAT 测试依赖 OpenSSL（`libssl-dev`）。本仓库的
`models/kem/harness/kat_check.c` 不需要 OpenSSL，直接验证 `pk/sk/ss`：

```bash
bash models/kem/harness/run.sh
# PASS: 100/100 vectors (pk/sk/ss)
```

## 许可证注意

官方代码是 public domain；`lib/nist-rng/rng.c` 是 NIST 公共软件声明。
本目录保留原 `LICENSE`，不要把第三方代码说成本项目原创。
