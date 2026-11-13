# 2026-11-13 jianglibo AC701 smoke 工程骨架

## 基本信息

- 日期：2026-11-13
- 成员：江力博
- 分支：feat/sys-jianglibo（已提交并推送）
- 工作阶段：P0 板级 bring-up 准备

## 本次目标

按 `docs/18` 的今晚分工，只做 AC701 smoke 的工程/约束/下载基础设施和系统 tb 目录规划；不写 HQC 核心 RTL，不写 smoke Verilog，不改契约，不动桌面文献综述。

## 做了什么

- 新增 `board/smoke/README.md`：smoke 范围、分工、目录、验收、证据。
- 新增 `board/smoke/constraints/README.md`：AC701 官方 board file 来源说明，禁止猜引脚。
- 新增 `board/smoke/constraints/ac701_smoke.xdc`：从官方 XilinxBoardStore `part0_pins.xml` 提取 smoke 最小 XDC（200 MHz 时钟、RESET、LED、UART）。
- 核对用户下载的 `ac701-schematic-xtp218_cluster.zip`：内含 `AC701_Rev1_0_ucf.xdc`，确认 USB_UART_TX=T19 / USB_UART_RX=U19，并修正 smoke XDC 的 UART 方向。
- 新增 `board/smoke/scripts/create_project.tcl`：Vivado 工程创建，读取 filelist/XDC，缺失 RTL 时明确报错。
- 新增 `board/smoke/scripts/program.tcl`：JTAG 下载模板，不写死 cable/hw_target。
- 新增 `board/smoke/filelist.f`：列出 RTL 线后续提供的 smoke RTL。
- 更新 `board/README.md`：加入 smoke 入口和职责说明。
- 更新 `sim/system/README.md`：补充今晚系统 tb 规划边界，不写 tb 实现。

## 验证

- `git diff --check`：通过。
- `node tools/build-offline-docs.mjs`：通过（32 篇文档）。
- 相对链接检查：`missing 0`。
- 未运行 Vivado：板卡实物和 RTL 线 smoke RTL 未就绪（XDC 已就绪）。

## 未完成 / 阻塞

- [ ] RTL 线提供 `smoke_top`/UART/AXI/counter/LED RTL。
- [x] 从官方 XilinxBoardStore 的 AC701 board file 提取 smoke 最小 XDC。
- [x] 完整 master XDC 已下载并核对（受 EULA/版权约束，未 vendor 进仓库）。
- [ ] 借到 AC701 实物，确认下载线/电源/串口。
- [ ] 跑通 Vivado 综合/实现/bit 下载/UART smoke。
- [x] 已提交并推送 `feat/sys-jianglibo`。

## 说明

smoke RTL 由骆奕宾、曹子墨写；江力博只做 Vivado 工程/约束/XDC/下载/评审。`create_project.tcl` 在 RTL 文件缺失时会报错，这是有意的，避免用空壳 top 假装 smoke 通过。
