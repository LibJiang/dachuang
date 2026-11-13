# AC701 smoke 最小约束
# 来源：AMD/Xilinx 官方 XilinxBoardStore 的 AC701 board files
#   boards/Xilinx/ac701/1.4/part0_pins.xml（part_name=xc7a200tfbg676-2）
# 说明：
#   - 这是从官方 board file 提取的“smoke 最小 XDC”，不是完整 AC701 master XDC。
#   - 只约束 smoke 用到的时钟、复位、LED、UART；未用外设不写。
#   - 端口名与 board/smoke/README.md 的 smoke_top 约定一致。
#   - 不猜引脚；如需完整外设，使用 AMD 官方 AC701 master XDC 并合并。

# ------------------------------------------------------------------
# 200 MHz system clock (differential)
# ------------------------------------------------------------------
set_property PACKAGE_PIN R3 [get_ports sys_clk_p]
set_property PACKAGE_PIN P3 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p sys_clk_n}]
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]

# ------------------------------------------------------------------
# Reset: board RESET is active high (part0_pins.xml name=RESET)
# ------------------------------------------------------------------
set_property PACKAGE_PIN U4 [get_ports rst]
set_property IOSTANDARD LVCMOS15 [get_ports rst]
set_property PULLDOWN true [get_ports rst]

# ------------------------------------------------------------------
# User LEDs: leds_4bits_tri_o_0..3
# ------------------------------------------------------------------
set_property PACKAGE_PIN M26 [get_ports {led[0]}]
set_property PACKAGE_PIN T24 [get_ports {led[1]}]
set_property PACKAGE_PIN T25 [get_ports {led[2]}]
set_property PACKAGE_PIN R26 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# ------------------------------------------------------------------
# USB-UART bridge
#   已核对完整 AC701_Rev1_0_ucf.xdc（RDF0212）：
#     USB_UART_TX = T19（FPGA 输出）
#     USB_UART_RX = U19（FPGA 输入）
# ------------------------------------------------------------------
set_property PACKAGE_PIN T19 [get_ports uart_txd]
set_property PACKAGE_PIN U19 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS18 [get_ports {uart_txd uart_rxd}]
