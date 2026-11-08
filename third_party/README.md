# 第三方代码与许可证

> 本项目代码沿用仓库根目录的 MIT LICENSE；第三方代码放这里，保留原 LICENSE。

---

## 当前清单

| 名称 | 位置 | 来源 | Commit / 版本 | 许可证 | 用途 |
|:---|:---|:---|:---|:---|:---|
| HQC 官方参考实现 | `hqc/` | <https://gitlab.com/pqc-hqc/hqc/> | `06567cc` | Public domain | A1 KAT / C 黄金 |

详见 [`hqc/VENDORED.md`](hqc/VENDORED.md)。

---

## 规则

1. **许可证明确才入库**：保留原 `LICENSE`，在 `VENDORED.md` 写来源、commit、SHA256。
2. **许可证不明确**：不要直接 vendor，只记录来源/版本/获取方式，问导师后再放。
3. 不得改变第三方代码的许可证，也不得把第三方代码说成本项目原创。
4. 官方 HQC 代码是 public domain，可以 vendor；但 `lib/nist-rng/rng.c` 的 NIST 声明要保留。
