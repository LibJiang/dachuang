# run_xsim.tcl -- 通用 Vivado xsim 批处理脚本
#
# 用法:
#   vivado -mode batch -source sim/scripts/run_xsim.tcl -tclargs tb_counter
#
# 约定:
#   - testbench 顶层为 tb_*，必须自检并打印 PASS/FAIL
#   - 源文件: src/ 下最多 3 层 + sim/*.v
#   - 工程目录: build/xsim/<top>/（不入库）

set top "tb_counter"
if {[llength $argv] >= 1 && [lindex $argv 0] ne ""} {
    set top [lindex $argv 0]
}

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir .. ..]]
set build_dir  [file join $root build xsim $top]
file mkdir $build_dir

puts "XSIM_TOP=$top"
puts "XSIM_ROOT=$root"

create_project -force sim_$top $build_dir -part xc7z020clg400-1

set src_files [list]
foreach pattern [list \
    [file join $root src *.v] \
    [file join $root src * *.v] \
    [file join $root src * * *.v] \
    [file join $root sim *.v]] {
    set src_files [concat $src_files [glob -nocomplain $pattern]]
}

if {[llength $src_files] == 0} {
    puts "ERROR: no .v sources found under src/ or sim/"
    exit 1
}

puts "XSIM_SOURCES:"
foreach f $src_files {
    puts "  $f"
}

add_files -fileset sim_1 -norecurse $src_files
set_property top $top [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation -mode behavioral
run all

puts "XSIM_DONE: $top"
exit 0
