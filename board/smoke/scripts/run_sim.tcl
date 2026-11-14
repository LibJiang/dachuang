# AC701 smoke xsim
# 用法：
#   vivado -mode batch -source board/smoke/scripts/run_sim.tcl
#
# 前置：
#   - 已运行 create_project.tcl（需要 RTL 线提供 filelist.f 中的 smoke RTL）
#   - tb: board/smoke/tb/tb_smoke_top.v

set script_dir [file dirname [info script]]
set repo_root  [file normalize [file join $script_dir .. .. ..]]
set proj_file  [file join $repo_root build vivado smoke smoke.xpr]
set tb_file    [file join $repo_root board smoke tb tb_smoke_top.v]

if {![file exists $proj_file]} {
    error "Project not found: $proj_file\nRun create_project.tcl first."
}
if {![file exists $tb_file]} {
    error "Testbench not found: $tb_file"
}

open_project $proj_file

# 把 tb 加入 sim_1（重复执行时先查重）
set existing [get_files -quiet $tb_file]
if {[llength $existing] == 0} {
    add_files -fileset sim_1 -norecurse $tb_file
}
set_property top tb_smoke_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

puts "INFO: launching xsim for tb_smoke_top"
launch_simulation -mode behavioral
run all
close_sim

puts "OK: simulation finished; check output for PASS/FAIL above."
close_project
