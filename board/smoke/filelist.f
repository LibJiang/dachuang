# AC701 smoke RTL filelist
# 这些文件由 RTL 线提供，江力博不创建、不代写。
# create_project.tcl 会在文件缺失时直接报错，避免用空壳 top 假装 smoke 通过。

board/smoke/rtl/smoke_top.v
board/smoke/rtl/smoke_counter.v
board/smoke/rtl/uart_tx.v
board/smoke/rtl/uart_rx.v
board/smoke/rtl/axi_lite_smoke.v

# 可选：如果 RTL 线拆分了时钟/复位同步器，补在这里
# board/smoke/rtl/reset_sync.v
