# Synopsys Design Compiler flow for the asynchronous FIFO.
# Set PDK_DIR to the directory containing gscl45nm.db before running dc_shell.

set rtl_files [list \
    ../rtl/fifo_memory.sv \
    ../rtl/fifo_read.sv \
    ../rtl/fifo_sync_r2w.sv \
    ../rtl/fifo_sync_w2r.sv \
    ../rtl/fifo_write.sv \
    ../rtl/fifo_top.sv]

set top_module fifo_top
set write_period_ns 0.625
set read_period_ns 1.25
set io_delay_ns 0.10

set pdk_dir [getenv PDK_DIR]
if {$pdk_dir eq ""} {
    error "PDK_DIR must point to the directory containing gscl45nm.db"
}

set search_path [concat $search_path [list $pdk_dir]]
set target_library [list gscl45nm.db]
set link_library [concat "*" $target_library [list dw_foundation.sldb]]

define_design_lib WORK -path ./WORK
analyze -format sverilog $rtl_files
elaborate $top_module
current_design $top_module
link
uniquify

create_clock -name wclk -period $write_period_ns [get_ports wclk]
create_clock -name rclk -period $read_period_ns [get_ports rclk]
set_clock_groups -asynchronous -group [get_clocks wclk] -group [get_clocks rclk]

set_input_delay $io_delay_ns -clock wclk [get_ports {wdata[*] winc}]
set_input_delay $io_delay_ns -clock rclk [get_ports {rinc}]
set_output_delay $io_delay_ns -clock wclk [get_ports {wfull walmost_full}]
set_output_delay $io_delay_ns -clock rclk [get_ports {rdata[*] rempty ralmost_empty}]
set_false_path -from [get_ports {wrst_n rrst_n}]

compile_ultra
check_design
report_constraint -all_violators

file mkdir reports
redirect reports/timing.rpt {report_timing -max_paths 10}
redirect reports/area.rpt {report_area -hierarchy}
redirect reports/power.rpt {report_power}

write -format ddc -hierarchy -output reports/fifo_top.ddc
write_sdc reports/fifo_top.sdc
quit
