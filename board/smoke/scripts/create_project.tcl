# AC701 smoke 工程创建（Vivado 2026.1）
# 用法：
#   vivado -mode batch -source board/smoke/scripts/create_project.tcl
# 可选覆盖 part：
#   vivado -mode batch -source board/smoke/scripts/create_project.tcl -tclargs xc7a200tfbg676-2
#
# 注意：
# - 不写死引脚；引脚只来自 board/smoke/constraints/ac701_smoke.xdc
# - RTL 文件由 RTL 线提供；缺失时直接报错，不创建空壳 top
# - 江力博不写 smoke Verilog

set script_dir [file dirname [info script]]
set repo_root  [file normalize [file join $script_dir .. .. ..]]
set smoke_dir  [file join $repo_root board smoke]
set filelist   [file join $smoke_dir filelist.f]
set proj_dir   [file join $repo_root build vivado smoke]
set xdc_file   [file join $smoke_dir constraints ac701_smoke.xdc]

set part "xc7a200tfbg676-2"
if {[llength $argv] > 0} {
    set part [lindex $argv 0]
}

puts "INFO: repo_root = $repo_root"
puts "INFO: part      = $part"

if {![file exists $filelist]} {
    error "Missing filelist: $filelist"
}

# 解析 filelist，跳过空行和 # 注释
set fh [open $filelist r]
set rtl_files {}
while {[gets $fh line] >= 0} {
    set line [string trim $line]
    if {$line eq "" || [string match "#*" $line]} {
        continue
    }
    set p [file normalize [file join $repo_root $line]]
    if {![file exists $p]} {
        close $fh
        error "Missing RTL file: $p\nRTL line must provide smoke_top/UART/AXI/counter/LED files. Do not create them in this script."
    }
    lappend rtl_files $p
}
close $fh

if {[llength $rtl_files] == 0} {
    error "filelist.f has no RTL files. RTL line must provide smoke_top/UART/AXI/counter/LED first."
}

file mkdir $proj_dir
create_project -force smoke $proj_dir -part $part
set_property target_language Verilog [current_project]

add_files -fileset sources_1 -norecurse $rtl_files

if {[file exists $xdc_file]} {
    add_files -fileset constrs_1 -norecurse $xdc_file
    puts "INFO: constraints added: $xdc_file"
} else {
    puts "WARNING: official AC701 XDC not found: $xdc_file"
    puts "WARNING: project will be created without pin/timing constraints."
    puts "WARNING: do NOT guess pins. Download AC701 master XDC and place it at the path above."
}

set_property top ac701_smoke_top [current_fileset]
update_compile_order -fileset sources_1

puts "OK: project created at $proj_dir"
puts "OK: next: synth_design / impl / write_bitstream, then program.tcl"
