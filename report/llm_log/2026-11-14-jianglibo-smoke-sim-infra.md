# 2026-11-14 jianglibo AC701 smoke 仿真与构建基础设施

## 基本信息

- 日期：2026-11-14
- 成员：江力博
- 分支：feat/sys-jianglibo
- 工作阶段：P0 板级 bring-up 准备

## 本次目标

完成今日分工中江力博的部分：Vivado 工程/约束骨架、board smoke 仿真基础设施；不写 HQC 核心 RTL，不写 smoke DUT，不改契约。

## 做了什么

- 新增 `board/smoke/tb/tb_smoke_top.v`：200 MHz 差分时钟、复位、UART 115200 8N1 接收、`SMOKE_PASS` 检测、LED 变化检测、10 ms 超时。
- 新增 `board/smoke/tb/README.md`：smoke tb 端口/波特率/通过标准。
- 新增 `board/smoke/scripts/run_sim.tcl`：打开 Vivado 工程并跑 xsim。
- 新增 `board/smoke/scripts/build_bitstream.tcl`：synth/impl/write_bitstream + utilization/timing 报告。
- 更新 `board/smoke/scripts/create_project.tcl`：自动加入 `tb_smoke_top.v` 到 `sim_1`。
- 更新 `board/smoke/README.md`：目录、仿真/构建顺序、UART 约定、通过标准。
- 更新 `board/README.md`：勾选 smoke 仿真 tb/脚本。

## 验证

- `git diff --check`：通过（仅 CRLF 提示）。
- `node tools/build-offline-docs.mjs`：32 篇文档，386.6 KB。
- 相对链接检查：`missing 0`。
- `tclsh` 语法检查：
  - `run_sim.tcl` / `build_bitstream.tcl` 正确报 `Project not found`，提示先跑 `create_project.tcl`；
  - 未执行 Vivado：RTL 线 smoke RTL 和板卡实物未就绪。

## 未完成 / 阻塞

- [ ] RTL 线提供 `smoke_top`/UART/AXI/counter/LED RTL。
- [ ] 借到 AC701 实物，确认下载线/电源/串口。
- [ ] Vivado 实际综合、bit 下载、UART `SMOKE_PASS`。
- [ ] 契约评审/冻结（房煦然/骆奕宾/曹子墨）。

## 说明

smoke DUT 仍由 RTL 线写；江力博只做工程/约束/XDC/下载/仿真基础设施和评审。testbench 直接例化 `smoke_top`，DUT 缺失时 xsim 会报找不到模块，这是预期的。
