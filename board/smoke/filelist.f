# AC701 smoke RTL filelist
# 这些文件由 RTL 线提供，江力博不创建、不代写。
# create_project.tcl 会在文件缺失时直接报错，避免用空壳 top 假装 smoke 通过。

src/soc/ac701_smoke_top.v
src/board/smoke_top.v
src/example/counter.v
src/board/uart_tx.v
src/board/uart_rx.v
src/board/smoke_axi_lite_regs.v

# 可选：如果 RTL 线拆分了时钟/复位同步器，补在这里
# board/smoke/rtl/reset_sync.v
