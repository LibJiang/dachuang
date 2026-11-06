# 证据（综合 / 时序 / 上板）

## 内容

- Vivado `utilization.rpt`、`timing_summary.rpt`；
- 综合/实现日志；
- 上板截图 + 串口/PYNQ 输出；
- `manifest.sha256`。

## 规则

- 每个证据目录必须有 `README.md`：版本、commit、工具版本、复现命令、WNS/WHS、LUT/FF/BRAM/DSP；
- 截图不能单独作为证据，必须配原始日志；
- `.bit/.dcp` 不入库，只记录路径与哈希；
- 仿真、综合、上板三种口径分开写，不得混用。
