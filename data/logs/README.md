# 原始日志

## 命名

```text
data/logs/YYYY-MM-DD-<主题>/
├─ README.md          # 做了什么、命令、结论、未完成项
├─ xsim.log
├─ golden.log
├─ kat.log
└─ manifest.sha256
```

## 规则

- 原始输出**不要手改**；需要总结写到 `README.md`；
- 日志里必须有：命令、工具版本、随机种子、用例数、PASS/FAIL；
- 大文件不入库；`.wdb/.vcd` 只留路径；
- 结论必须写清：仿真 / 综合 / 上板。
