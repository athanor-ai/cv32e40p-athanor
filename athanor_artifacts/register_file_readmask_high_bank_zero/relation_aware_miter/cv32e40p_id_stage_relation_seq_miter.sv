// Auto-generated adapter miter for ATH-2853 replay packaging.
// The load-bearing proof receipt for this packet remains replay_parent_equiv.sh,
// which uses Yosys equiv_make/equiv_induct on these same parent bundles.
module cv32e40p_id_stage_relation_seq_miter (
  input wire clk,
  input wire clk_ungated_i,
  input wire rst_n,
  input wire scan_cg_en_i,
  input wire fetch_enable_i,
  input wire instr_valid_i,
  input wire [31:0] instr_rdata_i,
  input wire is_compressed_i,
  input wire illegal_c_insn_i,
  input wire branch_decision_i,
  input wire is_fetch_failed_i,
  input wire [31:0] pc_id_i,
  input wire ex_ready_i,
  input wire wb_ready_i,
  input wire ex_valid_i,
  input wire apu_read_dep_i,
  input wire apu_read_dep_for_jalr_i,
  input wire apu_write_dep_i,
  input wire apu_busy_i,
  input wire fs_off_i,
  input wire [2:0] frm_i,
  input wire [1:0] current_priv_lvl_i,
  input wire data_misaligned_i,
  input wire data_err_i,
  input wire [31:0] irq_i,
  input wire irq_sec_i,
  input wire [31:0] mie_bypass_i,
  input wire m_irq_enable_i,
  input wire u_irq_enable_i,
  input wire debug_req_i,
  input wire debug_single_step_i,
  input wire debug_ebreakm_i,
  input wire debug_ebreaku_i,
  input wire trigger_match_i,
  input wire [5:0] regfile_waddr_wb_i,
  input wire regfile_we_wb_i,
  input wire regfile_we_wb_power_i,
  input wire [31:0] regfile_wdata_wb_i,
  input wire [5:0] regfile_alu_waddr_fw_i,
  input wire regfile_alu_we_fw_i,
  input wire regfile_alu_we_fw_power_i,
  input wire [31:0] regfile_alu_wdata_fw_i,
  input wire mult_multicycle_i,
  input wire perf_imiss_i,
  input wire [31:0] mcounteren_i
);

  parameter COREV_PULP = 1;
  parameter COREV_CLUSTER = 0;
  parameter N_HWLP = 2;
  parameter N_HWLP_BITS = $clog2(N_HWLP);
  parameter PULP_SECURE = 0;
  parameter USE_PMP = 0;
  parameter A_EXTENSION = 0;
  parameter APU = 0;
  parameter FPU = 0;
  parameter FPU_ADDMUL_LAT = 0;
  parameter FPU_OTHERS_LAT = 0;
  parameter ZFINX = 0;
  parameter APU_NARGS_CPU = 3;
  parameter APU_WOP_CPU = 6;
  parameter APU_NDSFLAGS_CPU = 15;
  parameter APU_NUSFLAGS_CPU = 5;
  parameter DEBUG_TRIGGER_EN = 1;

  wire gold_ctrl_busy_o;
  wire gate_ctrl_busy_o;
  wire gold_is_decoding_o;
  wire gate_is_decoding_o;
  wire gold_instr_req_o;
  wire gate_instr_req_o;
  wire gold_branch_in_ex_o;
  wire gate_branch_in_ex_o;
  wire [31:0] gold_jump_target_o;
  wire [31:0] gate_jump_target_o;
  wire [1:0] gold_ctrl_transfer_insn_in_dec_o;
  wire [1:0] gate_ctrl_transfer_insn_in_dec_o;
  wire gold_clear_instr_valid_o;
  wire gate_clear_instr_valid_o;
  wire gold_pc_set_o;
  wire gate_pc_set_o;
  wire [3:0] gold_pc_mux_o;
  wire [3:0] gate_pc_mux_o;
  wire [2:0] gold_exc_pc_mux_o;
  wire [2:0] gate_exc_pc_mux_o;
  wire [1:0] gold_trap_addr_mux_o;
  wire [1:0] gate_trap_addr_mux_o;
  wire gold_halt_if_o;
  wire gate_halt_if_o;
  wire gold_id_ready_o;
  wire gate_id_ready_o;
  wire gold_id_valid_o;
  wire gate_id_valid_o;
  wire [31:0] gold_pc_ex_o;
  wire [31:0] gate_pc_ex_o;
  wire [31:0] gold_alu_operand_a_ex_o;
  wire [31:0] gate_alu_operand_a_ex_o;
  wire [31:0] gold_alu_operand_b_ex_o;
  wire [31:0] gate_alu_operand_b_ex_o;
  wire [31:0] gold_alu_operand_c_ex_o;
  wire [31:0] gate_alu_operand_c_ex_o;
  wire [4:0] gold_bmask_a_ex_o;
  wire [4:0] gate_bmask_a_ex_o;
  wire [4:0] gold_bmask_b_ex_o;
  wire [4:0] gate_bmask_b_ex_o;
  wire [1:0] gold_imm_vec_ext_ex_o;
  wire [1:0] gate_imm_vec_ext_ex_o;
  wire [1:0] gold_alu_vec_mode_ex_o;
  wire [1:0] gate_alu_vec_mode_ex_o;
  wire [5:0] gold_regfile_waddr_ex_o;
  wire [5:0] gate_regfile_waddr_ex_o;
  wire gold_regfile_we_ex_o;
  wire gate_regfile_we_ex_o;
  wire [5:0] gold_regfile_alu_waddr_ex_o;
  wire [5:0] gate_regfile_alu_waddr_ex_o;
  wire gold_regfile_alu_we_ex_o;
  wire gate_regfile_alu_we_ex_o;
  wire gold_alu_en_ex_o;
  wire gate_alu_en_ex_o;
  wire [6:0] gold_alu_operator_ex_o;
  wire [6:0] gate_alu_operator_ex_o;
  wire gold_alu_is_clpx_ex_o;
  wire gate_alu_is_clpx_ex_o;
  wire gold_alu_is_subrot_ex_o;
  wire gate_alu_is_subrot_ex_o;
  wire [1:0] gold_alu_clpx_shift_ex_o;
  wire [1:0] gate_alu_clpx_shift_ex_o;
  wire [2:0] gold_mult_operator_ex_o;
  wire [2:0] gate_mult_operator_ex_o;
  wire [31:0] gold_mult_operand_a_ex_o;
  wire [31:0] gate_mult_operand_a_ex_o;
  wire [31:0] gold_mult_operand_b_ex_o;
  wire [31:0] gate_mult_operand_b_ex_o;
  wire [31:0] gold_mult_operand_c_ex_o;
  wire [31:0] gate_mult_operand_c_ex_o;
  wire gold_mult_en_ex_o;
  wire gate_mult_en_ex_o;
  wire gold_mult_sel_subword_ex_o;
  wire gate_mult_sel_subword_ex_o;
  wire [1:0] gold_mult_signed_mode_ex_o;
  wire [1:0] gate_mult_signed_mode_ex_o;
  wire [4:0] gold_mult_imm_ex_o;
  wire [4:0] gate_mult_imm_ex_o;
  wire [31:0] gold_mult_dot_op_a_ex_o;
  wire [31:0] gate_mult_dot_op_a_ex_o;
  wire [31:0] gold_mult_dot_op_b_ex_o;
  wire [31:0] gate_mult_dot_op_b_ex_o;
  wire [31:0] gold_mult_dot_op_c_ex_o;
  wire [31:0] gate_mult_dot_op_c_ex_o;
  wire [1:0] gold_mult_dot_signed_ex_o;
  wire [1:0] gate_mult_dot_signed_ex_o;
  wire gold_mult_is_clpx_ex_o;
  wire gate_mult_is_clpx_ex_o;
  wire [1:0] gold_mult_clpx_shift_ex_o;
  wire [1:0] gate_mult_clpx_shift_ex_o;
  wire gold_mult_clpx_img_ex_o;
  wire gate_mult_clpx_img_ex_o;
  wire gold_apu_en_ex_o;
  wire gate_apu_en_ex_o;
  wire [APU_WOP_CPU - 1:0] gold_apu_op_ex_o;
  wire [APU_WOP_CPU - 1:0] gate_apu_op_ex_o;
  wire [1:0] gold_apu_lat_ex_o;
  wire [1:0] gate_apu_lat_ex_o;
  wire [(APU_NARGS_CPU * 32) - 1:0] gold_apu_operands_ex_o;
  wire [(APU_NARGS_CPU * 32) - 1:0] gate_apu_operands_ex_o;
  wire [APU_NDSFLAGS_CPU - 1:0] gold_apu_flags_ex_o;
  wire [APU_NDSFLAGS_CPU - 1:0] gate_apu_flags_ex_o;
  wire [5:0] gold_apu_waddr_ex_o;
  wire [5:0] gate_apu_waddr_ex_o;
  wire [17:0] gold_apu_read_regs_o;
  wire [17:0] gate_apu_read_regs_o;
  wire [2:0] gold_apu_read_regs_valid_o;
  wire [2:0] gate_apu_read_regs_valid_o;
  wire [11:0] gold_apu_write_regs_o;
  wire [11:0] gate_apu_write_regs_o;
  wire [1:0] gold_apu_write_regs_valid_o;
  wire [1:0] gate_apu_write_regs_valid_o;
  wire gold_apu_perf_dep_o;
  wire gate_apu_perf_dep_o;
  wire gold_csr_access_ex_o;
  wire gate_csr_access_ex_o;
  wire [1:0] gold_csr_op_ex_o;
  wire [1:0] gate_csr_op_ex_o;
  wire gold_csr_irq_sec_o;
  wire gate_csr_irq_sec_o;
  wire [5:0] gold_csr_cause_o;
  wire [5:0] gate_csr_cause_o;
  wire gold_csr_save_if_o;
  wire gate_csr_save_if_o;
  wire gold_csr_save_id_o;
  wire gate_csr_save_id_o;
  wire gold_csr_save_ex_o;
  wire gate_csr_save_ex_o;
  wire gold_csr_restore_mret_id_o;
  wire gate_csr_restore_mret_id_o;
  wire gold_csr_restore_uret_id_o;
  wire gate_csr_restore_uret_id_o;
  wire gold_csr_restore_dret_id_o;
  wire gate_csr_restore_dret_id_o;
  wire gold_csr_save_cause_o;
  wire gate_csr_save_cause_o;
  wire [(N_HWLP * 32) - 1:0] gold_hwlp_start_o;
  wire [(N_HWLP * 32) - 1:0] gate_hwlp_start_o;
  wire [(N_HWLP * 32) - 1:0] gold_hwlp_end_o;
  wire [(N_HWLP * 32) - 1:0] gate_hwlp_end_o;
  wire [(N_HWLP * 32) - 1:0] gold_hwlp_cnt_o;
  wire [(N_HWLP * 32) - 1:0] gate_hwlp_cnt_o;
  wire gold_hwlp_jump_o;
  wire gate_hwlp_jump_o;
  wire [31:0] gold_hwlp_target_o;
  wire [31:0] gate_hwlp_target_o;
  wire gold_data_req_ex_o;
  wire gate_data_req_ex_o;
  wire gold_data_we_ex_o;
  wire gate_data_we_ex_o;
  wire [1:0] gold_data_type_ex_o;
  wire [1:0] gate_data_type_ex_o;
  wire [1:0] gold_data_sign_ext_ex_o;
  wire [1:0] gate_data_sign_ext_ex_o;
  wire [1:0] gold_data_reg_offset_ex_o;
  wire [1:0] gate_data_reg_offset_ex_o;
  wire gold_data_load_event_ex_o;
  wire gate_data_load_event_ex_o;
  wire gold_data_misaligned_ex_o;
  wire gate_data_misaligned_ex_o;
  wire gold_prepost_useincr_ex_o;
  wire gate_prepost_useincr_ex_o;
  wire gold_data_err_ack_o;
  wire gate_data_err_ack_o;
  wire [5:0] gold_atop_ex_o;
  wire [5:0] gate_atop_ex_o;
  wire [31:0] gold_mip_o;
  wire [31:0] gate_mip_o;
  wire gold_irq_ack_o;
  wire gate_irq_ack_o;
  wire [4:0] gold_irq_id_o;
  wire [4:0] gate_irq_id_o;
  wire [4:0] gold_exc_cause_o;
  wire [4:0] gate_exc_cause_o;
  wire gold_debug_mode_o;
  wire gate_debug_mode_o;
  wire [2:0] gold_debug_cause_o;
  wire [2:0] gate_debug_cause_o;
  wire gold_debug_csr_save_o;
  wire gate_debug_csr_save_o;
  wire gold_debug_p_elw_no_sleep_o;
  wire gate_debug_p_elw_no_sleep_o;
  wire gold_debug_havereset_o;
  wire gate_debug_havereset_o;
  wire gold_debug_running_o;
  wire gate_debug_running_o;
  wire gold_debug_halted_o;
  wire gate_debug_halted_o;
  wire gold_wake_from_sleep_o;
  wire gate_wake_from_sleep_o;
  wire gold_mhpmevent_minstret_o;
  wire gate_mhpmevent_minstret_o;
  wire gold_mhpmevent_load_o;
  wire gate_mhpmevent_load_o;
  wire gold_mhpmevent_store_o;
  wire gate_mhpmevent_store_o;
  wire gold_mhpmevent_jump_o;
  wire gate_mhpmevent_jump_o;
  wire gold_mhpmevent_branch_o;
  wire gate_mhpmevent_branch_o;
  wire gold_mhpmevent_branch_taken_o;
  wire gate_mhpmevent_branch_taken_o;
  wire gold_mhpmevent_compressed_o;
  wire gate_mhpmevent_compressed_o;
  wire gold_mhpmevent_jr_stall_o;
  wire gate_mhpmevent_jr_stall_o;
  wire gold_mhpmevent_imiss_o;
  wire gate_mhpmevent_imiss_o;
  wire gold_mhpmevent_ld_stall_o;
  wire gate_mhpmevent_ld_stall_o;
  wire gold_mhpmevent_pipe_stall_o;
  wire gate_mhpmevent_pipe_stall_o;

  cv32e40p_id_stage_gold gold (
    .clk(clk),
    .clk_ungated_i(clk_ungated_i),
    .rst_n(rst_n),
    .scan_cg_en_i(scan_cg_en_i),
    .fetch_enable_i(fetch_enable_i),
    .ctrl_busy_o(gold_ctrl_busy_o),
    .is_decoding_o(gold_is_decoding_o),
    .instr_valid_i(instr_valid_i),
    .instr_rdata_i(instr_rdata_i),
    .instr_req_o(gold_instr_req_o),
    .is_compressed_i(is_compressed_i),
    .illegal_c_insn_i(illegal_c_insn_i),
    .branch_in_ex_o(gold_branch_in_ex_o),
    .branch_decision_i(branch_decision_i),
    .jump_target_o(gold_jump_target_o),
    .ctrl_transfer_insn_in_dec_o(gold_ctrl_transfer_insn_in_dec_o),
    .clear_instr_valid_o(gold_clear_instr_valid_o),
    .pc_set_o(gold_pc_set_o),
    .pc_mux_o(gold_pc_mux_o),
    .exc_pc_mux_o(gold_exc_pc_mux_o),
    .trap_addr_mux_o(gold_trap_addr_mux_o),
    .is_fetch_failed_i(is_fetch_failed_i),
    .pc_id_i(pc_id_i),
    .halt_if_o(gold_halt_if_o),
    .id_ready_o(gold_id_ready_o),
    .ex_ready_i(ex_ready_i),
    .wb_ready_i(wb_ready_i),
    .id_valid_o(gold_id_valid_o),
    .ex_valid_i(ex_valid_i),
    .pc_ex_o(gold_pc_ex_o),
    .alu_operand_a_ex_o(gold_alu_operand_a_ex_o),
    .alu_operand_b_ex_o(gold_alu_operand_b_ex_o),
    .alu_operand_c_ex_o(gold_alu_operand_c_ex_o),
    .bmask_a_ex_o(gold_bmask_a_ex_o),
    .bmask_b_ex_o(gold_bmask_b_ex_o),
    .imm_vec_ext_ex_o(gold_imm_vec_ext_ex_o),
    .alu_vec_mode_ex_o(gold_alu_vec_mode_ex_o),
    .regfile_waddr_ex_o(gold_regfile_waddr_ex_o),
    .regfile_we_ex_o(gold_regfile_we_ex_o),
    .regfile_alu_waddr_ex_o(gold_regfile_alu_waddr_ex_o),
    .regfile_alu_we_ex_o(gold_regfile_alu_we_ex_o),
    .alu_en_ex_o(gold_alu_en_ex_o),
    .alu_operator_ex_o(gold_alu_operator_ex_o),
    .alu_is_clpx_ex_o(gold_alu_is_clpx_ex_o),
    .alu_is_subrot_ex_o(gold_alu_is_subrot_ex_o),
    .alu_clpx_shift_ex_o(gold_alu_clpx_shift_ex_o),
    .mult_operator_ex_o(gold_mult_operator_ex_o),
    .mult_operand_a_ex_o(gold_mult_operand_a_ex_o),
    .mult_operand_b_ex_o(gold_mult_operand_b_ex_o),
    .mult_operand_c_ex_o(gold_mult_operand_c_ex_o),
    .mult_en_ex_o(gold_mult_en_ex_o),
    .mult_sel_subword_ex_o(gold_mult_sel_subword_ex_o),
    .mult_signed_mode_ex_o(gold_mult_signed_mode_ex_o),
    .mult_imm_ex_o(gold_mult_imm_ex_o),
    .mult_dot_op_a_ex_o(gold_mult_dot_op_a_ex_o),
    .mult_dot_op_b_ex_o(gold_mult_dot_op_b_ex_o),
    .mult_dot_op_c_ex_o(gold_mult_dot_op_c_ex_o),
    .mult_dot_signed_ex_o(gold_mult_dot_signed_ex_o),
    .mult_is_clpx_ex_o(gold_mult_is_clpx_ex_o),
    .mult_clpx_shift_ex_o(gold_mult_clpx_shift_ex_o),
    .mult_clpx_img_ex_o(gold_mult_clpx_img_ex_o),
    .apu_en_ex_o(gold_apu_en_ex_o),
    .apu_op_ex_o(gold_apu_op_ex_o),
    .apu_lat_ex_o(gold_apu_lat_ex_o),
    .apu_operands_ex_o(gold_apu_operands_ex_o),
    .apu_flags_ex_o(gold_apu_flags_ex_o),
    .apu_waddr_ex_o(gold_apu_waddr_ex_o),
    .apu_read_regs_o(gold_apu_read_regs_o),
    .apu_read_regs_valid_o(gold_apu_read_regs_valid_o),
    .apu_read_dep_i(apu_read_dep_i),
    .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
    .apu_write_regs_o(gold_apu_write_regs_o),
    .apu_write_regs_valid_o(gold_apu_write_regs_valid_o),
    .apu_write_dep_i(apu_write_dep_i),
    .apu_perf_dep_o(gold_apu_perf_dep_o),
    .apu_busy_i(apu_busy_i),
    .fs_off_i(fs_off_i),
    .frm_i(frm_i),
    .csr_access_ex_o(gold_csr_access_ex_o),
    .csr_op_ex_o(gold_csr_op_ex_o),
    .current_priv_lvl_i(current_priv_lvl_i),
    .csr_irq_sec_o(gold_csr_irq_sec_o),
    .csr_cause_o(gold_csr_cause_o),
    .csr_save_if_o(gold_csr_save_if_o),
    .csr_save_id_o(gold_csr_save_id_o),
    .csr_save_ex_o(gold_csr_save_ex_o),
    .csr_restore_mret_id_o(gold_csr_restore_mret_id_o),
    .csr_restore_uret_id_o(gold_csr_restore_uret_id_o),
    .csr_restore_dret_id_o(gold_csr_restore_dret_id_o),
    .csr_save_cause_o(gold_csr_save_cause_o),
    .hwlp_start_o(gold_hwlp_start_o),
    .hwlp_end_o(gold_hwlp_end_o),
    .hwlp_cnt_o(gold_hwlp_cnt_o),
    .hwlp_jump_o(gold_hwlp_jump_o),
    .hwlp_target_o(gold_hwlp_target_o),
    .data_req_ex_o(gold_data_req_ex_o),
    .data_we_ex_o(gold_data_we_ex_o),
    .data_type_ex_o(gold_data_type_ex_o),
    .data_sign_ext_ex_o(gold_data_sign_ext_ex_o),
    .data_reg_offset_ex_o(gold_data_reg_offset_ex_o),
    .data_load_event_ex_o(gold_data_load_event_ex_o),
    .data_misaligned_ex_o(gold_data_misaligned_ex_o),
    .prepost_useincr_ex_o(gold_prepost_useincr_ex_o),
    .data_misaligned_i(data_misaligned_i),
    .data_err_i(data_err_i),
    .data_err_ack_o(gold_data_err_ack_o),
    .atop_ex_o(gold_atop_ex_o),
    .irq_i(irq_i),
    .irq_sec_i(irq_sec_i),
    .mie_bypass_i(mie_bypass_i),
    .mip_o(gold_mip_o),
    .m_irq_enable_i(m_irq_enable_i),
    .u_irq_enable_i(u_irq_enable_i),
    .irq_ack_o(gold_irq_ack_o),
    .irq_id_o(gold_irq_id_o),
    .exc_cause_o(gold_exc_cause_o),
    .debug_mode_o(gold_debug_mode_o),
    .debug_cause_o(gold_debug_cause_o),
    .debug_csr_save_o(gold_debug_csr_save_o),
    .debug_req_i(debug_req_i),
    .debug_single_step_i(debug_single_step_i),
    .debug_ebreakm_i(debug_ebreakm_i),
    .debug_ebreaku_i(debug_ebreaku_i),
    .trigger_match_i(trigger_match_i),
    .debug_p_elw_no_sleep_o(gold_debug_p_elw_no_sleep_o),
    .debug_havereset_o(gold_debug_havereset_o),
    .debug_running_o(gold_debug_running_o),
    .debug_halted_o(gold_debug_halted_o),
    .wake_from_sleep_o(gold_wake_from_sleep_o),
    .regfile_waddr_wb_i(regfile_waddr_wb_i),
    .regfile_we_wb_i(regfile_we_wb_i),
    .regfile_we_wb_power_i(regfile_we_wb_power_i),
    .regfile_wdata_wb_i(regfile_wdata_wb_i),
    .regfile_alu_waddr_fw_i(regfile_alu_waddr_fw_i),
    .regfile_alu_we_fw_i(regfile_alu_we_fw_i),
    .regfile_alu_we_fw_power_i(regfile_alu_we_fw_power_i),
    .regfile_alu_wdata_fw_i(regfile_alu_wdata_fw_i),
    .mult_multicycle_i(mult_multicycle_i),
    .mhpmevent_minstret_o(gold_mhpmevent_minstret_o),
    .mhpmevent_load_o(gold_mhpmevent_load_o),
    .mhpmevent_store_o(gold_mhpmevent_store_o),
    .mhpmevent_jump_o(gold_mhpmevent_jump_o),
    .mhpmevent_branch_o(gold_mhpmevent_branch_o),
    .mhpmevent_branch_taken_o(gold_mhpmevent_branch_taken_o),
    .mhpmevent_compressed_o(gold_mhpmevent_compressed_o),
    .mhpmevent_jr_stall_o(gold_mhpmevent_jr_stall_o),
    .mhpmevent_imiss_o(gold_mhpmevent_imiss_o),
    .mhpmevent_ld_stall_o(gold_mhpmevent_ld_stall_o),
    .mhpmevent_pipe_stall_o(gold_mhpmevent_pipe_stall_o),
    .perf_imiss_i(perf_imiss_i),
    .mcounteren_i(mcounteren_i)
  );

  cv32e40p_id_stage_gate gate (
    .clk(clk),
    .clk_ungated_i(clk_ungated_i),
    .rst_n(rst_n),
    .scan_cg_en_i(scan_cg_en_i),
    .fetch_enable_i(fetch_enable_i),
    .ctrl_busy_o(gate_ctrl_busy_o),
    .is_decoding_o(gate_is_decoding_o),
    .instr_valid_i(instr_valid_i),
    .instr_rdata_i(instr_rdata_i),
    .instr_req_o(gate_instr_req_o),
    .is_compressed_i(is_compressed_i),
    .illegal_c_insn_i(illegal_c_insn_i),
    .branch_in_ex_o(gate_branch_in_ex_o),
    .branch_decision_i(branch_decision_i),
    .jump_target_o(gate_jump_target_o),
    .ctrl_transfer_insn_in_dec_o(gate_ctrl_transfer_insn_in_dec_o),
    .clear_instr_valid_o(gate_clear_instr_valid_o),
    .pc_set_o(gate_pc_set_o),
    .pc_mux_o(gate_pc_mux_o),
    .exc_pc_mux_o(gate_exc_pc_mux_o),
    .trap_addr_mux_o(gate_trap_addr_mux_o),
    .is_fetch_failed_i(is_fetch_failed_i),
    .pc_id_i(pc_id_i),
    .halt_if_o(gate_halt_if_o),
    .id_ready_o(gate_id_ready_o),
    .ex_ready_i(ex_ready_i),
    .wb_ready_i(wb_ready_i),
    .id_valid_o(gate_id_valid_o),
    .ex_valid_i(ex_valid_i),
    .pc_ex_o(gate_pc_ex_o),
    .alu_operand_a_ex_o(gate_alu_operand_a_ex_o),
    .alu_operand_b_ex_o(gate_alu_operand_b_ex_o),
    .alu_operand_c_ex_o(gate_alu_operand_c_ex_o),
    .bmask_a_ex_o(gate_bmask_a_ex_o),
    .bmask_b_ex_o(gate_bmask_b_ex_o),
    .imm_vec_ext_ex_o(gate_imm_vec_ext_ex_o),
    .alu_vec_mode_ex_o(gate_alu_vec_mode_ex_o),
    .regfile_waddr_ex_o(gate_regfile_waddr_ex_o),
    .regfile_we_ex_o(gate_regfile_we_ex_o),
    .regfile_alu_waddr_ex_o(gate_regfile_alu_waddr_ex_o),
    .regfile_alu_we_ex_o(gate_regfile_alu_we_ex_o),
    .alu_en_ex_o(gate_alu_en_ex_o),
    .alu_operator_ex_o(gate_alu_operator_ex_o),
    .alu_is_clpx_ex_o(gate_alu_is_clpx_ex_o),
    .alu_is_subrot_ex_o(gate_alu_is_subrot_ex_o),
    .alu_clpx_shift_ex_o(gate_alu_clpx_shift_ex_o),
    .mult_operator_ex_o(gate_mult_operator_ex_o),
    .mult_operand_a_ex_o(gate_mult_operand_a_ex_o),
    .mult_operand_b_ex_o(gate_mult_operand_b_ex_o),
    .mult_operand_c_ex_o(gate_mult_operand_c_ex_o),
    .mult_en_ex_o(gate_mult_en_ex_o),
    .mult_sel_subword_ex_o(gate_mult_sel_subword_ex_o),
    .mult_signed_mode_ex_o(gate_mult_signed_mode_ex_o),
    .mult_imm_ex_o(gate_mult_imm_ex_o),
    .mult_dot_op_a_ex_o(gate_mult_dot_op_a_ex_o),
    .mult_dot_op_b_ex_o(gate_mult_dot_op_b_ex_o),
    .mult_dot_op_c_ex_o(gate_mult_dot_op_c_ex_o),
    .mult_dot_signed_ex_o(gate_mult_dot_signed_ex_o),
    .mult_is_clpx_ex_o(gate_mult_is_clpx_ex_o),
    .mult_clpx_shift_ex_o(gate_mult_clpx_shift_ex_o),
    .mult_clpx_img_ex_o(gate_mult_clpx_img_ex_o),
    .apu_en_ex_o(gate_apu_en_ex_o),
    .apu_op_ex_o(gate_apu_op_ex_o),
    .apu_lat_ex_o(gate_apu_lat_ex_o),
    .apu_operands_ex_o(gate_apu_operands_ex_o),
    .apu_flags_ex_o(gate_apu_flags_ex_o),
    .apu_waddr_ex_o(gate_apu_waddr_ex_o),
    .apu_read_regs_o(gate_apu_read_regs_o),
    .apu_read_regs_valid_o(gate_apu_read_regs_valid_o),
    .apu_read_dep_i(apu_read_dep_i),
    .apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
    .apu_write_regs_o(gate_apu_write_regs_o),
    .apu_write_regs_valid_o(gate_apu_write_regs_valid_o),
    .apu_write_dep_i(apu_write_dep_i),
    .apu_perf_dep_o(gate_apu_perf_dep_o),
    .apu_busy_i(apu_busy_i),
    .fs_off_i(fs_off_i),
    .frm_i(frm_i),
    .csr_access_ex_o(gate_csr_access_ex_o),
    .csr_op_ex_o(gate_csr_op_ex_o),
    .current_priv_lvl_i(current_priv_lvl_i),
    .csr_irq_sec_o(gate_csr_irq_sec_o),
    .csr_cause_o(gate_csr_cause_o),
    .csr_save_if_o(gate_csr_save_if_o),
    .csr_save_id_o(gate_csr_save_id_o),
    .csr_save_ex_o(gate_csr_save_ex_o),
    .csr_restore_mret_id_o(gate_csr_restore_mret_id_o),
    .csr_restore_uret_id_o(gate_csr_restore_uret_id_o),
    .csr_restore_dret_id_o(gate_csr_restore_dret_id_o),
    .csr_save_cause_o(gate_csr_save_cause_o),
    .hwlp_start_o(gate_hwlp_start_o),
    .hwlp_end_o(gate_hwlp_end_o),
    .hwlp_cnt_o(gate_hwlp_cnt_o),
    .hwlp_jump_o(gate_hwlp_jump_o),
    .hwlp_target_o(gate_hwlp_target_o),
    .data_req_ex_o(gate_data_req_ex_o),
    .data_we_ex_o(gate_data_we_ex_o),
    .data_type_ex_o(gate_data_type_ex_o),
    .data_sign_ext_ex_o(gate_data_sign_ext_ex_o),
    .data_reg_offset_ex_o(gate_data_reg_offset_ex_o),
    .data_load_event_ex_o(gate_data_load_event_ex_o),
    .data_misaligned_ex_o(gate_data_misaligned_ex_o),
    .prepost_useincr_ex_o(gate_prepost_useincr_ex_o),
    .data_misaligned_i(data_misaligned_i),
    .data_err_i(data_err_i),
    .data_err_ack_o(gate_data_err_ack_o),
    .atop_ex_o(gate_atop_ex_o),
    .irq_i(irq_i),
    .irq_sec_i(irq_sec_i),
    .mie_bypass_i(mie_bypass_i),
    .mip_o(gate_mip_o),
    .m_irq_enable_i(m_irq_enable_i),
    .u_irq_enable_i(u_irq_enable_i),
    .irq_ack_o(gate_irq_ack_o),
    .irq_id_o(gate_irq_id_o),
    .exc_cause_o(gate_exc_cause_o),
    .debug_mode_o(gate_debug_mode_o),
    .debug_cause_o(gate_debug_cause_o),
    .debug_csr_save_o(gate_debug_csr_save_o),
    .debug_req_i(debug_req_i),
    .debug_single_step_i(debug_single_step_i),
    .debug_ebreakm_i(debug_ebreakm_i),
    .debug_ebreaku_i(debug_ebreaku_i),
    .trigger_match_i(trigger_match_i),
    .debug_p_elw_no_sleep_o(gate_debug_p_elw_no_sleep_o),
    .debug_havereset_o(gate_debug_havereset_o),
    .debug_running_o(gate_debug_running_o),
    .debug_halted_o(gate_debug_halted_o),
    .wake_from_sleep_o(gate_wake_from_sleep_o),
    .regfile_waddr_wb_i(regfile_waddr_wb_i),
    .regfile_we_wb_i(regfile_we_wb_i),
    .regfile_we_wb_power_i(regfile_we_wb_power_i),
    .regfile_wdata_wb_i(regfile_wdata_wb_i),
    .regfile_alu_waddr_fw_i(regfile_alu_waddr_fw_i),
    .regfile_alu_we_fw_i(regfile_alu_we_fw_i),
    .regfile_alu_we_fw_power_i(regfile_alu_we_fw_power_i),
    .regfile_alu_wdata_fw_i(regfile_alu_wdata_fw_i),
    .mult_multicycle_i(mult_multicycle_i),
    .mhpmevent_minstret_o(gate_mhpmevent_minstret_o),
    .mhpmevent_load_o(gate_mhpmevent_load_o),
    .mhpmevent_store_o(gate_mhpmevent_store_o),
    .mhpmevent_jump_o(gate_mhpmevent_jump_o),
    .mhpmevent_branch_o(gate_mhpmevent_branch_o),
    .mhpmevent_branch_taken_o(gate_mhpmevent_branch_taken_o),
    .mhpmevent_compressed_o(gate_mhpmevent_compressed_o),
    .mhpmevent_jr_stall_o(gate_mhpmevent_jr_stall_o),
    .mhpmevent_imiss_o(gate_mhpmevent_imiss_o),
    .mhpmevent_ld_stall_o(gate_mhpmevent_ld_stall_o),
    .mhpmevent_pipe_stall_o(gate_mhpmevent_pipe_stall_o),
    .perf_imiss_i(perf_imiss_i),
    .mcounteren_i(mcounteren_i)
  );

  wire [1023:0] gold_regfile_mem_q = gold.register_file_i.mem;
  wire [1023:0] gate_regfile_mem_q = gate.register_file_i.mem;
  wire [1023:0] gold_regfile_mem_fp_q = gold.register_file_i.mem_fp;
  wire [1023:0] gate_regfile_mem_fp_q = gate.register_file_i.mem_fp;

  always @(posedge clk) begin
    if (rst_n) begin
      assert (gold_regfile_mem_q == gate_regfile_mem_q);
    assert (gold_regfile_mem_fp_q == gate_regfile_mem_fp_q);
    assert (gold_ctrl_busy_o == gate_ctrl_busy_o);
    assert (gold_is_decoding_o == gate_is_decoding_o);
    assert (gold_instr_req_o == gate_instr_req_o);
    assert (gold_branch_in_ex_o == gate_branch_in_ex_o);
    assert (gold_jump_target_o == gate_jump_target_o);
    assert (gold_ctrl_transfer_insn_in_dec_o == gate_ctrl_transfer_insn_in_dec_o);
    assert (gold_clear_instr_valid_o == gate_clear_instr_valid_o);
    assert (gold_pc_set_o == gate_pc_set_o);
    assert (gold_pc_mux_o == gate_pc_mux_o);
    assert (gold_exc_pc_mux_o == gate_exc_pc_mux_o);
    assert (gold_trap_addr_mux_o == gate_trap_addr_mux_o);
    assert (gold_halt_if_o == gate_halt_if_o);
    assert (gold_id_ready_o == gate_id_ready_o);
    assert (gold_id_valid_o == gate_id_valid_o);
    assert (gold_pc_ex_o == gate_pc_ex_o);
    assert (gold_alu_operand_a_ex_o == gate_alu_operand_a_ex_o);
    assert (gold_alu_operand_b_ex_o == gate_alu_operand_b_ex_o);
    assert (gold_alu_operand_c_ex_o == gate_alu_operand_c_ex_o);
    assert (gold_bmask_a_ex_o == gate_bmask_a_ex_o);
    assert (gold_bmask_b_ex_o == gate_bmask_b_ex_o);
    assert (gold_imm_vec_ext_ex_o == gate_imm_vec_ext_ex_o);
    assert (gold_alu_vec_mode_ex_o == gate_alu_vec_mode_ex_o);
    assert (gold_regfile_waddr_ex_o == gate_regfile_waddr_ex_o);
    assert (gold_regfile_we_ex_o == gate_regfile_we_ex_o);
    assert (gold_regfile_alu_waddr_ex_o == gate_regfile_alu_waddr_ex_o);
    assert (gold_regfile_alu_we_ex_o == gate_regfile_alu_we_ex_o);
    assert (gold_alu_en_ex_o == gate_alu_en_ex_o);
    assert (gold_alu_operator_ex_o == gate_alu_operator_ex_o);
    assert (gold_alu_is_clpx_ex_o == gate_alu_is_clpx_ex_o);
    assert (gold_alu_is_subrot_ex_o == gate_alu_is_subrot_ex_o);
    assert (gold_alu_clpx_shift_ex_o == gate_alu_clpx_shift_ex_o);
    assert (gold_mult_operator_ex_o == gate_mult_operator_ex_o);
    assert (gold_mult_operand_a_ex_o == gate_mult_operand_a_ex_o);
    assert (gold_mult_operand_b_ex_o == gate_mult_operand_b_ex_o);
    assert (gold_mult_operand_c_ex_o == gate_mult_operand_c_ex_o);
    assert (gold_mult_en_ex_o == gate_mult_en_ex_o);
    assert (gold_mult_sel_subword_ex_o == gate_mult_sel_subword_ex_o);
    assert (gold_mult_signed_mode_ex_o == gate_mult_signed_mode_ex_o);
    assert (gold_mult_imm_ex_o == gate_mult_imm_ex_o);
    assert (gold_mult_dot_op_a_ex_o == gate_mult_dot_op_a_ex_o);
    assert (gold_mult_dot_op_b_ex_o == gate_mult_dot_op_b_ex_o);
    assert (gold_mult_dot_op_c_ex_o == gate_mult_dot_op_c_ex_o);
    assert (gold_mult_dot_signed_ex_o == gate_mult_dot_signed_ex_o);
    assert (gold_mult_is_clpx_ex_o == gate_mult_is_clpx_ex_o);
    assert (gold_mult_clpx_shift_ex_o == gate_mult_clpx_shift_ex_o);
    assert (gold_mult_clpx_img_ex_o == gate_mult_clpx_img_ex_o);
    assert (gold_apu_en_ex_o == gate_apu_en_ex_o);
    assert (gold_apu_op_ex_o == gate_apu_op_ex_o);
    assert (gold_apu_lat_ex_o == gate_apu_lat_ex_o);
    assert (gold_apu_operands_ex_o == gate_apu_operands_ex_o);
    assert (gold_apu_flags_ex_o == gate_apu_flags_ex_o);
    assert (gold_apu_waddr_ex_o == gate_apu_waddr_ex_o);
    assert (gold_apu_read_regs_o == gate_apu_read_regs_o);
    assert (gold_apu_read_regs_valid_o == gate_apu_read_regs_valid_o);
    assert (gold_apu_write_regs_o == gate_apu_write_regs_o);
    assert (gold_apu_write_regs_valid_o == gate_apu_write_regs_valid_o);
    assert (gold_apu_perf_dep_o == gate_apu_perf_dep_o);
    assert (gold_csr_access_ex_o == gate_csr_access_ex_o);
    assert (gold_csr_op_ex_o == gate_csr_op_ex_o);
    assert (gold_csr_irq_sec_o == gate_csr_irq_sec_o);
    assert (gold_csr_cause_o == gate_csr_cause_o);
    assert (gold_csr_save_if_o == gate_csr_save_if_o);
    assert (gold_csr_save_id_o == gate_csr_save_id_o);
    assert (gold_csr_save_ex_o == gate_csr_save_ex_o);
    assert (gold_csr_restore_mret_id_o == gate_csr_restore_mret_id_o);
    assert (gold_csr_restore_uret_id_o == gate_csr_restore_uret_id_o);
    assert (gold_csr_restore_dret_id_o == gate_csr_restore_dret_id_o);
    assert (gold_csr_save_cause_o == gate_csr_save_cause_o);
    assert (gold_hwlp_start_o == gate_hwlp_start_o);
    assert (gold_hwlp_end_o == gate_hwlp_end_o);
    assert (gold_hwlp_cnt_o == gate_hwlp_cnt_o);
    assert (gold_hwlp_jump_o == gate_hwlp_jump_o);
    assert (gold_hwlp_target_o == gate_hwlp_target_o);
    assert (gold_data_req_ex_o == gate_data_req_ex_o);
    assert (gold_data_we_ex_o == gate_data_we_ex_o);
    assert (gold_data_type_ex_o == gate_data_type_ex_o);
    assert (gold_data_sign_ext_ex_o == gate_data_sign_ext_ex_o);
    assert (gold_data_reg_offset_ex_o == gate_data_reg_offset_ex_o);
    assert (gold_data_load_event_ex_o == gate_data_load_event_ex_o);
    assert (gold_data_misaligned_ex_o == gate_data_misaligned_ex_o);
    assert (gold_prepost_useincr_ex_o == gate_prepost_useincr_ex_o);
    assert (gold_data_err_ack_o == gate_data_err_ack_o);
    assert (gold_atop_ex_o == gate_atop_ex_o);
    assert (gold_mip_o == gate_mip_o);
    assert (gold_irq_ack_o == gate_irq_ack_o);
    assert (gold_irq_id_o == gate_irq_id_o);
    assert (gold_exc_cause_o == gate_exc_cause_o);
    assert (gold_debug_mode_o == gate_debug_mode_o);
    assert (gold_debug_cause_o == gate_debug_cause_o);
    assert (gold_debug_csr_save_o == gate_debug_csr_save_o);
    assert (gold_debug_p_elw_no_sleep_o == gate_debug_p_elw_no_sleep_o);
    assert (gold_debug_havereset_o == gate_debug_havereset_o);
    assert (gold_debug_running_o == gate_debug_running_o);
    assert (gold_debug_halted_o == gate_debug_halted_o);
    assert (gold_wake_from_sleep_o == gate_wake_from_sleep_o);
    assert (gold_mhpmevent_minstret_o == gate_mhpmevent_minstret_o);
    assert (gold_mhpmevent_load_o == gate_mhpmevent_load_o);
    assert (gold_mhpmevent_store_o == gate_mhpmevent_store_o);
    assert (gold_mhpmevent_jump_o == gate_mhpmevent_jump_o);
    assert (gold_mhpmevent_branch_o == gate_mhpmevent_branch_o);
    assert (gold_mhpmevent_branch_taken_o == gate_mhpmevent_branch_taken_o);
    assert (gold_mhpmevent_compressed_o == gate_mhpmevent_compressed_o);
    assert (gold_mhpmevent_jr_stall_o == gate_mhpmevent_jr_stall_o);
    assert (gold_mhpmevent_imiss_o == gate_mhpmevent_imiss_o);
    assert (gold_mhpmevent_ld_stall_o == gate_mhpmevent_ld_stall_o);
    assert (gold_mhpmevent_pipe_stall_o == gate_mhpmevent_pipe_stall_o);
    end
  end
endmodule
