# AC701 bit 下载模板（Vivado 2026.1）
# 用法：
#   vivado -mode batch -source board/smoke/scripts/program.tcl -tclargs <bit_path>
#
# 注意：
# - 不写死 cable / hw_target；由 hw_server 自动枚举
# - 先确认板卡上电、JTAG 连接、Vivado 能识别设备
# - 只用于 smoke bit，不是 HQC 功能 bit

if {[llength $argv] < 1} {
    error "Usage: vivado -mode batch -source board/smoke/scripts/program.tcl -tclargs <bit_path>"
}

set bit_file [lindex $argv 0]
if {![file exists $bit_file]} {
    error "Bit file not found: $bit_file"
}

open_hw_manager
connect_hw_server
open_hw_target

set devices [get_hw_devices]
if {[llength $devices] == 0} {
    error "No hw_device found. Check power/JTAG/cable and hw_server."
}

set dev [lindex $devices 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev

set_property PROGRAM.FILE $bit_file $dev
program_hw_devices $dev
refresh_hw_device $dev

puts "OK: programmed $dev with $bit_file"
puts "OK: check UART for SMOKE_PASS / LED / counter."

close_hw_target
disconnect_hw_server
close_hw_manager
