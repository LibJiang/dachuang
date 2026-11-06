# PYNQ-Z2 v1.0 板级引脚约束（子集）
#
# 来源：官方 PYNQ-Z2 Master XDC v1.0
#   SHA256: 07441e999bac956c77e78091c782cade278efc5a78affc51e5b12b4800b1fe73
#   成员文件: PYNQ-Z2 v1.0.xdc
# 本文件只保留 HQC 加速器 V0 需要的 clk / LED / BTN0；
# 其它引脚（HDMI、PMOD、UART 等）按需从 master XDC 追加，禁止猜。
#
# 说明：
#   - PL 时钟 clk = H16，125 MHz，LVCMOS33；
#   - BTN0 = D19，高电平按下；顶层若用 rst_n，请在顶层取反并做同步释放；
#   - LED[3:0] = R14 / P14 / N16 / M14，高电平点亮；
#   - 使用本文件时，顶层必须存在 clk / led[3:0] / btn0 端口，否则 XDC 会报错。

set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {clk}]

set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btn0}]

# 设计相关例外（不是 master XDC 的内容）：
# btn0 只驱动异步复位/同步释放链；LED 是人眼指示，没有外部采样时钟。
# 内部寄存器到寄存器的 setup/hold 仍按实际时钟约束。
set_false_path -from [get_ports {btn0}]
set_false_path -to [get_ports {led[*]}]
