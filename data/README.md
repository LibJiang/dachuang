# 测试数据、黄金输出与证据

> 原则：**仓库内可复现**。任何“验证通过”的结论，都必须能在这里找到向量、期望输出和原始日志。

---

## 目录

| 目录 | 放什么 | 不放什么 |
|:---|:---|:---|
| `vectors/` | 输入向量（dense hex、位置列表、KAT 输入） | 生成脚本（放 `tools/` 或 `models/`） |
| `golden/` | 期望输出（`.expected`）、SHA256、manifest | 运行日志 |
| `logs/` | 仿真/编译/上板原始日志 | 手工总结（放 `docs/records/`） |
| `evidence/` | 综合/时序/上板报告、截图说明、manifest | 大体积 bit/dcp（不入库） |

---

## 命名

```text
data/logs/YYYY-MM-DD-<主题>/
├─ README.md          # 本次做了什么、命令、结论
├─ xsim.log           # 原始日志
├─ golden.log
└─ manifest.sha256

data/evidence/YYYY-MM-DD-<主题>/
├─ README.md
├─ utilization.rpt
├─ timing_summary.rpt
└─ manifest.sha256
```

- 文件名用英文/拼音 + 数字，避免跨平台乱码；
- 日志里的随机种子必须可见；
- 大文件（`.bit/.dcp/.wdb`）不入库，只放路径/哈希/截图。

---

## 规则

1. 向量与黄金必须**成对**，并有生成命令；
2. 黄金输出必须来自独立实现（C/C++ 或官方参考），不能由被测 RTL 自己生成；
3. 每次回归记录用例数、通过数、失败数；
4. 结论必须写清口径：仿真 / 综合 / 上板，三者不可混写。
