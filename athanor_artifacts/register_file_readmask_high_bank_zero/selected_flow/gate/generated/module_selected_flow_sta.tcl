read_liberty /workdir/.main-6b922e97/src/kairos/data/liberty/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/generated/cv32e40p_id_stage_sta.v
link_design cv32e40p_id_stage
create_clock -name clk -period 5.0 [get_ports clk]

set flops [all_registers -edge_triggered]
set input_ports [all_inputs]
set output_ports [all_outputs]
set_input_delay -clock clk 0.5 $input_ports
set_output_delay -clock clk 0.5 $output_ports

group_path -name reg2reg -from $flops -to $flops
group_path -name reg2out -from $flops -to $output_ports
group_path -name in2reg -from $input_ports -to $flops
group_path -name in2out -from $input_ports -to $output_ports

proc write_paths {paths out_path} {
  set out [open $out_path w]
  puts $out "Start Point,End Point,WNS (ns)"
  foreach p $paths {
    set start [get_property [get_property $p startpoint] full_name]
    set end [get_property [get_property $p endpoint] full_name]
    set slack [get_property $p slack]
    puts $out [format "%s,%s,%.4f" $start $end $slack]
  }
  close $out
}

proc timing_csv {group path count} {
  report_checks -group_count $count -path_group $group > ${path}.rpt
  set paths [find_timing_paths -group_count $count -path_group $group]
  write_paths $paths ${path}.csv.rpt
}

report_checks -group_count 50 > /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/overall.rpt
set overall_paths [find_timing_paths -group_count 50]
write_paths $overall_paths /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/overall.csv.rpt
timing_csv reg2reg /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/reg2reg 50
timing_csv reg2out /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/reg2out 50
timing_csv in2reg /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/in2reg 50
timing_csv in2out /tmp/dexter_cv32_regfile_readmask_idstage_gate_selected/reports/timing/in2out 50
exit
