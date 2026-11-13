# 2026-11-13 骆奕宾补丁代导入记录

## 来源与范围

- 用户要求将队友提供的两份 git-format-patch 应用到 `feat/sha3-luoyibin`。
- 导入前远端分支：`84b0531767fcf0a6f11dcf3432e81dbc14d2465c`。
- 第一份原提交：`20cbc8eeb30955ce98b9e38851dd1b71a28c1c8e`，7 个契约/记录文件。
- 第二份原提交：`96d97af91ad920dd92e21a0c48c7fd803f2a2fa0`，11 个 smoke/自检/证据文件。
- 原补丁署名为骆弈宾，邮箱 luoyibin@users.noreply.github.com；导入提交以 Co-authored-by 保留署名。
- 用户授权的是代导入现成贡献；本次不重新开展逐步编程或替原作者确认理解/冻结契约。

## 应用与差异处理

- 两份补丁在原基线 `6c268ad` 的相关文件上均通过 `git apply --check --whitespace=error-all`，顺序应用成功。
- 最新远端已有姓名与 ASIC 口径调整；三个已有契约文件保留最新姓名“骆奕宾”。
- KEM 契约保留“前端综合、后端 P&R/STA 可选、不流片”的新口径，避免补丁回退现有约定。
- 原作者协作记录与历史失败记录照原内容导入；下述是本次代导入时新增的验证结果。
- RTL 和两个 testbench 与原补丁一致；未猜测引脚，未把曹子墨工作区内容并入本分支。

## 本次验证

- 工具：Vivado xvlog/xelab 2026.1；在独立工作副本中操作。
- xvlog 编译输入：src/example/counter.v、src/board 下四个模块，以及 sim 下两个新 tb。
- xvlog 退出码 0，语法编译通过。
- 分别执行 `xelab work.tb_board_smoke` 和 `xelab work.tb_smoke_axi_lite_regs`，均在生成 C 文件编译时失败。
- 错误：`XSIM 43-3409: Failed to compile generated C file .../obj/xsim_1.c`，随后 `XSIM 43-3915`。
- 缩短工作路径后重试仍失败；本次未确定根因，未进入 xsim 运行，不能称为仿真通过。
- 日志：[导入检查目录](../../data/logs/2026-11-13-luoyibin-import/README.md)。
- 完整工程还可使用既有 `sim/run.ps1 rtl tb_board_smoke` 与 `sim/run.ps1 rtl tb_smoke_axi_lite_regs` 复现测试入口。

## 未完成

- 两个自检的 xsim 运行及 PASS 证据；板端下载、UART/AXI 实板验证、综合/实现均未完成。
- 所有新增/修订契约仍为草案，待指定评审人审核；导入提交不构成契约冻结。
- smoke_top 使用已有 counter；与曹子墨新 smoke 计数器/复位骨架的联调仍是后续工作。
