# AC701 smoke bitstream build (Vivado 2026.1)
# 用法：
#   vivado -mode batch -source board/smoke/scripts/build_bitstream.tcl
#
# 前置：
#   - 已运行 create_project.tcl
#   - RTL 线已提供 smoke RTL
#   - constraints/ac701_smoke.xdc 存在
#
# 只做 smoke 的 synth/impl/bit；不是 HQC 功能 bit。

set script_dir [file dirname [info script]]
set repo_root  [file normalize [file join $script_dir .. .. ..]]
set proj_file  [file join $repo_root build vivado smoke smoke.xpr]

if {![file exists $proj_file]} {
    error "Project not found: $proj_file\nRun create_project.tcl first."
}

open_project $proj_file

puts "INFO: synth_1"
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "synth_1 failed: [get_property STATUS [get_runs synth_1]]"
}

puts "INFO: impl_1 + write_bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "impl_1 failed: [get_property STATUS [get_runs impl_1]]"
}

open_run impl_1
set report_dir [file join $repo_root build vivado smoke reports]
file mkdir $report_dir
report_utilization -file [file join $report_dir utilization.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]

set bit_file [file join [get_property DIRECTORY [get_runs impl_1]] smoke_top.bit]
if {![file exists $bit_file]} {
    error "Bitstream not found: $bit_file"
}

puts "OK: bitstream = $bit_file"
puts "OK: reports = $report_dir"
close_project
