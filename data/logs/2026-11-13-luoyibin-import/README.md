# 骆奕宾补丁代导入时的验证日志

这是代导入时新增的证据，原作者的历史记录保持原样。

- xvlog.log：原工作路径下 HDL 编译，退出码 0。
- tb_board_smoke-xelab.log：原路径下展开，生成 C 文件编译失败。
- xvlog-shortpath.log：缩短工作路径后 HDL 编译，退出码 0。
- tb_board_smoke-shortpath-xelab.log：同样的 XSIM 43-3409 / 43-3915 错误。
- tb_smoke_axi_lite_regs-shortpath-xelab.log：同样的 XSIM 43-3409 / 43-3915 错误。

本次未进入 xsim 运行，无 PASS；未修改 RTL/testbench 来绕过问题。
HDL 输入为 src/example/counter.v、src/board/uart_rx.v、uart_tx.v、smoke_top.v、smoke_axi_lite_regs.v、
sim/tb_board_smoke.v 与 sim/tb_smoke_axi_lite_regs.v。
使用 xvlog -work work 编译以上文件，然后对两个 work.tb_* 分别调用 xelab -s <snapshot>。

补丁适用性、分支基线及处理说明见 [代导入记录](../../../report/llm_log/2026-11-13-luoyibin-patch-import.md)。
