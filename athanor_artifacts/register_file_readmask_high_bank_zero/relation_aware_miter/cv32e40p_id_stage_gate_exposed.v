module cv32e40p_register_file_gate (
	clk,
	rst_n,
	scan_cg_en_i,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	raddr_c_i,
	rdata_c_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	waddr_b_i,
	wdata_b_i,
	we_b_i
);
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire clk;
	input wire rst_n;
	input wire scan_cg_en_i;
	input wire [ADDR_WIDTH - 1:0] raddr_a_i;
	output wire [DATA_WIDTH - 1:0] rdata_a_o;
	input wire [ADDR_WIDTH - 1:0] raddr_b_i;
	output wire [DATA_WIDTH - 1:0] rdata_b_o;
	input wire [ADDR_WIDTH - 1:0] raddr_c_i;
	output wire [DATA_WIDTH - 1:0] rdata_c_o;
	input wire [ADDR_WIDTH - 1:0] waddr_a_i;
	input wire [DATA_WIDTH - 1:0] wdata_a_i;
	input wire we_a_i;
	input wire [ADDR_WIDTH - 1:0] waddr_b_i;
	input wire [DATA_WIDTH - 1:0] wdata_b_i;
	input wire we_b_i;
	localparam NUM_WORDS = 2 ** (ADDR_WIDTH - 1);
	localparam NUM_FP_WORDS = 2 ** (ADDR_WIDTH - 1);
	localparam NUM_TOT_WORDS = (FPU ? (ZFINX ? NUM_WORDS : NUM_WORDS + NUM_FP_WORDS) : NUM_WORDS);
	reg [(NUM_WORDS * DATA_WIDTH) - 1:0] mem;
	reg [(NUM_FP_WORDS * DATA_WIDTH) - 1:0] mem_fp;
	wire [ADDR_WIDTH - 1:0] waddr_a;
	wire [ADDR_WIDTH - 1:0] waddr_b;
	wire [NUM_TOT_WORDS - 1:0] we_a_dec;
	wire [NUM_TOT_WORDS - 1:0] we_b_dec;
	assign rdata_a_o = ((FPU && !ZFINX) && raddr_a_i[5] ? mem_fp[raddr_a_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_a_i[4:0] * DATA_WIDTH+:DATA_WIDTH] & {DATA_WIDTH {~raddr_a_i[5]}});
	assign rdata_b_o = ((FPU && !ZFINX) && raddr_b_i[5] ? mem_fp[raddr_b_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_b_i[4:0] * DATA_WIDTH+:DATA_WIDTH] & {DATA_WIDTH {~raddr_b_i[5]}});
	assign rdata_c_o = ((FPU && !ZFINX) && raddr_c_i[5] ? mem_fp[raddr_c_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_c_i[4:0] * DATA_WIDTH+:DATA_WIDTH] & {DATA_WIDTH {~raddr_c_i[5]}});
	assign waddr_a = waddr_a_i;
	assign waddr_b = waddr_b_i;
	genvar _gv_gidx_1;
	generate
		for (_gv_gidx_1 = 0; _gv_gidx_1 < NUM_TOT_WORDS; _gv_gidx_1 = _gv_gidx_1 + 1) begin : gen_we_decoder
			localparam gidx = _gv_gidx_1;
			assign we_a_dec[gidx] = (waddr_a == gidx ? we_a_i : 1'b0);
			assign we_b_dec[gidx] = (waddr_b == gidx ? we_b_i : 1'b0);
		end
	endgenerate
	genvar _gv_i_1;
	genvar _gv_l_1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			mem[0+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
		else
			mem[0+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
	generate
		for (_gv_i_1 = 1; _gv_i_1 < NUM_WORDS; _gv_i_1 = _gv_i_1 + 1) begin : gen_rf
			localparam i = _gv_i_1;
			always @(posedge clk or negedge rst_n) begin : register_write_behavioral
				if (rst_n == 1'b0)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
				else if (we_b_dec[i] == 1'b1)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_b_i;
				else if (we_a_dec[i] == 1'b1)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_a_i;
			end
		end
		if ((FPU == 1) && (ZFINX == 0)) begin : gen_mem_fp_write
			for (_gv_l_1 = 0; _gv_l_1 < NUM_FP_WORDS; _gv_l_1 = _gv_l_1 + 1) begin : genblk1
				localparam l = _gv_l_1;
				always @(posedge clk or negedge rst_n) begin : fp_regs
					if (rst_n == 1'b0)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= 1'sb0;
					else if (we_b_dec[l + NUM_WORDS] == 1'b1)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= wdata_b_i;
					else if (we_a_dec[l + NUM_WORDS] == 1'b1)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= wdata_a_i;
				end
			end
		end
		else begin : gen_no_mem_fp_write
			wire [NUM_FP_WORDS * DATA_WIDTH:1] sv2v_tmp_E9FFD;
			assign sv2v_tmp_E9FFD = 'b0;
			always @(*) mem_fp = sv2v_tmp_E9FFD;
		end
	endgenerate
endmodule
module cv32e40p_compressed_decoder_gate (
	instr_i,
	instr_o,
	is_compressed_o,
	illegal_instr_o
);
	reg _sv2v_0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire [31:0] instr_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output reg illegal_instr_o;
	localparam cv32e40p_pkg_OPCODE_BRANCH = 7'h63;
	localparam cv32e40p_pkg_OPCODE_JAL = 7'h6f;
	localparam cv32e40p_pkg_OPCODE_JALR = 7'h67;
	localparam cv32e40p_pkg_OPCODE_LOAD = 7'h03;
	localparam cv32e40p_pkg_OPCODE_LOAD_FP = 7'h07;
	localparam cv32e40p_pkg_OPCODE_LUI = 7'h37;
	localparam cv32e40p_pkg_OPCODE_OP = 7'h33;
	localparam cv32e40p_pkg_OPCODE_OPIMM = 7'h13;
	localparam cv32e40p_pkg_OPCODE_STORE = 7'h23;
	localparam cv32e40p_pkg_OPCODE_STORE_FP = 7'h27;
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_instr_o = 1'b0;
		instr_o = 1'sb0;
		(* full_case, parallel_case *)
		case (instr_i[1:0])
			2'b00:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h041, instr_i[4:2], cv32e40p_pkg_OPCODE_OPIMM};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b001:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12:10], 5'b00001, instr_i[9:7], 5'b01101, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD};
					3'b011:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b101:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b011, instr_i[11:10], 3'b000, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, cv32e40p_pkg_OPCODE_STORE};
					3'b111:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], cv32e40p_pkg_OPCODE_JAL};
					3'b010:
						if (instr_i[11:7] == 5'b00000)
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
						else
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b011:
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
						else if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 17'h00202, cv32e40p_pkg_OPCODE_OPIMM};
						else if (instr_i[11:7] == 5'b00000)
							instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], cv32e40p_pkg_OPCODE_LUI};
						else
							instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], cv32e40p_pkg_OPCODE_LUI};
					3'b100:
						(* full_case, parallel_case *)
						case (instr_i[11:10])
							2'b00, 2'b01:
								if (instr_i[12] == 1'b1) begin
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
									illegal_instr_o = 1'b1;
								end
								else if (instr_i[6:2] == 5'b00000)
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
								else
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
							2'b11:
								(* full_case, parallel_case *)
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b10001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b100, 3'b101, 3'b110, 3'b111: illegal_instr_o = 1'b1;
								endcase
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 7'b0000001, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], cv32e40p_pkg_OPCODE_BRANCH};
				endcase
			2'b10:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000:
						if (instr_i[12] == 1'b1) begin
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
							illegal_instr_o = 1'b1;
						end
						else if ((instr_i[6:2] == 5'b00000) || (instr_i[11:7] == 5'b00000))
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
						else
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b001:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {3'b000, instr_i[4:2], instr_i[12], instr_i[6:5], 11'h013, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b011:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b100:
						if (instr_i[12] == 1'b0) begin
							if (instr_i[6:2] == 5'b00000) begin
								instr_o = {12'b000000000000, instr_i[11:7], 8'b00000000, cv32e40p_pkg_OPCODE_JALR};
								if (instr_i[11:7] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
							else if (instr_i[11:7] == 5'b00000)
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
							else
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
						end
						else if (instr_i[6:2] == 5'b00000) begin
							if (instr_i[11:7] == 5'b00000)
								instr_o = 32'h00100073;
							else
								instr_o = {12'b000000000000, instr_i[11:7], 8'b00000001, cv32e40p_pkg_OPCODE_JALR};
						end
						else if (instr_i[11:7] == 5'b00000)
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
						else
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
					3'b101:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {3'b000, instr_i[9:7], instr_i[12], instr_i[6:2], 8'h13, instr_i[11:10], 3'b000, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 2'b00, cv32e40p_pkg_OPCODE_STORE};
					3'b111:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 2'b00, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
				endcase
			default: instr_o = instr_i;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_decoder_gate (
	deassert_we_i,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	uret_insn_o,
	dret_insn_o,
	mret_dec_o,
	uret_dec_o,
	dret_dec_o,
	ecall_insn_o,
	wfi_o,
	fencei_insn_o,
	rega_used_o,
	regb_used_o,
	regc_used_o,
	reg_fp_a_o,
	reg_fp_b_o,
	reg_fp_c_o,
	reg_fp_d_o,
	bmask_a_mux_o,
	bmask_b_mux_o,
	alu_bmask_a_mux_sel_o,
	alu_bmask_b_mux_sel_o,
	instr_rdata_i,
	illegal_c_insn_i,
	alu_en_o,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	alu_op_c_mux_sel_o,
	alu_vec_o,
	alu_vec_mode_o,
	scalar_replication_o,
	scalar_replication_c_o,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	regc_mux_o,
	is_clpx_o,
	is_subrot_o,
	mult_operator_o,
	mult_int_en_o,
	mult_dot_en_o,
	mult_imm_mux_o,
	mult_sel_subword_o,
	mult_signed_mode_o,
	mult_dot_signed_o,
	fs_off_i,
	frm_i,
	fpu_dst_fmt_o,
	fpu_src_fmt_o,
	fpu_int_fmt_o,
	apu_en_o,
	apu_op_o,
	apu_lat_o,
	fp_rnd_mode_o,
	regfile_mem_we_o,
	regfile_alu_we_o,
	regfile_alu_we_dec_o,
	regfile_alu_waddr_sel_o,
	csr_access_o,
	csr_status_o,
	csr_op_o,
	current_priv_lvl_i,
	data_req_o,
	data_we_o,
	prepost_useincr_o,
	data_type_o,
	data_sign_extension_o,
	data_reg_offset_o,
	data_load_event_o,
	atop_o,
	hwlp_we_o,
	hwlp_target_mux_sel_o,
	hwlp_start_mux_sel_o,
	hwlp_cnt_mux_sel_o,
	debug_mode_i,
	debug_wfi_no_sleep_i,
	ctrl_transfer_insn_in_dec_o,
	ctrl_transfer_insn_in_id_o,
	ctrl_transfer_target_mux_sel_o,
	mcounteren_i
);
	reg _sv2v_0;
	parameter COREV_PULP = 1;
	parameter COREV_CLUSTER = 0;
	parameter A_EXTENSION = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter PULP_SECURE = 0;
	parameter USE_PMP = 0;
	parameter APU_WOP_CPU = 6;
	parameter DEBUG_TRIGGER_EN = 1;
	input wire deassert_we_i;
	output reg illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg uret_insn_o;
	output reg dret_insn_o;
	output reg mret_dec_o;
	output reg uret_dec_o;
	output reg dret_dec_o;
	output reg ecall_insn_o;
	output reg wfi_o;
	output reg fencei_insn_o;
	output reg rega_used_o;
	output reg regb_used_o;
	output reg regc_used_o;
	output reg reg_fp_a_o;
	output reg reg_fp_b_o;
	output reg reg_fp_c_o;
	output reg reg_fp_d_o;
	output reg [0:0] bmask_a_mux_o;
	output reg [1:0] bmask_b_mux_o;
	output reg alu_bmask_a_mux_sel_o;
	output reg alu_bmask_b_mux_sel_o;
	input wire [31:0] instr_rdata_i;
	input wire illegal_c_insn_i;
	output wire alu_en_o;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	output reg [6:0] alu_operator_o;
	output reg [2:0] alu_op_a_mux_sel_o;
	output reg [2:0] alu_op_b_mux_sel_o;
	output reg [1:0] alu_op_c_mux_sel_o;
	output reg alu_vec_o;
	output reg [1:0] alu_vec_mode_o;
	output reg scalar_replication_o;
	output reg scalar_replication_c_o;
	output reg [0:0] imm_a_mux_sel_o;
	output reg [3:0] imm_b_mux_sel_o;
	output reg [1:0] regc_mux_o;
	output reg is_clpx_o;
	output reg is_subrot_o;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	output reg [2:0] mult_operator_o;
	output wire mult_int_en_o;
	output wire mult_dot_en_o;
	output reg [0:0] mult_imm_mux_o;
	output reg mult_sel_subword_o;
	output reg [1:0] mult_signed_mode_o;
	output reg [1:0] mult_dot_signed_o;
	input wire fs_off_i;
	localparam cv32e40p_pkg_C_RM = 3;
	input wire [2:0] frm_i;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] cv32e40p_fpu_pkg_FP_FORMAT_BITS = 3;
	output reg [2:0] fpu_dst_fmt_o;
	output reg [2:0] fpu_src_fmt_o;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_INT_FORMATS = 4;
	localparam [31:0] cv32e40p_fpu_pkg_INT_FORMAT_BITS = 2;
	output reg [1:0] fpu_int_fmt_o;
	output wire apu_en_o;
	output reg [APU_WOP_CPU - 1:0] apu_op_o;
	output reg [1:0] apu_lat_o;
	output reg [2:0] fp_rnd_mode_o;
	output wire regfile_mem_we_o;
	output wire regfile_alu_we_o;
	output wire regfile_alu_we_dec_o;
	output reg regfile_alu_waddr_sel_o;
	output reg csr_access_o;
	output reg csr_status_o;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	output wire [1:0] csr_op_o;
	input wire [1:0] current_priv_lvl_i;
	output wire data_req_o;
	output reg data_we_o;
	output reg prepost_useincr_o;
	output reg [1:0] data_type_o;
	output reg [1:0] data_sign_extension_o;
	output reg [1:0] data_reg_offset_o;
	output reg data_load_event_o;
	output reg [5:0] atop_o;
	output wire [2:0] hwlp_we_o;
	output reg [1:0] hwlp_target_mux_sel_o;
	output reg [1:0] hwlp_start_mux_sel_o;
	output reg hwlp_cnt_mux_sel_o;
	input wire debug_mode_i;
	input wire debug_wfi_no_sleep_i;
	output wire [1:0] ctrl_transfer_insn_in_dec_o;
	output wire [1:0] ctrl_transfer_insn_in_id_o;
	output reg [1:0] ctrl_transfer_target_mux_sel_o;
	input wire [31:0] mcounteren_i;
	reg regfile_mem_we;
	reg regfile_alu_we;
	reg data_req;
	reg [2:0] hwlp_we;
	reg csr_illegal;
	reg [1:0] ctrl_transfer_insn;
	reg [1:0] csr_op;
	reg alu_en;
	reg mult_int_en;
	reg mult_dot_en;
	reg apu_en;
	reg check_fprm;
	localparam [31:0] cv32e40p_fpu_pkg_OP_BITS = 4;
	reg [3:0] fpu_op;
	reg fpu_op_mod;
	reg fpu_vec_op;
	reg [1:0] fp_op_group;
	localparam cv32e40p_pkg_AMO_ADD = 5'b00000;
	localparam cv32e40p_pkg_AMO_AND = 5'b01100;
	localparam cv32e40p_pkg_AMO_LR = 5'b00010;
	localparam cv32e40p_pkg_AMO_MAX = 5'b10100;
	localparam cv32e40p_pkg_AMO_MAXU = 5'b11100;
	localparam cv32e40p_pkg_AMO_MIN = 5'b10000;
	localparam cv32e40p_pkg_AMO_MINU = 5'b11000;
	localparam cv32e40p_pkg_AMO_OR = 5'b01000;
	localparam cv32e40p_pkg_AMO_SC = 5'b00011;
	localparam cv32e40p_pkg_AMO_SWAP = 5'b00001;
	localparam cv32e40p_pkg_AMO_XOR = 5'b00100;
	localparam cv32e40p_pkg_BMASK_A_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_REG = 1'b0;
	localparam cv32e40p_pkg_BMASK_A_S3 = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_ZERO = 1'b0;
	localparam cv32e40p_pkg_BMASK_B_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_B_ONE = 2'b11;
	localparam cv32e40p_pkg_BMASK_B_REG = 1'b0;
	localparam cv32e40p_pkg_BMASK_B_S2 = 2'b00;
	localparam cv32e40p_pkg_BMASK_B_S3 = 2'b01;
	localparam cv32e40p_pkg_BMASK_B_ZERO = 2'b10;
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	localparam cv32e40p_pkg_BRANCH_NONE = 2'b00;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16ALT = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP64 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP8 = 'd0;
	localparam [0:0] cv32e40p_pkg_C_RVD = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_RVF = 1'b1;
	localparam [0:0] cv32e40p_pkg_C_XF16 = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF16ALT = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF8 = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XFVEC = 1'b0;
	localparam cv32e40p_pkg_IMMA_Z = 1'b0;
	localparam cv32e40p_pkg_IMMA_ZERO = 1'b1;
	localparam cv32e40p_pkg_IMMB_BI = 4'b1011;
	localparam cv32e40p_pkg_IMMB_CLIP = 4'b1001;
	localparam cv32e40p_pkg_IMMB_I = 4'b0000;
	localparam cv32e40p_pkg_IMMB_PCINCR = 4'b0011;
	localparam cv32e40p_pkg_IMMB_S = 4'b0001;
	localparam cv32e40p_pkg_IMMB_S2 = 4'b0100;
	localparam cv32e40p_pkg_IMMB_SHUF = 4'b1000;
	localparam cv32e40p_pkg_IMMB_U = 4'b0010;
	localparam cv32e40p_pkg_IMMB_VS = 4'b0110;
	localparam cv32e40p_pkg_IMMB_VU = 4'b0111;
	localparam cv32e40p_pkg_JT_COND = 2'b11;
	localparam cv32e40p_pkg_JT_JAL = 2'b01;
	localparam cv32e40p_pkg_JT_JALR = 2'b10;
	localparam cv32e40p_pkg_MIMM_S3 = 1'b1;
	localparam cv32e40p_pkg_MIMM_ZERO = 1'b0;
	localparam cv32e40p_pkg_OPCODE_AMO = 7'h2f;
	localparam cv32e40p_pkg_OPCODE_AUIPC = 7'h17;
	localparam cv32e40p_pkg_OPCODE_BRANCH = 7'h63;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_0 = 7'h0b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_1 = 7'h2b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_2 = 7'h5b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_3 = 7'h7b;
	localparam cv32e40p_pkg_OPCODE_FENCE = 7'h0f;
	localparam cv32e40p_pkg_OPCODE_JAL = 7'h6f;
	localparam cv32e40p_pkg_OPCODE_JALR = 7'h67;
	localparam cv32e40p_pkg_OPCODE_LOAD = 7'h03;
	localparam cv32e40p_pkg_OPCODE_LOAD_FP = 7'h07;
	localparam cv32e40p_pkg_OPCODE_LUI = 7'h37;
	localparam cv32e40p_pkg_OPCODE_OP = 7'h33;
	localparam cv32e40p_pkg_OPCODE_OPIMM = 7'h13;
	localparam cv32e40p_pkg_OPCODE_OP_FMADD = 7'h43;
	localparam cv32e40p_pkg_OPCODE_OP_FMSUB = 7'h47;
	localparam cv32e40p_pkg_OPCODE_OP_FNMADD = 7'h4f;
	localparam cv32e40p_pkg_OPCODE_OP_FNMSUB = 7'h4b;
	localparam cv32e40p_pkg_OPCODE_OP_FP = 7'h53;
	localparam cv32e40p_pkg_OPCODE_STORE = 7'h23;
	localparam cv32e40p_pkg_OPCODE_STORE_FP = 7'h27;
	localparam cv32e40p_pkg_OPCODE_SYSTEM = 7'h73;
	localparam cv32e40p_pkg_OP_A_CURRPC = 3'b001;
	localparam cv32e40p_pkg_OP_A_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_A_REGA_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_A_REGB_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_A_REGC_OR_FWD = 3'b100;
	localparam cv32e40p_pkg_OP_B_BMASK = 3'b100;
	localparam cv32e40p_pkg_OP_B_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_B_REGA_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_B_REGB_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_B_REGC_OR_FWD = 3'b001;
	localparam cv32e40p_pkg_OP_C_JT = 2'b10;
	localparam cv32e40p_pkg_OP_C_REGB_OR_FWD = 2'b01;
	localparam cv32e40p_pkg_OP_C_REGC_OR_FWD = 2'b00;
	localparam cv32e40p_pkg_REGC_RD = 2'b01;
	localparam cv32e40p_pkg_REGC_S4 = 2'b00;
	localparam cv32e40p_pkg_REGC_ZERO = 2'b11;
	localparam cv32e40p_pkg_VEC_MODE16 = 2'b10;
	localparam cv32e40p_pkg_VEC_MODE32 = 2'b00;
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	function automatic [6:0] sv2v_cast_C07C4;
		input reg [6:0] inp;
		sv2v_cast_C07C4 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_9F558;
		input reg [2:0] inp;
		sv2v_cast_9F558 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_A1364;
		input reg [3:0] inp;
		sv2v_cast_A1364 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_9D6B6;
		input reg [2:0] inp;
		sv2v_cast_9D6B6 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_1BCDC;
		input reg [1:0] inp;
		sv2v_cast_1BCDC = inp;
	endfunction
	function automatic [1:0] sv2v_cast_EB06E;
		input reg [1:0] inp;
		sv2v_cast_EB06E = inp;
	endfunction
	always @(*) begin : instruction_decoder
		if (_sv2v_0)
			;
		ctrl_transfer_insn = cv32e40p_pkg_BRANCH_NONE;
		ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JAL;
		alu_en = 1'b1;
		alu_operator_o = sv2v_cast_C07C4(7'b0000011);
		alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
		alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
		alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGC_OR_FWD;
		alu_vec_o = 1'b0;
		alu_vec_mode_o = cv32e40p_pkg_VEC_MODE32;
		scalar_replication_o = 1'b0;
		scalar_replication_c_o = 1'b0;
		regc_mux_o = cv32e40p_pkg_REGC_ZERO;
		imm_a_mux_sel_o = cv32e40p_pkg_IMMA_ZERO;
		imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
		mult_int_en = 1'b0;
		mult_dot_en = 1'b0;
		mult_operator_o = sv2v_cast_9F558(3'b010);
		mult_imm_mux_o = cv32e40p_pkg_MIMM_ZERO;
		mult_signed_mode_o = 2'b00;
		mult_sel_subword_o = 1'b0;
		mult_dot_signed_o = 2'b00;
		apu_en = 1'b0;
		apu_op_o = 1'sb0;
		apu_lat_o = 1'sb0;
		fp_rnd_mode_o = 1'sb0;
		fpu_op = sv2v_cast_A1364(6);
		fpu_op_mod = 1'b0;
		fpu_vec_op = 1'b0;
		fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
		fpu_src_fmt_o = sv2v_cast_9D6B6('d0);
		fpu_int_fmt_o = sv2v_cast_1BCDC(2);
		check_fprm = 1'b0;
		fp_op_group = 2'd0;
		regfile_mem_we = 1'b0;
		regfile_alu_we = 1'b0;
		regfile_alu_waddr_sel_o = 1'b1;
		prepost_useincr_o = 1'b1;
		hwlp_we = 3'b000;
		hwlp_target_mux_sel_o = 2'b00;
		hwlp_start_mux_sel_o = 2'b00;
		hwlp_cnt_mux_sel_o = 1'b0;
		csr_access_o = 1'b0;
		csr_status_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = sv2v_cast_EB06E(2'b00);
		mret_insn_o = 1'b0;
		uret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 2'b00;
		data_reg_offset_o = 2'b00;
		data_req = 1'b0;
		data_load_event_o = 1'b0;
		atop_o = 6'b000000;
		illegal_insn_o = 1'b0;
		ebrk_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		wfi_o = 1'b0;
		fencei_insn_o = 1'b0;
		rega_used_o = 1'b0;
		regb_used_o = 1'b0;
		regc_used_o = 1'b0;
		reg_fp_a_o = 1'b0;
		reg_fp_b_o = 1'b0;
		reg_fp_c_o = 1'b0;
		reg_fp_d_o = 1'b0;
		bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
		bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
		alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_IMM;
		alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_IMM;
		is_clpx_o = 1'b0;
		is_subrot_o = 1'b0;
		mret_dec_o = 1'b0;
		uret_dec_o = 1'b0;
		dret_dec_o = 1'b0;
		(* full_case, parallel_case *)
		case (instr_rdata_i[6:0])
			cv32e40p_pkg_OPCODE_JAL: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JAL;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_JAL;
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_PCINCR;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_JALR: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JALR;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_JALR;
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_PCINCR;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				regfile_alu_we = 1'b1;
				rega_used_o = 1'b1;
				if (instr_rdata_i[14:12] != 3'b000) begin
					ctrl_transfer_insn = cv32e40p_pkg_BRANCH_NONE;
					regfile_alu_we = 1'b0;
					illegal_insn_o = 1'b1;
				end
			end
			cv32e40p_pkg_OPCODE_BRANCH: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_COND;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_COND;
				alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_JT;
				rega_used_o = 1'b1;
				regb_used_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: alu_operator_o = sv2v_cast_C07C4(7'b0001100);
					3'b001: alu_operator_o = sv2v_cast_C07C4(7'b0001101);
					3'b100: alu_operator_o = sv2v_cast_C07C4(7'b0000000);
					3'b101: alu_operator_o = sv2v_cast_C07C4(7'b0001010);
					3'b110: alu_operator_o = sv2v_cast_C07C4(7'b0000001);
					3'b111: alu_operator_o = sv2v_cast_C07C4(7'b0001011);
					default: illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_STORE: begin
				data_req = 1'b1;
				data_we_o = 1'b1;
				rega_used_o = 1'b1;
				regb_used_o = 1'b1;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: data_type_o = 2'b10;
					3'b001: data_type_o = 2'b01;
					3'b010: data_type_o = 2'b00;
					default: begin
						illegal_insn_o = 1'b1;
						data_req = 1'b0;
						data_we_o = 1'b0;
					end
				endcase
			end
			cv32e40p_pkg_OPCODE_LOAD: begin
				data_req = 1'b1;
				regfile_mem_we = 1'b1;
				rega_used_o = 1'b1;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
				data_sign_extension_o = {1'b0, ~instr_rdata_i[14]};
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000, 3'b100: data_type_o = 2'b10;
					3'b001, 3'b101: data_type_o = 2'b01;
					3'b010: data_type_o = 2'b00;
					default: illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_AMO:
				if (A_EXTENSION) begin : decode_amo
					if (instr_rdata_i[14:12] == 3'b010) begin
						data_req = 1'b1;
						data_type_o = 2'b00;
						rega_used_o = 1'b1;
						regb_used_o = 1'b1;
						regfile_mem_we = 1'b1;
						prepost_useincr_o = 1'b0;
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
						data_sign_extension_o = 1'b1;
						atop_o = {1'b1, instr_rdata_i[31:27]};
						(* full_case, parallel_case *)
						case (instr_rdata_i[31:27])
							cv32e40p_pkg_AMO_LR: data_we_o = 1'b0;
							cv32e40p_pkg_AMO_SC, cv32e40p_pkg_AMO_SWAP, cv32e40p_pkg_AMO_ADD, cv32e40p_pkg_AMO_XOR, cv32e40p_pkg_AMO_AND, cv32e40p_pkg_AMO_OR, cv32e40p_pkg_AMO_MIN, cv32e40p_pkg_AMO_MAX, cv32e40p_pkg_AMO_MINU, cv32e40p_pkg_AMO_MAXU: begin
								data_we_o = 1'b1;
								alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							end
							default: illegal_insn_o = 1'b1;
						endcase
					end
					else
						illegal_insn_o = 1'b1;
				end
				else begin : no_decode_amo
					illegal_insn_o = 1'b1;
				end
			cv32e40p_pkg_OPCODE_LUI: begin
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_IMM;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_a_mux_sel_o = cv32e40p_pkg_IMMA_ZERO;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_U;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_AUIPC: begin
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_U;
				alu_operator_o = sv2v_cast_C07C4(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_OPIMM: begin
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
				regfile_alu_we = 1'b1;
				rega_used_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: alu_operator_o = sv2v_cast_C07C4(7'b0011000);
					3'b010: alu_operator_o = sv2v_cast_C07C4(7'b0000010);
					3'b011: alu_operator_o = sv2v_cast_C07C4(7'b0000011);
					3'b100: alu_operator_o = sv2v_cast_C07C4(7'b0101111);
					3'b110: alu_operator_o = sv2v_cast_C07C4(7'b0101110);
					3'b111: alu_operator_o = sv2v_cast_C07C4(7'b0010101);
					3'b001: begin
						alu_operator_o = sv2v_cast_C07C4(7'b0100111);
						if (instr_rdata_i[31:25] != 7'b0000000)
							illegal_insn_o = 1'b1;
					end
					3'b101:
						if (instr_rdata_i[31:25] == 7'b0000000)
							alu_operator_o = sv2v_cast_C07C4(7'b0100101);
						else if (instr_rdata_i[31:25] == 7'b0100000)
							alu_operator_o = sv2v_cast_C07C4(7'b0100100);
						else
							illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_OP:
				if (instr_rdata_i[31:30] == 2'b11)
					illegal_insn_o = 1'b1;
				else if (instr_rdata_i[31:30] == 2'b10) begin
					if (instr_rdata_i[29:25] == 5'b00000)
						illegal_insn_o = 1'b1;
					else if ((FPU == 1) && 1'd0) begin
						alu_en = 1'b0;
						apu_en = 1'b1;
						rega_used_o = 1'b1;
						regb_used_o = 1'b1;
						if (ZFINX == 0) begin
							reg_fp_a_o = 1'b1;
							reg_fp_b_o = 1'b1;
							reg_fp_d_o = 1'b1;
						end
						else begin
							reg_fp_a_o = 1'b0;
							reg_fp_b_o = 1'b0;
							reg_fp_d_o = 1'b0;
						end
						fpu_vec_op = 1'b1;
						scalar_replication_o = instr_rdata_i[14];
						check_fprm = 1'b1;
						fp_rnd_mode_o = frm_i;
						(* full_case, parallel_case *)
						case (instr_rdata_i[13:12])
							2'b00: begin
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE32;
							end
							2'b01: begin
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
							end
							2'b10: begin
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d2);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
							end
							2'b11: begin
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d3);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
							end
						endcase
						fpu_src_fmt_o = fpu_dst_fmt_o;
						(* full_case, parallel_case *)
						if (instr_rdata_i[29:25] == 5'b00001) begin
							fpu_op = sv2v_cast_A1364(2);
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							scalar_replication_o = 1'b0;
							scalar_replication_c_o = instr_rdata_i[14];
						end
						else if (instr_rdata_i[29:25] == 5'b00010) begin
							fpu_op = sv2v_cast_A1364(2);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							scalar_replication_o = 1'b0;
							scalar_replication_c_o = instr_rdata_i[14];
						end
						else if (instr_rdata_i[29:25] == 5'b00011) begin
							fpu_op = sv2v_cast_A1364(3);
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b00100) begin
							fpu_op = sv2v_cast_A1364(4);
							fp_op_group = 2'd1;
						end
						else if (instr_rdata_i[29:25] == 5'b00101) begin
							fpu_op = sv2v_cast_A1364(7);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b00110) begin
							fpu_op = sv2v_cast_A1364(7);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b00111) begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_A1364(5);
							fp_op_group = 2'd1;
							if ((instr_rdata_i[24:20] != 5'b00000) || instr_rdata_i[14])
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[29:25] == 5'b01000) begin
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_A1364(0);
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b01001) begin
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_A1364(0);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b01100) begin
							regb_used_o = 1'b0;
							scalar_replication_o = 1'b0;
							(* full_case, parallel_case *)
							if (instr_rdata_i[24:20] == 5'b00000) begin
								alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
								fpu_op = sv2v_cast_A1364(6);
								fp_rnd_mode_o = 3'b011;
								fp_op_group = 2'd2;
								check_fprm = 1'b0;
								if (instr_rdata_i[14]) begin
									reg_fp_a_o = 1'b0;
									fpu_op_mod = 1'b0;
								end
								else begin
									reg_fp_d_o = 1'b0;
									fpu_op_mod = 1'b1;
								end
							end
							else if (instr_rdata_i[24:20] == 5'b00001) begin
								reg_fp_d_o = 1'b0;
								fpu_op = sv2v_cast_A1364(9);
								fp_rnd_mode_o = 3'b000;
								fp_op_group = 2'd2;
								check_fprm = 1'b0;
								if (instr_rdata_i[14])
									illegal_insn_o = 1'b1;
							end
							else if ((instr_rdata_i[24:20] | 5'b00001) == 5'b00011) begin
								fp_op_group = 2'd3;
								fpu_op_mod = instr_rdata_i[14];
								(* full_case, parallel_case *)
								case (instr_rdata_i[13:12])
									2'b00: fpu_int_fmt_o = sv2v_cast_1BCDC(2);
									2'b01, 2'b10: fpu_int_fmt_o = sv2v_cast_1BCDC(1);
									2'b11: fpu_int_fmt_o = sv2v_cast_1BCDC(0);
								endcase
								if (instr_rdata_i[20]) begin
									reg_fp_a_o = 1'b0;
									fpu_op = sv2v_cast_A1364(12);
								end
								else begin
									reg_fp_d_o = 1'b0;
									fpu_op = sv2v_cast_A1364(11);
								end
							end
							else if ((instr_rdata_i[24:20] | 5'b00011) == 5'b00111) begin
								fpu_op = sv2v_cast_A1364(10);
								fp_op_group = 2'd3;
								(* full_case, parallel_case *)
								case (instr_rdata_i[21:20])
									2'b00: begin
										fpu_src_fmt_o = sv2v_cast_9D6B6('d0);
										if (~cv32e40p_pkg_C_RVF)
											illegal_insn_o = 1'b1;
									end
									2'b01: begin
										fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
										if (~cv32e40p_pkg_C_XF16ALT)
											illegal_insn_o = 1'b1;
									end
									2'b10: begin
										fpu_src_fmt_o = sv2v_cast_9D6B6('d2);
										if (~cv32e40p_pkg_C_XF16)
											illegal_insn_o = 1'b1;
									end
									2'b11: begin
										fpu_src_fmt_o = sv2v_cast_9D6B6('d3);
										if (~cv32e40p_pkg_C_XF8)
											illegal_insn_o = 1'b1;
									end
								endcase
								if (instr_rdata_i[14])
									illegal_insn_o = 1'b1;
							end
							else
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[29:25] == 5'b01101) begin
							fpu_op = sv2v_cast_A1364(6);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b01110) begin
							fpu_op = sv2v_cast_A1364(6);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b01111) begin
							fpu_op = sv2v_cast_A1364(6);
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10000) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10001) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10010) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10011) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10100) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10101) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if ((instr_rdata_i[29:25] | 5'b00011) == 5'b11011) begin
							fpu_op_mod = instr_rdata_i[14];
							fp_op_group = 2'd3;
							scalar_replication_o = 1'b0;
							if (instr_rdata_i[25])
								fpu_op = sv2v_cast_A1364(14);
							else
								fpu_op = sv2v_cast_A1364(13);
							if (instr_rdata_i[26]) begin
								fpu_src_fmt_o = sv2v_cast_9D6B6('d1);
								if (~cv32e40p_pkg_C_RVD)
									illegal_insn_o = 1'b1;
							end
							else begin
								fpu_src_fmt_o = sv2v_cast_9D6B6('d0);
								if (~cv32e40p_pkg_C_RVF)
									illegal_insn_o = 1'b1;
							end
							if (fpu_op == sv2v_cast_A1364(14)) begin
								if (~cv32e40p_pkg_C_XF8 || ~cv32e40p_pkg_C_RVD)
									illegal_insn_o = 1'b1;
							end
							else if (instr_rdata_i[14]) begin
								if (fpu_dst_fmt_o == sv2v_cast_9D6B6('d0))
									illegal_insn_o = 1'b1;
								if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o != sv2v_cast_9D6B6('d3)))
									illegal_insn_o = 1'b1;
							end
						end
						else
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_RVF || ~cv32e40p_pkg_C_RVD) && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d0)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF16 || ~cv32e40p_pkg_C_RVF) && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d2)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF16ALT || ~cv32e40p_pkg_C_RVF) && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d4)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF8 || (~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT)) && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d3)))
							illegal_insn_o = 1'b1;
						if (check_fprm) begin
							(* full_case, parallel_case *)
							if ((3'b000 <= frm_i) && (3'b100 >= frm_i))
								;
							else
								illegal_insn_o = 1'b1;
						end
						case (fp_op_group)
							2'd0:
								(* full_case, parallel_case *)
								case (fpu_dst_fmt_o)
									sv2v_cast_9D6B6('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
									sv2v_cast_9D6B6('d2): apu_lat_o = 1;
									sv2v_cast_9D6B6('d4): apu_lat_o = 1;
									sv2v_cast_9D6B6('d3): apu_lat_o = 1;
									default:
										;
								endcase
							2'd1: apu_lat_o = 2'h3;
							2'd2: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
							2'd3: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						endcase
						apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
					end
					else
						illegal_insn_o = 1'b1;
				end
				else begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					if (~instr_rdata_i[28])
						regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case ({instr_rdata_i[30:25], instr_rdata_i[14:12]})
						9'b000000000: alu_operator_o = sv2v_cast_C07C4(7'b0011000);
						9'b100000000: alu_operator_o = sv2v_cast_C07C4(7'b0011001);
						9'b000000010: alu_operator_o = sv2v_cast_C07C4(7'b0000010);
						9'b000000011: alu_operator_o = sv2v_cast_C07C4(7'b0000011);
						9'b000000100: alu_operator_o = sv2v_cast_C07C4(7'b0101111);
						9'b000000110: alu_operator_o = sv2v_cast_C07C4(7'b0101110);
						9'b000000111: alu_operator_o = sv2v_cast_C07C4(7'b0010101);
						9'b000000001: alu_operator_o = sv2v_cast_C07C4(7'b0100111);
						9'b000000101: alu_operator_o = sv2v_cast_C07C4(7'b0100101);
						9'b100000101: alu_operator_o = sv2v_cast_C07C4(7'b0100100);
						9'b000001000: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							mult_operator_o = sv2v_cast_9F558(3'b000);
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
						end
						9'b000001001: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b11;
							mult_operator_o = sv2v_cast_9F558(3'b110);
						end
						9'b000001010: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b01;
							mult_operator_o = sv2v_cast_9F558(3'b110);
						end
						9'b000001011: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b00;
							mult_operator_o = sv2v_cast_9F558(3'b110);
						end
						9'b000001100: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_C07C4(7'b0110001);
						end
						9'b000001101: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_C07C4(7'b0110000);
						end
						9'b000001110: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_C07C4(7'b0110011);
						end
						9'b000001111: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_C07C4(7'b0110010);
						end
						default: illegal_insn_o = 1'b1;
					endcase
				end
			cv32e40p_pkg_OPCODE_OP_FP:
				if ((FPU == 1) && ((ZFINX == 1) || (fs_off_i == 1'b0))) begin
					alu_en = 1'b0;
					apu_en = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					if (ZFINX == 0) begin
						reg_fp_a_o = 1'b1;
						reg_fp_b_o = 1'b1;
						reg_fp_d_o = 1'b1;
					end
					else begin
						reg_fp_a_o = 1'b0;
						reg_fp_b_o = 1'b0;
						reg_fp_d_o = 1'b0;
					end
					check_fprm = 1'b1;
					fp_rnd_mode_o = instr_rdata_i[14:12];
					(* full_case, parallel_case *)
					case (instr_rdata_i[26:25])
						2'b00: fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
						2'b01: fpu_dst_fmt_o = sv2v_cast_9D6B6('d1);
						2'b10:
							if (instr_rdata_i[14:12] == 3'b101)
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
							else
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d2);
						2'b11: fpu_dst_fmt_o = sv2v_cast_9D6B6('d3);
					endcase
					fpu_src_fmt_o = fpu_dst_fmt_o;
					(* full_case, parallel_case *)
					case (instr_rdata_i[31:27])
						5'b00000: begin
							fpu_op = sv2v_cast_A1364(2);
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
						end
						5'b00001: begin
							fpu_op = sv2v_cast_A1364(2);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
						end
						5'b00010: begin
							fpu_op = sv2v_cast_A1364(3);
							fp_op_group = 2'd0;
						end
						5'b00011: begin
							fpu_op = sv2v_cast_A1364(4);
							fp_op_group = 2'd1;
						end
						5'b01011: begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_A1364(5);
							fp_op_group = 2'd1;
							if (instr_rdata_i[24:20] != 5'b00000)
								illegal_insn_o = 1'b1;
						end
						5'b00100: begin
							fpu_op = sv2v_cast_A1364(6);
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b110 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b00101: begin
							fpu_op = sv2v_cast_A1364(7);
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b001 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b101 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b001 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b01000: begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_A1364(10);
							fp_op_group = 2'd3;
							if (instr_rdata_i[24:23])
								illegal_insn_o = 1'b1;
							(* full_case, parallel_case *)
							case (instr_rdata_i[22:20])
								3'b000: begin
									illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_9D6B6('d0);
								end
								3'b001: begin
									if (~cv32e40p_pkg_C_RVD)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_9D6B6('d1);
								end
								3'b010: begin
									if (~cv32e40p_pkg_C_XF16)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_9D6B6('d2);
								end
								3'b110: begin
									if (~cv32e40p_pkg_C_XF16ALT)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
								3'b011: begin
									if (~cv32e40p_pkg_C_XF8)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_9D6B6('d3);
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						5'b01001: begin
							if ((~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT) && ~cv32e40p_pkg_C_XF8)
								illegal_insn_o = 1;
							fpu_op = sv2v_cast_A1364(3);
							fp_op_group = 2'd0;
							fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
						end
						5'b01010: begin
							if ((~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT) && ~cv32e40p_pkg_C_XF8)
								illegal_insn_o = 1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_A1364(0);
							fp_op_group = 2'd0;
							fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
						end
						5'b10100: begin
							fpu_op = sv2v_cast_A1364(8);
							fp_op_group = 2'd2;
							reg_fp_d_o = 1'b0;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b110 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b11000: begin
							regb_used_o = 1'b0;
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_A1364(11);
							fp_op_group = 2'd3;
							fpu_op_mod = instr_rdata_i[20];
							(* full_case, parallel_case *)
							case (instr_rdata_i[26:25])
								2'b00:
									if (~cv32e40p_pkg_C_RVF)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_9D6B6('d0);
								2'b01:
									if (~cv32e40p_pkg_C_RVD)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_9D6B6('d1);
								2'b10:
									if (instr_rdata_i[14:12] == 3'b101) begin
										if (~cv32e40p_pkg_C_XF16ALT)
											illegal_insn_o = 1;
										else
											fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
									end
									else if (~cv32e40p_pkg_C_XF16)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_9D6B6('d2);
								2'b11:
									if (~cv32e40p_pkg_C_XF8)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_9D6B6('d3);
							endcase
							if (instr_rdata_i[24:21])
								illegal_insn_o = 1'b1;
						end
						5'b11010: begin
							regb_used_o = 1'b0;
							reg_fp_a_o = 1'b0;
							fpu_op = sv2v_cast_A1364(12);
							fp_op_group = 2'd3;
							fpu_op_mod = instr_rdata_i[20];
							if (instr_rdata_i[24:21])
								illegal_insn_o = 1'b1;
						end
						5'b11100: begin
							regb_used_o = 1'b0;
							reg_fp_d_o = 1'b0;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (((ZFINX == 0) && (instr_rdata_i[14:12] == 3'b000)) || 1'd0) begin
								alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
								fpu_op = sv2v_cast_A1364(6);
								fpu_op_mod = 1'b1;
								fp_rnd_mode_o = 3'b011;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
							end
							else if ((instr_rdata_i[14:12] == 3'b001) || 1'd0) begin
								fpu_op = sv2v_cast_A1364(9);
								fp_rnd_mode_o = 3'b000;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
							end
							else
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[24:20])
								illegal_insn_o = 1'b1;
						end
						5'b11110: begin
							regb_used_o = 1'b0;
							reg_fp_a_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							fpu_op = sv2v_cast_A1364(6);
							fpu_op_mod = 1'b0;
							fp_op_group = 2'd2;
							fp_rnd_mode_o = 3'b011;
							check_fprm = 1'b0;
							if (((ZFINX == 0) && (instr_rdata_i[14:12] == 3'b000)) || 1'd0) begin
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
									fpu_src_fmt_o = sv2v_cast_9D6B6('d4);
								end
							end
							else
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[24:20] != 5'b00000)
								illegal_insn_o = 1'b1;
						end
						default: illegal_insn_o = 1'b1;
					endcase
					if (~cv32e40p_pkg_C_RVF && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d0)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d1)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16 && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d2)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16ALT && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d4)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF8 && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d3)))
						illegal_insn_o = 1'b1;
					if (check_fprm) begin
						(* full_case, parallel_case *)
						if (|{instr_rdata_i[14:12] == 3'b000, instr_rdata_i[14:12] == 3'b001, instr_rdata_i[14:12] == 3'b010, instr_rdata_i[14:12] == 3'b011, instr_rdata_i[14:12] == 3'b100})
							;
						else if (instr_rdata_i[14:12] == 3'b101) begin
							if (~cv32e40p_pkg_C_XF16ALT || (fpu_dst_fmt_o != sv2v_cast_9D6B6('d4)))
								illegal_insn_o = 1'b1;
							(* full_case, parallel_case *)
							if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
								fp_rnd_mode_o = frm_i;
							else
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[14:12] == 3'b111) begin
							(* full_case, parallel_case *)
							if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
								fp_rnd_mode_o = frm_i;
							else
								illegal_insn_o = 1'b1;
						end
						else
							illegal_insn_o = 1'b1;
					end
					case (fp_op_group)
						2'd0:
							(* full_case, parallel_case *)
							case (fpu_dst_fmt_o)
								sv2v_cast_9D6B6('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
								sv2v_cast_9D6B6('d1): apu_lat_o = 1;
								sv2v_cast_9D6B6('d2): apu_lat_o = 1;
								sv2v_cast_9D6B6('d4): apu_lat_o = 1;
								sv2v_cast_9D6B6('d3): apu_lat_o = 1;
								default:
									;
							endcase
						2'd1: apu_lat_o = 2'h3;
						2'd2: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						2'd3: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						default:
							;
					endcase
					apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_OP_FMADD, cv32e40p_pkg_OPCODE_OP_FMSUB, cv32e40p_pkg_OPCODE_OP_FNMSUB, cv32e40p_pkg_OPCODE_OP_FNMADD:
				if ((FPU == 1) && ((ZFINX == 1) || (fs_off_i == 1'b0))) begin
					alu_en = 1'b0;
					apu_en = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					regc_used_o = 1'b1;
					regc_mux_o = cv32e40p_pkg_REGC_S4;
					if (ZFINX == 0) begin
						reg_fp_a_o = 1'b1;
						reg_fp_b_o = 1'b1;
						reg_fp_c_o = 1'b1;
						reg_fp_d_o = 1'b1;
					end
					else begin
						reg_fp_a_o = 1'b0;
						reg_fp_b_o = 1'b0;
						reg_fp_c_o = 1'b0;
						reg_fp_d_o = 1'b0;
					end
					fp_rnd_mode_o = instr_rdata_i[14:12];
					(* full_case, parallel_case *)
					case (instr_rdata_i[26:25])
						2'b00: fpu_dst_fmt_o = sv2v_cast_9D6B6('d0);
						2'b01: fpu_dst_fmt_o = sv2v_cast_9D6B6('d1);
						2'b10:
							if (instr_rdata_i[14:12] == 3'b101)
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d4);
							else
								fpu_dst_fmt_o = sv2v_cast_9D6B6('d2);
						2'b11: fpu_dst_fmt_o = sv2v_cast_9D6B6('d3);
					endcase
					fpu_src_fmt_o = fpu_dst_fmt_o;
					(* full_case, parallel_case *)
					case (instr_rdata_i[6:0])
						cv32e40p_pkg_OPCODE_OP_FMADD: fpu_op = sv2v_cast_A1364(0);
						cv32e40p_pkg_OPCODE_OP_FMSUB: begin
							fpu_op = sv2v_cast_A1364(0);
							fpu_op_mod = 1'b1;
						end
						cv32e40p_pkg_OPCODE_OP_FNMSUB: fpu_op = sv2v_cast_A1364(1);
						cv32e40p_pkg_OPCODE_OP_FNMADD: begin
							fpu_op = sv2v_cast_A1364(1);
							fpu_op_mod = 1'b1;
						end
						default:
							;
					endcase
					if (~cv32e40p_pkg_C_RVF && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d0)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d1)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16 && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d2)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16ALT && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d4)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF8 && (fpu_dst_fmt_o == sv2v_cast_9D6B6('d3)))
						illegal_insn_o = 1'b1;
					(* full_case, parallel_case *)
					if (|{instr_rdata_i[14:12] == 3'b000, instr_rdata_i[14:12] == 3'b001, instr_rdata_i[14:12] == 3'b010, instr_rdata_i[14:12] == 3'b011, instr_rdata_i[14:12] == 3'b100})
						;
					else if (instr_rdata_i[14:12] == 3'b101) begin
						if (~cv32e40p_pkg_C_XF16ALT || (fpu_dst_fmt_o != sv2v_cast_9D6B6('d4)))
							illegal_insn_o = 1'b1;
						(* full_case, parallel_case *)
						if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
							fp_rnd_mode_o = frm_i;
						else
							illegal_insn_o = 1'b1;
					end
					else if (instr_rdata_i[14:12] == 3'b111) begin
						(* full_case, parallel_case *)
						if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
							fp_rnd_mode_o = frm_i;
						else
							illegal_insn_o = 1'b1;
					end
					else
						illegal_insn_o = 1'b1;
					(* full_case, parallel_case *)
					case (fpu_dst_fmt_o)
						sv2v_cast_9D6B6('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
						sv2v_cast_9D6B6('d1): apu_lat_o = 1;
						sv2v_cast_9D6B6('d2): apu_lat_o = 1;
						sv2v_cast_9D6B6('d4): apu_lat_o = 1;
						sv2v_cast_9D6B6('d3): apu_lat_o = 1;
						default:
							;
					endcase
					apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_STORE_FP:
				if (((FPU == 1) && (ZFINX == 0)) && (fs_off_i == 1'b0)) begin
					data_req = 1'b1;
					data_we_o = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					alu_operator_o = sv2v_cast_C07C4(7'b0011000);
					reg_fp_b_o = 1'b1;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000:
							if (cv32e40p_pkg_C_XF8)
								data_type_o = 2'b10;
							else
								illegal_insn_o = 1'b1;
						3'b001:
							if (cv32e40p_pkg_C_XF16 | cv32e40p_pkg_C_XF16ALT)
								data_type_o = 2'b01;
							else
								illegal_insn_o = 1'b1;
						3'b010:
							if (cv32e40p_pkg_C_RVF)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						3'b011:
							if (cv32e40p_pkg_C_RVD)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						default: illegal_insn_o = 1'b1;
					endcase
					if (illegal_insn_o) begin
						data_req = 1'b0;
						data_we_o = 1'b0;
					end
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_LOAD_FP:
				if (((FPU == 1) && (ZFINX == 0)) && (fs_off_i == 1'b0)) begin
					data_req = 1'b1;
					regfile_mem_we = 1'b1;
					reg_fp_d_o = 1'b1;
					rega_used_o = 1'b1;
					alu_operator_o = sv2v_cast_C07C4(7'b0011000);
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					data_sign_extension_o = 2'b10;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000:
							if (cv32e40p_pkg_C_XF8)
								data_type_o = 2'b10;
							else
								illegal_insn_o = 1'b1;
						3'b001:
							if (cv32e40p_pkg_C_XF16 | cv32e40p_pkg_C_XF16ALT)
								data_type_o = 2'b01;
							else
								illegal_insn_o = 1'b1;
						3'b010:
							if (cv32e40p_pkg_C_RVF)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						3'b011:
							if (cv32e40p_pkg_C_RVD)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						default: illegal_insn_o = 1'b1;
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_0:
				if (COREV_PULP && (instr_rdata_i[14:13] != 2'b11)) begin
					data_req = 1'b1;
					regfile_mem_we = 1'b1;
					rega_used_o = 1'b1;
					alu_operator_o = sv2v_cast_C07C4(7'b0011000);
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					if (instr_rdata_i[13:12] != 2'b11) begin
						prepost_useincr_o = 1'b0;
						regfile_alu_waddr_sel_o = 1'b0;
						regfile_alu_we = 1'b1;
					end
					data_sign_extension_o = {1'b0, ~instr_rdata_i[14]};
					(* full_case, parallel_case *)
					case (instr_rdata_i[13:12])
						2'b00: data_type_o = 2'b10;
						2'b01: data_type_o = 2'b01;
						default: data_type_o = 2'b00;
					endcase
					if (instr_rdata_i[13:12] == 2'b11) begin
						if (COREV_CLUSTER)
							data_load_event_o = 1'b1;
						else
							illegal_insn_o = 1'b1;
					end
				end
				else if (COREV_PULP) begin
					ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_COND;
					ctrl_transfer_insn = cv32e40p_pkg_BRANCH_COND;
					alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_JT;
					rega_used_o = 1'b1;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_BI;
					if (instr_rdata_i[12] == 1'b0)
						alu_operator_o = sv2v_cast_C07C4(7'b0001100);
					else
						alu_operator_o = sv2v_cast_C07C4(7'b0001101);
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_1:
				if (COREV_PULP)
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000, 3'b001, 3'b010: begin
							data_req = 1'b1;
							data_we_o = 1'b1;
							rega_used_o = 1'b1;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_C07C4(7'b0011000);
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
							prepost_useincr_o = 1'b0;
							regfile_alu_waddr_sel_o = 1'b0;
							regfile_alu_we = 1'b1;
							(* full_case, parallel_case *)
							case (instr_rdata_i[13:12])
								2'b00: data_type_o = 2'b10;
								2'b01: data_type_o = 2'b01;
								default: data_type_o = 2'b00;
							endcase
						end
						3'b011:
							(* full_case, parallel_case *)
							case (instr_rdata_i[31:25])
								7'b0000000, 7'b0000001, 7'b0000010, 7'b0000011, 7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111, 7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011, 7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: begin
									data_req = 1'b1;
									regfile_mem_we = 1'b1;
									rega_used_o = 1'b1;
									alu_operator_o = sv2v_cast_C07C4(7'b0011000);
									regb_used_o = 1'b1;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
									if (instr_rdata_i[27] == 1'b0) begin
										prepost_useincr_o = 1'b0;
										regfile_alu_waddr_sel_o = 1'b0;
										regfile_alu_we = 1'b1;
									end
									data_sign_extension_o = {1'b0, ~instr_rdata_i[28]};
									(* full_case, parallel_case *)
									case ({instr_rdata_i[28], instr_rdata_i[26:25]})
										3'b000: data_type_o = 2'b10;
										3'b001: data_type_o = 2'b01;
										3'b010: data_type_o = 2'b00;
										3'b100: data_type_o = 2'b10;
										3'b101: data_type_o = 2'b01;
										default: begin
											illegal_insn_o = 1'b1;
											data_req = 1'b0;
											regfile_mem_we = 1'b0;
											regfile_alu_we = 1'b0;
										end
									endcase
								end
								7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011, 7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: begin
									data_req = 1'b1;
									data_we_o = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									alu_operator_o = sv2v_cast_C07C4(7'b0011000);
									alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
									regc_used_o = 1'b1;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGC_OR_FWD;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									if (instr_rdata_i[27] == 1'b0) begin
										prepost_useincr_o = 1'b0;
										regfile_alu_waddr_sel_o = 1'b0;
										regfile_alu_we = 1'b1;
									end
									(* full_case, parallel_case *)
									case (instr_rdata_i[26:25])
										2'b00: data_type_o = 2'b10;
										2'b01: data_type_o = 2'b01;
										2'b10: data_type_o = 2'b00;
										default: begin
											illegal_insn_o = 1'b1;
											data_req = 1'b0;
											data_we_o = 1'b0;
											data_type_o = 2'b00;
										end
									endcase
								end
								7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011, 7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									bmask_a_mux_o = cv32e40p_pkg_BMASK_A_S3;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S2;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
									alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_REG;
									(* full_case, parallel_case *)
									case (instr_rdata_i[27:25])
										3'b000: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0101000);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
										end
										3'b001: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0101001);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
										end
										3'b010: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0101010);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											regc_used_o = 1'b1;
											regc_mux_o = cv32e40p_pkg_REGC_RD;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										3'b100: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0101011);
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										3'b101: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0101100);
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										default: illegal_insn_o = 1'b1;
									endcase
								end
								7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011, 7'b0100100, 7'b0100101, 7'b0100110, 7'b0100111, 7'b0101000, 7'b0101001, 7'b0101010, 7'b0101011, 7'b0101100, 7'b0101101, 7'b0101110, 7'b0101111, 7'b0110000, 7'b0110001, 7'b0110010, 7'b0110011, 7'b0110100, 7'b0110101, 7'b0110110, 7'b0110111, 7'b0111000, 7'b0111001, 7'b0111010, 7'b0111011, 7'b0111100, 7'b0111101, 7'b0111110, 7'b0111111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									(* full_case, parallel_case *)
									case (instr_rdata_i[29:25])
										5'b00000: alu_operator_o = sv2v_cast_C07C4(7'b0100110);
										5'b00001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0110110);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00010: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0110111);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00011: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0110101);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00100: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0110100);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b01000: begin
											alu_operator_o = sv2v_cast_C07C4(7'b0010100);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b01001: alu_operator_o = sv2v_cast_C07C4(7'b0000110);
										5'b01010: alu_operator_o = sv2v_cast_C07C4(7'b0000111);
										5'b01011: alu_operator_o = sv2v_cast_C07C4(7'b0010000);
										5'b01100: alu_operator_o = sv2v_cast_C07C4(7'b0010001);
										5'b01101: alu_operator_o = sv2v_cast_C07C4(7'b0010010);
										5'b01110: alu_operator_o = sv2v_cast_C07C4(7'b0010011);
										5'b10000: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0111110);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0111111);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10010: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0111110);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10011: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0111111);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b11000: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0010110);
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_CLIP;
										end
										5'b11001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_C07C4(7'b0010111);
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_CLIP;
										end
										5'b11010: alu_operator_o = sv2v_cast_C07C4(7'b0010110);
										5'b11011: alu_operator_o = sv2v_cast_C07C4(7'b0010111);
										default: illegal_insn_o = 1'b1;
									endcase
								end
								7'b1000000, 7'b1000001, 7'b1000010, 7'b1000011, 7'b1000100, 7'b1000101, 7'b1000110, 7'b1000111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S3;
									alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
									alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGC_OR_FWD;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
									(* full_case, parallel_case *)
									case (instr_rdata_i[27:25])
										3'b001: alu_operator_o = sv2v_cast_C07C4(7'b0011010);
										3'b010: alu_operator_o = sv2v_cast_C07C4(7'b0011100);
										3'b011: alu_operator_o = sv2v_cast_C07C4(7'b0011110);
										3'b100: alu_operator_o = sv2v_cast_C07C4(7'b0011001);
										3'b101: alu_operator_o = sv2v_cast_C07C4(7'b0011011);
										3'b110: alu_operator_o = sv2v_cast_C07C4(7'b0011101);
										3'b111: alu_operator_o = sv2v_cast_C07C4(7'b0011111);
										default: alu_operator_o = sv2v_cast_C07C4(7'b0011000);
									endcase
								end
								7'b1001000, 7'b1001001: begin
									alu_en = 1'b0;
									mult_int_en = 1'b1;
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									if (instr_rdata_i[25] == 1'b0)
										mult_operator_o = sv2v_cast_9F558(3'b000);
									else
										mult_operator_o = sv2v_cast_9F558(3'b001);
								end
								default: illegal_insn_o = 1'b1;
							endcase
						3'b100: begin
							hwlp_target_mux_sel_o = 2'b00;
							(* full_case, parallel_case *)
							case (instr_rdata_i[11:8])
								4'b0000: begin
									hwlp_we[0] = 1'b1;
									hwlp_start_mux_sel_o = 2'b00;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0001: begin
									hwlp_we[0] = 1'b1;
									hwlp_start_mux_sel_o = 2'b10;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0010: begin
									hwlp_we[1] = 1'b1;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0011: begin
									hwlp_we[1] = 1'b1;
									hwlp_target_mux_sel_o = 2'b10;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0100: begin
									hwlp_we[2] = 1'b1;
									hwlp_cnt_mux_sel_o = 1'b0;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0101: begin
									hwlp_we[2] = 1'b1;
									hwlp_cnt_mux_sel_o = 1'b1;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0110: begin
									hwlp_we = 3'b111;
									hwlp_target_mux_sel_o = 2'b01;
									hwlp_start_mux_sel_o = 2'b01;
									hwlp_cnt_mux_sel_o = 1'b0;
								end
								4'b0111: begin
									hwlp_we = 3'b111;
									hwlp_start_mux_sel_o = 2'b01;
									hwlp_cnt_mux_sel_o = 1'b1;
									rega_used_o = 1'b1;
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						default: illegal_insn_o = 1'b1;
					endcase
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_2:
				if (COREV_PULP) begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:13])
						2'b00: begin
							regb_used_o = 1'b0;
							bmask_a_mux_o = cv32e40p_pkg_BMASK_A_S3;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S2;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
							(* full_case, parallel_case *)
							case ({instr_rdata_i[31:30], instr_rdata_i[12]})
								3'b000: begin
									alu_operator_o = sv2v_cast_C07C4(7'b0101000);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
								end
								3'b010: begin
									alu_operator_o = sv2v_cast_C07C4(7'b0101001);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
								end
								3'b100: begin
									alu_operator_o = sv2v_cast_C07C4(7'b0101010);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
								end
								3'b001: alu_operator_o = sv2v_cast_C07C4(7'b0101011);
								3'b011: alu_operator_o = sv2v_cast_C07C4(7'b0101100);
								3'b111: begin
									alu_operator_o = sv2v_cast_C07C4(7'b1001001);
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_IMM;
									if (instr_rdata_i[29:27] != 3'b000)
										illegal_insn_o = 1'b1;
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						2'b01: begin
							bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S3;
							(* full_case, parallel_case *)
							case ({instr_rdata_i[31:30], instr_rdata_i[12]})
								3'b010: alu_operator_o = sv2v_cast_C07C4(7'b0011010);
								3'b100: alu_operator_o = sv2v_cast_C07C4(7'b0011100);
								3'b110: alu_operator_o = sv2v_cast_C07C4(7'b0011110);
								3'b001: alu_operator_o = sv2v_cast_C07C4(7'b0011001);
								3'b011: alu_operator_o = sv2v_cast_C07C4(7'b0011011);
								3'b101: alu_operator_o = sv2v_cast_C07C4(7'b0011101);
								3'b111: alu_operator_o = sv2v_cast_C07C4(7'b0011111);
								default: alu_operator_o = sv2v_cast_C07C4(7'b0011000);
							endcase
						end
						default: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							mult_imm_mux_o = cv32e40p_pkg_MIMM_S3;
							mult_sel_subword_o = instr_rdata_i[30];
							mult_signed_mode_o = {2 {~instr_rdata_i[12]}};
							if (instr_rdata_i[13]) begin
								regc_used_o = 1'b1;
								regc_mux_o = cv32e40p_pkg_REGC_RD;
							end
							else
								regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							if (instr_rdata_i[31])
								mult_operator_o = sv2v_cast_9F558(3'b011);
							else
								mult_operator_o = sv2v_cast_9F558(3'b010);
						end
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_3:
				if (COREV_PULP) begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
					alu_vec_o = 1'b1;
					if (instr_rdata_i[12]) begin
						alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
						mult_operator_o = sv2v_cast_9F558(3'b100);
					end
					else begin
						alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
						mult_operator_o = sv2v_cast_9F558(3'b101);
					end
					if (instr_rdata_i[14]) begin
						scalar_replication_o = 1'b1;
						if (instr_rdata_i[13])
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
						else
							regb_used_o = 1'b1;
					end
					else
						regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr_rdata_i[31:26])
						6'b000000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000010: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000100: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ONE;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000110: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ONE;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001010: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001100: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001110: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010011);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0100101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010010: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0100100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010100: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0100111);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010110: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0101110);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0101111);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011010: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011100: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] != 3'b000) && (instr_rdata_i[14:12] != 3'b001))
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[25:20] != 6'b000000)
								illegal_insn_o = 1'b1;
						end
						6'b100000: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b00;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100010: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b01;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100100: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100110: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b00;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101000: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b01;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101010: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101110: begin
							(* full_case, parallel_case *)
							case (instr_rdata_i[14:13])
								2'b00: alu_operator_o = sv2v_cast_C07C4(7'b0111110);
								2'b01: alu_operator_o = sv2v_cast_C07C4(7'b0111111);
								2'b10: begin
									alu_operator_o = sv2v_cast_C07C4(7'b0101101);
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGC_OR_FWD;
								end
								default: illegal_insn_o = 1'b1;
							endcase
							if (((instr_rdata_i[12] == 1'b0) && (instr_rdata_i[24:20] != 5'b00000)) || ((instr_rdata_i[12] == 1'b1) && (instr_rdata_i[24:21] != 4'b0000)))
								illegal_insn_o = 1'b1;
						end
						6'b110000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0111010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_SHUF;
							regb_used_o = 1'b1;
							scalar_replication_o = 1'b0;
							if ((((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011)) || (instr_rdata_i[14:12] == 3'b100)) || (instr_rdata_i[14:12] == 3'b101))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if ((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:21] != 4'b0000))
								illegal_insn_o = 1'b1;
						end
						6'b110010, 6'b110100, 6'b110110: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0111010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_SHUF;
							regb_used_o = 1'b1;
							scalar_replication_o = 1'b0;
							if (instr_rdata_i[14:12] != 3'b111)
								illegal_insn_o = 1'b1;
						end
						6'b111000: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0111011);
							regb_used_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							scalar_replication_o = 1'b0;
							if ((instr_rdata_i[14:12] != 3'b000) && (instr_rdata_i[14:12] != 3'b001))
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[25] != 1'b0)
								illegal_insn_o = 1'b1;
						end
						6'b111100: begin
							alu_operator_o = (instr_rdata_i[25] ? sv2v_cast_C07C4(7'b0111001) : sv2v_cast_C07C4(7'b0111000));
							regb_used_o = 1'b1;
							if (instr_rdata_i[14:12] != 3'b000)
								illegal_insn_o = 1'b1;
						end
						6'b111110: begin
							alu_operator_o = (instr_rdata_i[25] ? sv2v_cast_C07C4(7'b0111001) : sv2v_cast_C07C4(7'b0111000));
							regb_used_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (instr_rdata_i[14:12] != 3'b001)
								illegal_insn_o = 1'b1;
						end
						6'b000001: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000011: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000101: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000111: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001001: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0000000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001011: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0000100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001101: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001111: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0001011);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010001: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0000001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010011: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0000101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010101: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							is_clpx_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							illegal_insn_o = instr_rdata_i[12];
						end
						6'b010111: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0010100);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							regb_used_o = 1'b0;
							if ((instr_rdata_i[14:12] != 3'b000) || (instr_rdata_i[25:20] != 6'b000000))
								illegal_insn_o = 1'b1;
						end
						6'b011001: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011001);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							is_subrot_o = 1'b1;
							if ((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011011: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011000);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							if (((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[14:12] == 3'b000)) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011101: begin
							alu_operator_o = sv2v_cast_C07C4(7'b0011001);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							if (((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[14:12] == 3'b000)) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						default: illegal_insn_o = 1'b1;
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_FENCE:
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: fencei_insn_o = 1'b1;
					3'b001: fencei_insn_o = 1'b1;
					default: illegal_insn_o = 1'b1;
				endcase
			cv32e40p_pkg_OPCODE_SYSTEM:
				if (instr_rdata_i[14:12] == 3'b000) begin
					if ({instr_rdata_i[19:15], instr_rdata_i[11:7]} == {10 {1'sb0}})
						(* full_case, parallel_case *)
						case (instr_rdata_i[31:20])
							12'h000: ecall_insn_o = 1'b1;
							12'h001: ebrk_insn_o = 1'b1;
							12'h302: begin
								illegal_insn_o = (PULP_SECURE ? current_priv_lvl_i != 2'b11 : 1'b0);
								mret_insn_o = ~illegal_insn_o;
								mret_dec_o = 1'b1;
							end
							12'h002: begin
								illegal_insn_o = (PULP_SECURE ? 1'b0 : 1'b1);
								uret_insn_o = ~illegal_insn_o;
								uret_dec_o = 1'b1;
							end
							12'h7b2: begin
								illegal_insn_o = !debug_mode_i;
								dret_insn_o = debug_mode_i;
								dret_dec_o = 1'b1;
							end
							12'h105: begin
								wfi_o = 1'b1;
								if (debug_wfi_no_sleep_i) begin
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
									alu_operator_o = sv2v_cast_C07C4(7'b0011000);
								end
							end
							default: illegal_insn_o = 1'b1;
						endcase
					else
						illegal_insn_o = 1'b1;
				end
				else begin
					csr_access_o = 1'b1;
					regfile_alu_we = 1'b1;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_a_mux_sel_o = cv32e40p_pkg_IMMA_Z;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					if (instr_rdata_i[14] == 1'b1)
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_IMM;
					else begin
						rega_used_o = 1'b1;
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
					end
					(* full_case, parallel_case *)
					case (instr_rdata_i[13:12])
						2'b01: csr_op = sv2v_cast_EB06E(2'b01);
						2'b10: csr_op = (instr_rdata_i[19:15] == 5'b00000 ? sv2v_cast_EB06E(2'b00) : sv2v_cast_EB06E(2'b10));
						2'b11: csr_op = (instr_rdata_i[19:15] == 5'b00000 ? sv2v_cast_EB06E(2'b00) : sv2v_cast_EB06E(2'b11));
						default: csr_illegal = 1'b1;
					endcase
					if (instr_rdata_i[29:28] > current_priv_lvl_i)
						csr_illegal = 1'b1;
					case (instr_rdata_i[31:20])
						12'h001:
							if ((FPU == 0) || (fs_off_i == 1'b1))
								csr_illegal = 1'b1;
						12'h002, 12'h003:
							if ((FPU == 0) || (fs_off_i == 1'b1))
								csr_illegal = 1'b1;
							else if (csr_op != sv2v_cast_EB06E(2'b00))
								csr_status_o = 1'b1;
						12'hf11, 12'hf12, 12'hf13, 12'hf14:
							if (csr_op != sv2v_cast_EB06E(2'b00))
								csr_illegal = 1'b1;
						12'h300, 12'h341, 12'h305, 12'h342: csr_status_o = 1'b1;
						12'h301, 12'h304, 12'h340, 12'h343, 12'h344:
							;
						12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f, 12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f, 12'h320, 12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_status_o = 1'b1;
						12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f, 12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f:
							if ((csr_op != sv2v_cast_EB06E(2'b00)) || ((PULP_SECURE && (current_priv_lvl_i != 2'b11)) && !mcounteren_i[instr_rdata_i[24:20]]))
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h306:
							if (!PULP_SECURE)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h7b0, 12'h7b1, 12'h7b2, 12'h7b3:
							if (!debug_mode_i)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h7a0, 12'h7a1, 12'h7a2, 12'h7a3, 12'h7a4, 12'h7a8, 12'h7aa:
							if (DEBUG_TRIGGER_EN != 1)
								csr_illegal = 1'b1;
						12'hcc0, 12'hcc1, 12'hcc2, 12'hcc4, 12'hcc5, 12'hcc6:
							if (!COREV_PULP || (csr_op != sv2v_cast_EB06E(2'b00)))
								csr_illegal = 1'b1;
						12'hcd0:
							if (!COREV_PULP || (csr_op != sv2v_cast_EB06E(2'b00)))
								csr_illegal = 1'b1;
						12'hcd1:
							if (!COREV_PULP || (csr_op != sv2v_cast_EB06E(2'b00)))
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'hcd2:
							if ((!COREV_PULP || (FPU && !ZFINX)) || (csr_op != sv2v_cast_EB06E(2'b00)))
								csr_illegal = 1'b1;
						12'h3a0, 12'h3a1, 12'h3a2, 12'h3a3, 12'h3b0, 12'h3b1, 12'h3b2, 12'h3b3, 12'h3b4, 12'h3b5, 12'h3b6, 12'h3b7, 12'h3b8, 12'h3b9, 12'h3ba, 12'h3bb, 12'h3bc, 12'h3bd, 12'h3be, 12'h3bf:
							if (!USE_PMP)
								csr_illegal = 1'b1;
						12'h000, 12'h041, 12'h005, 12'h042:
							if (!PULP_SECURE)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						default: csr_illegal = 1'b1;
					endcase
					illegal_insn_o = csr_illegal;
				end
			default: illegal_insn_o = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn_o = 1'b1;
	end
	assign alu_en_o = (deassert_we_i ? 1'b0 : alu_en);
	assign mult_int_en_o = (deassert_we_i ? 1'b0 : mult_int_en);
	assign mult_dot_en_o = (deassert_we_i ? 1'b0 : mult_dot_en);
	assign apu_en_o = (deassert_we_i ? 1'b0 : apu_en);
	assign regfile_mem_we_o = (deassert_we_i ? 1'b0 : regfile_mem_we);
	assign regfile_alu_we_o = (deassert_we_i ? 1'b0 : regfile_alu_we);
	assign data_req_o = (deassert_we_i ? 1'b0 : data_req);
	assign hwlp_we_o = (deassert_we_i ? 3'b000 : hwlp_we);
	assign csr_op_o = (deassert_we_i ? sv2v_cast_EB06E(2'b00) : csr_op);
	assign ctrl_transfer_insn_in_id_o = (deassert_we_i ? cv32e40p_pkg_BRANCH_NONE : ctrl_transfer_insn);
	assign ctrl_transfer_insn_in_dec_o = ctrl_transfer_insn;
	assign regfile_alu_we_dec_o = regfile_alu_we;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_int_controller_gate (
	clk,
	rst_n,
	irq_i,
	irq_sec_i,
	irq_req_ctrl_o,
	irq_sec_ctrl_o,
	irq_id_ctrl_o,
	irq_wu_ctrl_o,
	mie_bypass_i,
	mip_o,
	m_ie_i,
	u_ie_i,
	current_priv_lvl_i
);
	reg _sv2v_0;
	parameter PULP_SECURE = 0;
	input wire clk;
	input wire rst_n;
	input wire [31:0] irq_i;
	input wire irq_sec_i;
	output wire irq_req_ctrl_o;
	output wire irq_sec_ctrl_o;
	output reg [4:0] irq_id_ctrl_o;
	output wire irq_wu_ctrl_o;
	input wire [31:0] mie_bypass_i;
	output wire [31:0] mip_o;
	input wire m_ie_i;
	input wire u_ie_i;
	input wire [1:0] current_priv_lvl_i;
	wire global_irq_enable;
	wire [31:0] irq_local_qual;
	reg [31:0] irq_q;
	reg irq_sec_q;
	localparam cv32e40p_pkg_IRQ_MASK = 32'hffff0888;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			irq_q <= 1'sb0;
			irq_sec_q <= 1'b0;
		end
		else begin
			irq_q <= irq_i & cv32e40p_pkg_IRQ_MASK;
			irq_sec_q <= irq_sec_i;
		end
	assign mip_o = irq_q;
	assign irq_local_qual = irq_q & mie_bypass_i;
	assign irq_wu_ctrl_o = |(irq_i & mie_bypass_i);
	generate
		if (PULP_SECURE) begin : gen_pulp_secure
			assign global_irq_enable = ((u_ie_i || irq_sec_i) && (current_priv_lvl_i == 2'b00)) || (m_ie_i && (current_priv_lvl_i == 2'b11));
		end
		else begin : gen_no_pulp_secure
			assign global_irq_enable = m_ie_i;
		end
	endgenerate
	assign irq_req_ctrl_o = |irq_local_qual && global_irq_enable;
	localparam [31:0] cv32e40p_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] cv32e40p_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] cv32e40p_pkg_CSR_MTIX_BIT = 7;
	always @(*) begin
		if (_sv2v_0)
			;
		if (irq_local_qual[31])
			irq_id_ctrl_o = 5'd31;
		else if (irq_local_qual[30])
			irq_id_ctrl_o = 5'd30;
		else if (irq_local_qual[29])
			irq_id_ctrl_o = 5'd29;
		else if (irq_local_qual[28])
			irq_id_ctrl_o = 5'd28;
		else if (irq_local_qual[27])
			irq_id_ctrl_o = 5'd27;
		else if (irq_local_qual[26])
			irq_id_ctrl_o = 5'd26;
		else if (irq_local_qual[25])
			irq_id_ctrl_o = 5'd25;
		else if (irq_local_qual[24])
			irq_id_ctrl_o = 5'd24;
		else if (irq_local_qual[23])
			irq_id_ctrl_o = 5'd23;
		else if (irq_local_qual[22])
			irq_id_ctrl_o = 5'd22;
		else if (irq_local_qual[21])
			irq_id_ctrl_o = 5'd21;
		else if (irq_local_qual[20])
			irq_id_ctrl_o = 5'd20;
		else if (irq_local_qual[19])
			irq_id_ctrl_o = 5'd19;
		else if (irq_local_qual[18])
			irq_id_ctrl_o = 5'd18;
		else if (irq_local_qual[17])
			irq_id_ctrl_o = 5'd17;
		else if (irq_local_qual[16])
			irq_id_ctrl_o = 5'd16;
		else if (irq_local_qual[15])
			irq_id_ctrl_o = 5'd15;
		else if (irq_local_qual[14])
			irq_id_ctrl_o = 5'd14;
		else if (irq_local_qual[13])
			irq_id_ctrl_o = 5'd13;
		else if (irq_local_qual[12])
			irq_id_ctrl_o = 5'd12;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MEIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MEIX_BIT;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MSIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MSIX_BIT;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MTIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MTIX_BIT;
		else if (irq_local_qual[10])
			irq_id_ctrl_o = 5'd10;
		else if (irq_local_qual[2])
			irq_id_ctrl_o = 5'd2;
		else if (irq_local_qual[6])
			irq_id_ctrl_o = 5'd6;
		else if (irq_local_qual[9])
			irq_id_ctrl_o = 5'd9;
		else if (irq_local_qual[1])
			irq_id_ctrl_o = 5'd1;
		else if (irq_local_qual[5])
			irq_id_ctrl_o = 5'd5;
		else if (irq_local_qual[8])
			irq_id_ctrl_o = 5'd8;
		else if (irq_local_qual[0])
			irq_id_ctrl_o = 5'd0;
		else if (irq_local_qual[4])
			irq_id_ctrl_o = 5'd4;
		else
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MTIX_BIT;
	end
	assign irq_sec_ctrl_o = irq_sec_q;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_controller_gate (
	clk,
	clk_ungated_i,
	rst_n,
	fetch_enable_i,
	ctrl_busy_o,
	is_decoding_o,
	is_fetch_failed_i,
	deassert_we_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	uret_insn_i,
	dret_insn_i,
	mret_dec_i,
	uret_dec_i,
	dret_dec_i,
	wfi_i,
	ebrk_insn_i,
	fencei_insn_i,
	csr_status_i,
	hwlp_mask_o,
	instr_valid_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	trap_addr_mux_o,
	pc_id_i,
	hwlp_start_addr_i,
	hwlp_end_addr_i,
	hwlp_counter_i,
	hwlp_dec_cnt_o,
	hwlp_jump_o,
	hwlp_targ_addr_o,
	data_req_ex_i,
	data_we_ex_i,
	data_misaligned_i,
	data_load_event_i,
	data_err_i,
	data_err_ack_o,
	mult_multicycle_i,
	apu_en_i,
	apu_read_dep_i,
	apu_read_dep_for_jalr_i,
	apu_write_dep_i,
	apu_stall_o,
	branch_taken_ex_i,
	ctrl_transfer_insn_in_id_i,
	ctrl_transfer_insn_in_dec_i,
	irq_req_ctrl_i,
	irq_sec_ctrl_i,
	irq_id_ctrl_i,
	irq_wu_ctrl_i,
	current_priv_lvl_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	debug_mode_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	debug_p_elw_no_sleep_o,
	debug_wfi_no_sleep_o,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	wake_from_sleep_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_ex_o,
	csr_cause_o,
	csr_irq_sec_o,
	csr_restore_mret_id_o,
	csr_restore_uret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	regfile_we_id_i,
	regfile_alu_waddr_id_i,
	regfile_we_ex_i,
	regfile_waddr_ex_i,
	regfile_we_wb_i,
	regfile_alu_we_fw_i,
	operand_a_fw_mux_sel_o,
	operand_b_fw_mux_sel_o,
	operand_c_fw_mux_sel_o,
	reg_d_ex_is_reg_a_i,
	reg_d_ex_is_reg_b_i,
	reg_d_ex_is_reg_c_i,
	reg_d_wb_is_reg_a_i,
	reg_d_wb_is_reg_b_i,
	reg_d_wb_is_reg_c_i,
	reg_d_alu_is_reg_a_i,
	reg_d_alu_is_reg_b_i,
	reg_d_alu_is_reg_c_i,
	halt_if_o,
	halt_id_o,
	misaligned_stall_o,
	jr_stall_o,
	load_stall_o,
	id_ready_i,
	id_valid_i,
	ex_valid_i,
	wb_ready_i,
	perf_pipeline_stall_o
);
	reg _sv2v_0;
	parameter COREV_CLUSTER = 0;
	parameter COREV_PULP = 0;
	parameter FPU = 0;
	input wire clk;
	input wire clk_ungated_i;
	input wire rst_n;
	input wire fetch_enable_i;
	output reg ctrl_busy_o;
	output reg is_decoding_o;
	input wire is_fetch_failed_i;
	output reg deassert_we_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire uret_insn_i;
	input wire dret_insn_i;
	input wire mret_dec_i;
	input wire uret_dec_i;
	input wire dret_dec_i;
	input wire wfi_i;
	input wire ebrk_insn_i;
	input wire fencei_insn_i;
	input wire csr_status_i;
	output reg hwlp_mask_o;
	input wire instr_valid_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [3:0] pc_mux_o;
	output reg [2:0] exc_pc_mux_o;
	output reg [1:0] trap_addr_mux_o;
	input wire [31:0] pc_id_i;
	input wire [63:0] hwlp_start_addr_i;
	input wire [63:0] hwlp_end_addr_i;
	input wire [63:0] hwlp_counter_i;
	output reg [1:0] hwlp_dec_cnt_o;
	output wire hwlp_jump_o;
	output reg [31:0] hwlp_targ_addr_o;
	input wire data_req_ex_i;
	input wire data_we_ex_i;
	input wire data_misaligned_i;
	input wire data_load_event_i;
	input wire data_err_i;
	output reg data_err_ack_o;
	input wire mult_multicycle_i;
	input wire apu_en_i;
	input wire apu_read_dep_i;
	input wire apu_read_dep_for_jalr_i;
	input wire apu_write_dep_i;
	output wire apu_stall_o;
	input wire branch_taken_ex_i;
	input wire [1:0] ctrl_transfer_insn_in_id_i;
	input wire [1:0] ctrl_transfer_insn_in_dec_i;
	input wire irq_req_ctrl_i;
	input wire irq_sec_ctrl_i;
	input wire [4:0] irq_id_ctrl_i;
	input wire irq_wu_ctrl_i;
	input wire [1:0] current_priv_lvl_i;
	output reg irq_ack_o;
	output reg [4:0] irq_id_o;
	output reg [4:0] exc_cause_o;
	output wire debug_mode_o;
	output reg [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output wire debug_p_elw_no_sleep_o;
	output wire debug_wfi_no_sleep_o;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	output wire wake_from_sleep_o;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg csr_save_ex_o;
	output reg [5:0] csr_cause_o;
	output reg csr_irq_sec_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_uret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	input wire regfile_we_id_i;
	input wire [5:0] regfile_alu_waddr_id_i;
	input wire regfile_we_ex_i;
	input wire [5:0] regfile_waddr_ex_i;
	input wire regfile_we_wb_i;
	input wire regfile_alu_we_fw_i;
	output reg [1:0] operand_a_fw_mux_sel_o;
	output reg [1:0] operand_b_fw_mux_sel_o;
	output reg [1:0] operand_c_fw_mux_sel_o;
	input wire reg_d_ex_is_reg_a_i;
	input wire reg_d_ex_is_reg_b_i;
	input wire reg_d_ex_is_reg_c_i;
	input wire reg_d_wb_is_reg_a_i;
	input wire reg_d_wb_is_reg_b_i;
	input wire reg_d_wb_is_reg_c_i;
	input wire reg_d_alu_is_reg_a_i;
	input wire reg_d_alu_is_reg_b_i;
	input wire reg_d_alu_is_reg_c_i;
	output reg halt_if_o;
	output reg halt_id_o;
	output wire misaligned_stall_o;
	output reg jr_stall_o;
	output reg load_stall_o;
	input wire id_ready_i;
	input wire id_valid_i;
	input wire ex_valid_i;
	input wire wb_ready_i;
	output reg perf_pipeline_stall_o;
	reg [4:0] ctrl_fsm_cs;
	reg [4:0] ctrl_fsm_ns;
	reg [2:0] debug_fsm_cs;
	reg [2:0] debug_fsm_ns;
	reg jump_done;
	reg jump_done_q;
	reg jump_in_dec;
	reg branch_in_id;
	reg data_err_q;
	reg debug_mode_q;
	reg debug_mode_n;
	reg ebrk_force_debug_mode;
	wire is_hwlp_body;
	reg illegal_insn_q;
	reg illegal_insn_n;
	reg debug_req_entry_q;
	reg debug_req_entry_n;
	reg debug_force_wakeup_q;
	reg debug_force_wakeup_n;
	wire hwlp_end0_eq_pc;
	wire hwlp_end1_eq_pc;
	wire hwlp_counter0_gt_1;
	wire hwlp_counter1_gt_1;
	wire hwlp_counter0_eq_1;
	wire hwlp_counter1_eq_1;
	wire hwlp_counter0_eq_0;
	wire hwlp_counter1_eq_0;
	wire hwlp_end0_eq_pc_plus4;
	wire hwlp_end1_eq_pc_plus4;
	wire hwlp_start0_leq_pc;
	wire hwlp_start1_leq_pc;
	wire hwlp_end0_geq_pc;
	wire hwlp_end1_geq_pc;
	reg hwlp_end_4_id_d;
	reg hwlp_end_4_id_q;
	reg debug_req_q;
	wire debug_req_pending;
	wire wfi_active;
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	localparam cv32e40p_pkg_DBG_CAUSE_EBREAK = 3'h1;
	localparam cv32e40p_pkg_DBG_CAUSE_HALTREQ = 3'h3;
	localparam cv32e40p_pkg_DBG_CAUSE_STEP = 3'h4;
	localparam cv32e40p_pkg_DBG_CAUSE_TRIGGER = 3'h2;
	localparam cv32e40p_pkg_EXC_CAUSE_BREAKPOINT = 5'h03;
	localparam cv32e40p_pkg_EXC_CAUSE_ECALL_MMODE = 5'h0b;
	localparam cv32e40p_pkg_EXC_CAUSE_ECALL_UMODE = 5'h08;
	localparam cv32e40p_pkg_EXC_CAUSE_ILLEGAL_INSN = 5'h02;
	localparam cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT = 5'h01;
	localparam cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT = 5'h05;
	localparam cv32e40p_pkg_EXC_CAUSE_STORE_FAULT = 5'h07;
	localparam cv32e40p_pkg_EXC_PC_DBD = 3'b010;
	localparam cv32e40p_pkg_EXC_PC_DBE = 3'b011;
	localparam cv32e40p_pkg_EXC_PC_EXCEPTION = 3'b000;
	localparam cv32e40p_pkg_EXC_PC_IRQ = 3'b001;
	localparam cv32e40p_pkg_PC_BOOT = 4'b0000;
	localparam cv32e40p_pkg_PC_BRANCH = 4'b0011;
	localparam cv32e40p_pkg_PC_DRET = 4'b0111;
	localparam cv32e40p_pkg_PC_EXCEPTION = 4'b0100;
	localparam cv32e40p_pkg_PC_FENCEI = 4'b0001;
	localparam cv32e40p_pkg_PC_HWLOOP = 4'b1000;
	localparam cv32e40p_pkg_PC_JUMP = 4'b0010;
	localparam cv32e40p_pkg_PC_MRET = 4'b0101;
	localparam cv32e40p_pkg_PC_URET = 4'b0110;
	localparam cv32e40p_pkg_TRAP_MACHINE = 2'b00;
	localparam cv32e40p_pkg_TRAP_USER = 2'b01;
	always @(*) begin
		if (_sv2v_0)
			;
		instr_req_o = 1'b1;
		data_err_ack_o = 1'b0;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_save_ex_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_uret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		exc_cause_o = 1'sb0;
		exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
		trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
		csr_cause_o = 1'sb0;
		csr_irq_sec_o = 1'b0;
		pc_mux_o = cv32e40p_pkg_PC_BOOT;
		pc_set_o = 1'b0;
		jump_done = jump_done_q;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		halt_if_o = 1'b0;
		halt_id_o = 1'b0;
		is_decoding_o = 1'b0;
		irq_ack_o = 1'b0;
		irq_id_o = 5'b00000;
		jump_in_dec = (ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) || (ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JAL);
		branch_in_id = ctrl_transfer_insn_in_id_i == cv32e40p_pkg_BRANCH_COND;
		ebrk_force_debug_mode = (debug_ebreakm_i && (current_priv_lvl_i == 2'b11)) || (debug_ebreaku_i && (current_priv_lvl_i == 2'b00));
		debug_csr_save_o = 1'b0;
		debug_cause_o = cv32e40p_pkg_DBG_CAUSE_EBREAK;
		debug_mode_n = debug_mode_q;
		illegal_insn_n = illegal_insn_q;
		debug_req_entry_n = debug_req_entry_q;
		debug_force_wakeup_n = debug_force_wakeup_q;
		perf_pipeline_stall_o = 1'b0;
		hwlp_mask_o = 1'b0;
		hwlp_dec_cnt_o = 1'sb0;
		hwlp_end_4_id_d = 1'b0;
		hwlp_targ_addr_o = ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && !(hwlp_start0_leq_pc && hwlp_end0_geq_pc) ? hwlp_start_addr_i[32+:32] : hwlp_start_addr_i[0+:32]);
		(* full_case, parallel_case *)
		case (ctrl_fsm_cs)
			5'd0: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				if (fetch_enable_i == 1'b1)
					ctrl_fsm_ns = 5'd1;
			end
			5'd1: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_BOOT;
				pc_set_o = 1'b1;
				if (debug_req_pending) begin
					ctrl_fsm_ns = 5'd12;
					debug_force_wakeup_n = 1'b1;
				end
				else
					ctrl_fsm_ns = 5'd4;
			end
			5'd3: begin
				is_decoding_o = 1'b0;
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				ctrl_fsm_ns = 5'd2;
			end
			5'd2: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (wake_from_sleep_o) begin
					if (debug_req_pending) begin
						ctrl_fsm_ns = 5'd12;
						debug_force_wakeup_n = 1'b1;
					end
					else
						ctrl_fsm_ns = 5'd4;
				end
				else
					ctrl_busy_o = 1'b0;
			end
			5'd4: begin
				is_decoding_o = 1'b0;
				ctrl_fsm_ns = 5'd5;
				if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					pc_set_o = 1'b1;
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
					exc_cause_o = irq_id_ctrl_i;
					csr_irq_sec_o = irq_sec_ctrl_i;
					irq_ack_o = 1'b1;
					irq_id_o = irq_id_ctrl_i;
					if (irq_sec_ctrl_i)
						trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					else
						trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
					csr_save_cause_o = 1'b1;
					csr_cause_o = {1'b1, irq_id_ctrl_i};
					csr_save_if_o = 1'b1;
				end
			end
			5'd5:
				if (branch_taken_ex_i) begin
					is_decoding_o = 1'b0;
					pc_mux_o = cv32e40p_pkg_PC_BRANCH;
					pc_set_o = 1'b1;
				end
				else if (data_err_i) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
				end
				else if (is_fetch_failed_i) begin
					is_decoding_o = 1'b0;
					halt_id_o = 1'b1;
					halt_if_o = 1'b1;
					csr_save_if_o = 1'b1;
					csr_save_cause_o = !debug_mode_q;
					csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT};
					ctrl_fsm_ns = 5'd9;
				end
				else if (instr_valid_i) begin : blk_decode_level1
					is_decoding_o = 1'b1;
					illegal_insn_n = 1'b0;
					if ((debug_req_pending || trigger_match_i) & ~debug_mode_q) begin
						is_decoding_o = (COREV_PULP ? 1'b0 : 1'b1);
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						ctrl_fsm_ns = 5'd13;
						debug_req_entry_n = 1'b1;
					end
					else if (irq_req_ctrl_i && ~debug_mode_q) begin
						hwlp_mask_o = (COREV_PULP ? 1'b1 : 1'b0);
						is_decoding_o = 1'b0;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						pc_set_o = 1'b1;
						pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
						exc_cause_o = irq_id_ctrl_i;
						csr_irq_sec_o = irq_sec_ctrl_i;
						irq_ack_o = 1'b1;
						irq_id_o = irq_id_ctrl_i;
						if (irq_sec_ctrl_i)
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
						else
							trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
						csr_save_cause_o = 1'b1;
						csr_cause_o = {1'b1, irq_id_ctrl_i};
						csr_save_id_o = 1'b1;
					end
					else begin
						if (illegal_insn_i) begin
							halt_if_o = 1'b1;
							halt_id_o = 1'b0;
							ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
							illegal_insn_n = 1'b1;
						end
						else
							(* full_case, parallel_case *)
							case (1'b1)
								jump_in_dec: begin
									pc_mux_o = cv32e40p_pkg_PC_JUMP;
									if (~jr_stall_o && ~jump_done_q) begin
										pc_set_o = 1'b1;
										jump_done = 1'b1;
									end
								end
								ebrk_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									if (debug_mode_q)
										ctrl_fsm_ns = 5'd13;
									else if (ebrk_force_debug_mode)
										ctrl_fsm_ns = 5'd13;
									else
										ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								wfi_active: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								ecall_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								fencei_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								(mret_insn_i | uret_insn_i) | dret_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								csr_status_i: begin
									halt_if_o = 1'b1;
									if (~id_ready_i)
										ctrl_fsm_ns = 5'd5;
									else begin
										ctrl_fsm_ns = 5'd8;
										if (hwlp_end0_eq_pc)
											hwlp_dec_cnt_o[0] = 1'b1;
										if (hwlp_end1_eq_pc)
											hwlp_dec_cnt_o[1] = 1'b1;
									end
								end
								data_load_event_i: begin
									ctrl_fsm_ns = (id_ready_i ? 5'd7 : 5'd5);
									halt_if_o = 1'b1;
								end
								default: begin
									if (is_hwlp_body) begin
										ctrl_fsm_ns = (hwlp_end0_eq_pc_plus4 || hwlp_end1_eq_pc_plus4 ? 5'd5 : 5'd15);
										if (hwlp_end0_eq_pc && hwlp_counter0_gt_1) begin
											pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
											if (~jump_done_q) begin
												pc_set_o = 1'b1;
												jump_done = 1'b1;
												hwlp_dec_cnt_o[0] = 1'b1;
											end
										end
										if (hwlp_end1_eq_pc && hwlp_counter1_gt_1) begin
											pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
											if (~jump_done_q) begin
												pc_set_o = 1'b1;
												jump_done = 1'b1;
												hwlp_dec_cnt_o[1] = 1'b1;
											end
										end
									end
									if (hwlp_end0_eq_pc && hwlp_counter0_eq_1)
										hwlp_dec_cnt_o[0] = 1'b1;
									if (hwlp_end1_eq_pc && hwlp_counter1_eq_1)
										hwlp_dec_cnt_o[1] = 1'b1;
								end
							endcase
						if (debug_single_step_i & ~debug_mode_q) begin
							halt_if_o = 1'b1;
							if (id_ready_i)
								(* full_case, parallel_case *)
								case (1'b1)
									illegal_insn_i | ecall_insn_i: ctrl_fsm_ns = 5'd8;
									~ebrk_force_debug_mode & ebrk_insn_i: ctrl_fsm_ns = 5'd8;
									mret_insn_i | uret_insn_i: ctrl_fsm_ns = 5'd8;
									branch_in_id: ctrl_fsm_ns = 5'd14;
									default: ctrl_fsm_ns = 5'd13;
								endcase
						end
					end
				end
				else begin
					is_decoding_o = 1'b0;
					perf_pipeline_stall_o = data_load_event_i;
				end
			5'd15:
				if (COREV_PULP) begin
					if (instr_valid_i) begin
						is_decoding_o = 1'b1;
						if ((debug_req_pending || trigger_match_i) & ~debug_mode_q) begin
							is_decoding_o = (COREV_PULP ? 1'b0 : 1'b1);
							halt_if_o = 1'b1;
							halt_id_o = 1'b1;
							ctrl_fsm_ns = 5'd13;
							debug_req_entry_n = 1'b1;
						end
						else if (irq_req_ctrl_i && ~debug_mode_q) begin
							hwlp_mask_o = (COREV_PULP ? 1'b1 : 1'b0);
							is_decoding_o = 1'b0;
							halt_if_o = 1'b1;
							halt_id_o = 1'b1;
							pc_set_o = 1'b1;
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
							exc_cause_o = irq_id_ctrl_i;
							csr_irq_sec_o = irq_sec_ctrl_i;
							irq_ack_o = 1'b1;
							irq_id_o = irq_id_ctrl_i;
							if (irq_sec_ctrl_i)
								trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							else
								trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
							csr_save_cause_o = 1'b1;
							csr_cause_o = {1'b1, irq_id_ctrl_i};
							csr_save_id_o = 1'b1;
							ctrl_fsm_ns = 5'd5;
						end
						else begin
							if (illegal_insn_i) begin
								halt_if_o = 1'b1;
								halt_id_o = 1'b1;
								ctrl_fsm_ns = 5'd8;
								illegal_insn_n = 1'b1;
							end
							else
								(* full_case, parallel_case *)
								case (1'b1)
									ebrk_insn_i: begin
										halt_if_o = 1'b1;
										halt_id_o = 1'b0;
										if (debug_mode_q)
											ctrl_fsm_ns = 5'd13;
										else if (ebrk_force_debug_mode)
											ctrl_fsm_ns = 5'd13;
										else
											ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd15);
									end
									ecall_insn_i: begin
										halt_if_o = 1'b1;
										halt_id_o = 1'b0;
										ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd15);
									end
									csr_status_i: begin
										halt_if_o = 1'b1;
										if (~id_ready_i)
											ctrl_fsm_ns = 5'd15;
										else begin
											ctrl_fsm_ns = 5'd8;
											if (hwlp_end0_eq_pc)
												hwlp_dec_cnt_o[0] = 1'b1;
											if (hwlp_end1_eq_pc)
												hwlp_dec_cnt_o[1] = 1'b1;
										end
									end
									data_load_event_i: begin
										ctrl_fsm_ns = (id_ready_i ? 5'd7 : 5'd15);
										halt_if_o = 1'b1;
									end
									default: begin
										if (hwlp_end1_eq_pc_plus4) begin
											if (hwlp_counter1_gt_1) begin
												hwlp_end_4_id_d = 1'b1;
												hwlp_targ_addr_o = hwlp_start_addr_i[32+:32];
												ctrl_fsm_ns = 5'd15;
											end
											else
												ctrl_fsm_ns = (is_hwlp_body ? 5'd15 : 5'd5);
										end
										if (hwlp_end0_eq_pc_plus4) begin
											if (hwlp_counter0_gt_1) begin
												hwlp_end_4_id_d = 1'b1;
												hwlp_targ_addr_o = hwlp_start_addr_i[0+:32];
												ctrl_fsm_ns = 5'd15;
											end
											else
												ctrl_fsm_ns = (is_hwlp_body ? 5'd15 : 5'd5);
										end
										hwlp_dec_cnt_o[0] = hwlp_end0_eq_pc && !hwlp_counter0_eq_0;
										hwlp_dec_cnt_o[1] = hwlp_end1_eq_pc && !hwlp_counter1_eq_0;
									end
								endcase
							if (debug_single_step_i & ~debug_mode_q) begin
								halt_if_o = 1'b1;
								if (id_ready_i)
									(* full_case, parallel_case *)
									case (1'b1)
										illegal_insn_i | ecall_insn_i: ctrl_fsm_ns = 5'd8;
										~ebrk_force_debug_mode & ebrk_insn_i: ctrl_fsm_ns = 5'd8;
										mret_insn_i | uret_insn_i: ctrl_fsm_ns = 5'd8;
										branch_in_id: ctrl_fsm_ns = 5'd14;
										default: ctrl_fsm_ns = 5'd13;
									endcase
							end
						end
					end
					else begin
						is_decoding_o = 1'b0;
						perf_pipeline_stall_o = data_load_event_i;
					end
				end
			5'd8: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (data_err_i) begin
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
					illegal_insn_n = 1'b0;
				end
				else if (ex_valid_i) begin
					ctrl_fsm_ns = 5'd9;
					if (illegal_insn_q) begin
						csr_save_id_o = 1'b1;
						csr_save_cause_o = !debug_mode_q;
						csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_ILLEGAL_INSN};
					end
					else
						(* full_case, parallel_case *)
						case (1'b1)
							ebrk_insn_i: begin
								csr_save_id_o = 1'b1;
								csr_save_cause_o = 1'b1;
								csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_BREAKPOINT};
							end
							ecall_insn_i: begin
								csr_save_id_o = 1'b1;
								csr_save_cause_o = !debug_mode_q;
								csr_cause_o = {1'b0, (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_EXC_CAUSE_ECALL_UMODE : cv32e40p_pkg_EXC_CAUSE_ECALL_MMODE)};
							end
							default:
								;
						endcase
				end
			end
			5'd6:
				if (COREV_CLUSTER == 1'b1) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					ctrl_fsm_ns = 5'd5;
					perf_pipeline_stall_o = data_load_event_i;
					if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
						is_decoding_o = 1'b0;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						pc_set_o = 1'b1;
						pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
						exc_cause_o = irq_id_ctrl_i;
						csr_irq_sec_o = irq_sec_ctrl_i;
						irq_ack_o = 1'b1;
						irq_id_o = irq_id_ctrl_i;
						if (irq_sec_ctrl_i)
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
						else
							trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
						csr_save_cause_o = 1'b1;
						csr_cause_o = {1'b1, irq_id_ctrl_i};
						csr_save_id_o = 1'b1;
					end
				end
			5'd7:
				if (COREV_CLUSTER == 1'b1) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					if (id_ready_i)
						ctrl_fsm_ns = ((debug_req_pending || trigger_match_i) & ~debug_mode_q ? 5'd13 : 5'd6);
					else
						ctrl_fsm_ns = 5'd7;
					perf_pipeline_stall_o = data_load_event_i;
				end
			5'd9: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				ctrl_fsm_ns = 5'd5;
				if (data_err_q) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = cv32e40p_pkg_EXC_PC_EXCEPTION;
					exc_cause_o = (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT : cv32e40p_pkg_EXC_CAUSE_STORE_FAULT);
				end
				else if (is_fetch_failed_i) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
					exc_cause_o = cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT;
				end
				else if (illegal_insn_q) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
					illegal_insn_n = 1'b0;
					if (debug_single_step_i && ~debug_mode_q)
						ctrl_fsm_ns = 5'd12;
				end
				else
					(* full_case, parallel_case *)
					case (1'b1)
						ebrk_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							pc_set_o = 1'b1;
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							exc_pc_mux_o = cv32e40p_pkg_EXC_PC_EXCEPTION;
							if (debug_single_step_i && ~debug_mode_q)
								ctrl_fsm_ns = 5'd12;
						end
						ecall_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							pc_set_o = 1'b1;
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
							if (debug_single_step_i && ~debug_mode_q)
								ctrl_fsm_ns = 5'd12;
						end
						mret_insn_i: begin
							csr_restore_mret_id_o = !debug_mode_q;
							ctrl_fsm_ns = 5'd10;
						end
						uret_insn_i: begin
							csr_restore_uret_id_o = !debug_mode_q;
							ctrl_fsm_ns = 5'd10;
						end
						dret_insn_i: begin
							csr_restore_dret_id_o = 1'b1;
							ctrl_fsm_ns = 5'd10;
						end
						csr_status_i:
							if ((hwlp_end0_eq_pc && !hwlp_counter0_eq_0) || (hwlp_end1_eq_pc && !hwlp_counter1_eq_0)) begin
								pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
								pc_set_o = 1'b1;
							end
						wfi_i:
							if (debug_req_pending) begin
								ctrl_fsm_ns = 5'd12;
								debug_force_wakeup_n = 1'b1;
							end
							else
								ctrl_fsm_ns = 5'd3;
						fencei_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_FENCEI;
							pc_set_o = 1'b1;
						end
						default:
							;
					endcase
			end
			5'd10: begin
				is_decoding_o = 1'b0;
				ctrl_fsm_ns = 5'd5;
				(* full_case, parallel_case *)
				case (1'b1)
					mret_dec_i: begin
						pc_mux_o = (debug_mode_q ? cv32e40p_pkg_PC_EXCEPTION : cv32e40p_pkg_PC_MRET);
						pc_set_o = 1'b1;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBE;
					end
					uret_dec_i: begin
						pc_mux_o = (debug_mode_q ? cv32e40p_pkg_PC_EXCEPTION : cv32e40p_pkg_PC_URET);
						pc_set_o = 1'b1;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBE;
					end
					dret_dec_i: begin
						pc_mux_o = cv32e40p_pkg_PC_DRET;
						pc_set_o = 1'b1;
						debug_mode_n = 1'b0;
					end
					default:
						;
				endcase
				if (debug_single_step_i && ~debug_mode_q)
					ctrl_fsm_ns = 5'd12;
			end
			5'd14: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				if (branch_taken_ex_i) begin
					pc_mux_o = cv32e40p_pkg_PC_BRANCH;
					pc_set_o = 1'b1;
				end
				ctrl_fsm_ns = 5'd13;
			end
			5'd11: begin
				is_decoding_o = 1'b0;
				pc_set_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
				exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBD;
				if (~debug_mode_q) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
					if (trigger_match_i)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_TRIGGER;
					else if (ebrk_force_debug_mode & ebrk_insn_i)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_EBREAK;
					else if (debug_req_entry_q)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_HALTREQ;
				end
				debug_req_entry_n = 1'b0;
				ctrl_fsm_ns = 5'd5;
				debug_mode_n = 1'b1;
			end
			5'd12: begin
				is_decoding_o = 1'b0;
				pc_set_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
				exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBD;
				csr_save_cause_o = 1'b1;
				debug_csr_save_o = 1'b1;
				if (debug_force_wakeup_q)
					debug_cause_o = cv32e40p_pkg_DBG_CAUSE_HALTREQ;
				else if (debug_single_step_i)
					debug_cause_o = cv32e40p_pkg_DBG_CAUSE_STEP;
				csr_save_if_o = 1'b1;
				ctrl_fsm_ns = 5'd5;
				debug_mode_n = 1'b1;
				debug_force_wakeup_n = 1'b0;
			end
			5'd13: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				perf_pipeline_stall_o = data_load_event_i;
				if (data_err_i) begin
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
				end
				else if ((((debug_mode_q | trigger_match_i) | (ebrk_force_debug_mode & ebrk_insn_i)) | data_load_event_i) | debug_req_entry_q)
					ctrl_fsm_ns = 5'd11;
				else
					ctrl_fsm_ns = 5'd12;
			end
			default: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				ctrl_fsm_ns = 5'd0;
			end
		endcase
	end
	generate
		if (COREV_PULP) begin : gen_hwlp
			assign hwlp_jump_o = (hwlp_end_4_id_d && !hwlp_end_4_id_q ? 1'b1 : 1'b0);
			always @(posedge clk or negedge rst_n)
				if (!rst_n)
					hwlp_end_4_id_q <= 1'b0;
				else
					hwlp_end_4_id_q <= hwlp_end_4_id_d;
			assign hwlp_end0_eq_pc = hwlp_end_addr_i[0+:32] == (pc_id_i + 4);
			assign hwlp_end1_eq_pc = hwlp_end_addr_i[32+:32] == (pc_id_i + 4);
			assign hwlp_counter0_gt_1 = hwlp_counter_i[0+:32] > 1;
			assign hwlp_counter1_gt_1 = hwlp_counter_i[32+:32] > 1;
			assign hwlp_counter0_eq_1 = hwlp_counter_i[0+:32] == 1;
			assign hwlp_counter1_eq_1 = hwlp_counter_i[32+:32] == 1;
			assign hwlp_counter0_eq_0 = hwlp_counter_i[0+:32] == 0;
			assign hwlp_counter1_eq_0 = hwlp_counter_i[32+:32] == 0;
			assign hwlp_end0_eq_pc_plus4 = hwlp_end_addr_i[0+:32] == (pc_id_i + 8);
			assign hwlp_end1_eq_pc_plus4 = hwlp_end_addr_i[32+:32] == (pc_id_i + 8);
			assign hwlp_start0_leq_pc = hwlp_start_addr_i[0+:32] <= pc_id_i;
			assign hwlp_start1_leq_pc = hwlp_start_addr_i[32+:32] <= pc_id_i;
			assign hwlp_end0_geq_pc = hwlp_end_addr_i[0+:32] >= (pc_id_i + 4);
			assign hwlp_end1_geq_pc = hwlp_end_addr_i[32+:32] >= (pc_id_i + 4);
			assign is_hwlp_body = ((hwlp_start0_leq_pc && hwlp_end0_geq_pc) && hwlp_counter0_gt_1) || ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && hwlp_counter1_gt_1);
		end
		else begin : gen_no_hwlp
			assign hwlp_jump_o = 1'b0;
			wire [1:1] sv2v_tmp_6074E;
			assign sv2v_tmp_6074E = 1'b0;
			always @(*) hwlp_end_4_id_q = sv2v_tmp_6074E;
			assign hwlp_end0_eq_pc = 1'b0;
			assign hwlp_end1_eq_pc = 1'b0;
			assign hwlp_counter0_gt_1 = 1'b0;
			assign hwlp_counter1_gt_1 = 1'b0;
			assign hwlp_counter0_eq_1 = 1'b0;
			assign hwlp_counter1_eq_1 = 1'b0;
			assign hwlp_counter0_eq_0 = 1'b0;
			assign hwlp_counter1_eq_0 = 1'b0;
			assign hwlp_end0_eq_pc_plus4 = 1'b0;
			assign hwlp_end1_eq_pc_plus4 = 1'b0;
			assign hwlp_start0_leq_pc = 1'b0;
			assign hwlp_start1_leq_pc = 1'b0;
			assign hwlp_end0_geq_pc = 1'b0;
			assign hwlp_end1_geq_pc = 1'b0;
			assign is_hwlp_body = 1'b0;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		load_stall_o = 1'b0;
		deassert_we_o = 1'b0;
		if (~is_decoding_o)
			deassert_we_o = 1'b1;
		if (illegal_insn_i)
			deassert_we_o = 1'b1;
		if ((((data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1)) || ((wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1))) && ((((reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1)) || (reg_d_ex_is_reg_c_i == 1'b1)) || ((is_decoding_o && (regfile_we_id_i && !data_misaligned_i)) && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)))) begin
			deassert_we_o = 1'b1;
			load_stall_o = 1'b1;
		end
		if ((ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) && (((((regfile_we_wb_i == 1'b1) && (reg_d_wb_is_reg_a_i == 1'b1)) || ((regfile_we_ex_i == 1'b1) && (reg_d_ex_is_reg_a_i == 1'b1))) || ((regfile_alu_we_fw_i == 1'b1) && (reg_d_alu_is_reg_a_i == 1'b1))) || (FPU && (apu_read_dep_for_jalr_i == 1'b1)))) begin
			jr_stall_o = 1'b1;
			deassert_we_o = 1'b1;
		end
		else
			jr_stall_o = 1'b0;
	end
	assign misaligned_stall_o = data_misaligned_i;
	assign apu_stall_o = apu_read_dep_i | (apu_write_dep_i & ~apu_en_i);
	localparam cv32e40p_pkg_SEL_FW_EX = 2'b01;
	localparam cv32e40p_pkg_SEL_FW_WB = 2'b10;
	localparam cv32e40p_pkg_SEL_REGFILE = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		if (regfile_we_wb_i == 1'b1) begin
			if (reg_d_wb_is_reg_a_i == 1'b1)
				operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
			if (reg_d_wb_is_reg_b_i == 1'b1)
				operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
			if (reg_d_wb_is_reg_c_i == 1'b1)
				operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
		end
		if (regfile_alu_we_fw_i == 1'b1) begin
			if (reg_d_alu_is_reg_a_i == 1'b1)
				operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			if (reg_d_alu_is_reg_b_i == 1'b1)
				operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			if (reg_d_alu_is_reg_c_i == 1'b1)
				operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
		end
		if (data_misaligned_i) begin
			operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		end
		else if (mult_multicycle_i)
			operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
	end
	always @(posedge clk or negedge rst_n) begin : UPDATE_REGS
		if (rst_n == 1'b0) begin
			ctrl_fsm_cs <= 5'd0;
			jump_done_q <= 1'b0;
			data_err_q <= 1'b0;
			debug_mode_q <= 1'b0;
			illegal_insn_q <= 1'b0;
			debug_req_entry_q <= 1'b0;
			debug_force_wakeup_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			jump_done_q <= jump_done & ~id_ready_i;
			data_err_q <= data_err_i;
			debug_mode_q <= debug_mode_n;
			illegal_insn_q <= illegal_insn_n;
			debug_req_entry_q <= debug_req_entry_n;
			debug_force_wakeup_q <= debug_force_wakeup_n;
		end
	end
	assign wake_from_sleep_o = (irq_wu_ctrl_i || debug_req_pending) || debug_mode_q;
	assign debug_mode_o = debug_mode_q;
	assign debug_req_pending = debug_req_i || debug_req_q;
	assign debug_p_elw_no_sleep_o = ((debug_mode_q || debug_req_q) || debug_single_step_i) || trigger_match_i;
	assign debug_wfi_no_sleep_o = (((debug_mode_q || debug_req_pending) || debug_single_step_i) || trigger_match_i) || COREV_CLUSTER;
	assign wfi_active = wfi_i & ~debug_wfi_no_sleep_o;
	always @(posedge clk_ungated_i or negedge rst_n)
		if (!rst_n)
			debug_req_q <= 1'b0;
		else if (debug_req_i)
			debug_req_q <= 1'b1;
		else if (debug_mode_q)
			debug_req_q <= 1'b0;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			debug_fsm_cs <= 3'b001;
		else
			debug_fsm_cs <= debug_fsm_ns;
	always @(*) begin
		if (_sv2v_0)
			;
		debug_fsm_ns = debug_fsm_cs;
		case (debug_fsm_cs)
			3'b001:
				if (debug_mode_n || (ctrl_fsm_ns == 5'd4)) begin
					if (debug_mode_n)
						debug_fsm_ns = 3'b100;
					else
						debug_fsm_ns = 3'b010;
				end
			3'b010:
				if (debug_mode_n)
					debug_fsm_ns = 3'b100;
			3'b100:
				if (!debug_mode_n)
					debug_fsm_ns = 3'b010;
			default: debug_fsm_ns = 3'b001;
		endcase
	end
	localparam cv32e40p_pkg_HAVERESET_INDEX = 0;
	assign debug_havereset_o = debug_fsm_cs[cv32e40p_pkg_HAVERESET_INDEX];
	localparam cv32e40p_pkg_RUNNING_INDEX = 1;
	assign debug_running_o = debug_fsm_cs[cv32e40p_pkg_RUNNING_INDEX];
	localparam cv32e40p_pkg_HALTED_INDEX = 2;
	assign debug_halted_o = debug_fsm_cs[cv32e40p_pkg_HALTED_INDEX];
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_hwloop_regs_gate (
	clk,
	rst_n,
	hwlp_start_data_i,
	hwlp_end_data_i,
	hwlp_cnt_data_i,
	hwlp_we_i,
	hwlp_regid_i,
	valid_i,
	hwlp_dec_cnt_i,
	hwlp_start_addr_o,
	hwlp_end_addr_o,
	hwlp_counter_o
);
	parameter N_REGS = 2;
	parameter N_REG_BITS = $clog2(N_REGS);
	input wire clk;
	input wire rst_n;
	input wire [31:0] hwlp_start_data_i;
	input wire [31:0] hwlp_end_data_i;
	input wire [31:0] hwlp_cnt_data_i;
	input wire [2:0] hwlp_we_i;
	input wire [N_REG_BITS - 1:0] hwlp_regid_i;
	input wire valid_i;
	input wire [N_REGS - 1:0] hwlp_dec_cnt_i;
	output wire [(N_REGS * 32) - 1:0] hwlp_start_addr_o;
	output wire [(N_REGS * 32) - 1:0] hwlp_end_addr_o;
	output wire [(N_REGS * 32) - 1:0] hwlp_counter_o;
	reg [(N_REGS * 32) - 1:0] hwlp_start_q;
	reg [(N_REGS * 32) - 1:0] hwlp_end_q;
	reg [(N_REGS * 32) - 1:0] hwlp_counter_q;
	wire [(N_REGS * 32) - 1:0] hwlp_counter_n;
	reg [31:0] i;
	assign hwlp_start_addr_o = hwlp_start_q;
	assign hwlp_end_addr_o = hwlp_end_q;
	assign hwlp_counter_o = hwlp_counter_q;
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_START
		if (rst_n == 1'b0)
			hwlp_start_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else if (hwlp_we_i[0] == 1'b1)
			hwlp_start_q[hwlp_regid_i * 32+:32] <= {hwlp_start_data_i[31:2], 2'b00};
	end
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_END
		if (rst_n == 1'b0)
			hwlp_end_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else if (hwlp_we_i[1] == 1'b1)
			hwlp_end_q[hwlp_regid_i * 32+:32] <= {hwlp_end_data_i[31:2], 2'b00};
	end
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < N_REGS; _gv_k_1 = _gv_k_1 + 1) begin : genblk1
			localparam k = _gv_k_1;
			assign hwlp_counter_n[k * 32+:32] = hwlp_counter_q[k * 32+:32] - 1;
		end
	endgenerate
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_COUNTER
		if (rst_n == 1'b0)
			hwlp_counter_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else
			for (i = 0; i < N_REGS; i = i + 1)
				if ((hwlp_we_i[2] == 1'b1) && (i == hwlp_regid_i))
					hwlp_counter_q[i * 32+:32] <= hwlp_cnt_data_i;
				else if (hwlp_dec_cnt_i[i] && valid_i)
					hwlp_counter_q[i * 32+:32] <= hwlp_counter_n[i * 32+:32];
	end
endmodule
module cv32e40p_id_stage_gate (
	clk,
	clk_ungated_i,
	rst_n,
	scan_cg_en_i,
	fetch_enable_i,
	ctrl_busy_o,
	is_decoding_o,
	instr_valid_i,
	instr_rdata_i,
	instr_req_o,
	is_compressed_i,
	illegal_c_insn_i,
	branch_in_ex_o,
	branch_decision_i,
	jump_target_o,
	ctrl_transfer_insn_in_dec_o,
	clear_instr_valid_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	trap_addr_mux_o,
	is_fetch_failed_i,
	pc_id_i,
	halt_if_o,
	id_ready_o,
	ex_ready_i,
	wb_ready_i,
	id_valid_o,
	ex_valid_i,
	pc_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	alu_operand_c_ex_o,
	bmask_a_ex_o,
	bmask_b_ex_o,
	imm_vec_ext_ex_o,
	alu_vec_mode_ex_o,
	regfile_waddr_ex_o,
	regfile_we_ex_o,
	regfile_alu_waddr_ex_o,
	regfile_alu_we_ex_o,
	alu_en_ex_o,
	alu_operator_ex_o,
	alu_is_clpx_ex_o,
	alu_is_subrot_ex_o,
	alu_clpx_shift_ex_o,
	mult_operator_ex_o,
	mult_operand_a_ex_o,
	mult_operand_b_ex_o,
	mult_operand_c_ex_o,
	mult_en_ex_o,
	mult_sel_subword_ex_o,
	mult_signed_mode_ex_o,
	mult_imm_ex_o,
	mult_dot_op_a_ex_o,
	mult_dot_op_b_ex_o,
	mult_dot_op_c_ex_o,
	mult_dot_signed_ex_o,
	mult_is_clpx_ex_o,
	mult_clpx_shift_ex_o,
	mult_clpx_img_ex_o,
	apu_en_ex_o,
	apu_op_ex_o,
	apu_lat_ex_o,
	apu_operands_ex_o,
	apu_flags_ex_o,
	apu_waddr_ex_o,
	apu_read_regs_o,
	apu_read_regs_valid_o,
	apu_read_dep_i,
	apu_read_dep_for_jalr_i,
	apu_write_regs_o,
	apu_write_regs_valid_o,
	apu_write_dep_i,
	apu_perf_dep_o,
	apu_busy_i,
	fs_off_i,
	frm_i,
	csr_access_ex_o,
	csr_op_ex_o,
	current_priv_lvl_i,
	csr_irq_sec_o,
	csr_cause_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_ex_o,
	csr_restore_mret_id_o,
	csr_restore_uret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	hwlp_start_o,
	hwlp_end_o,
	hwlp_cnt_o,
	hwlp_jump_o,
	hwlp_target_o,
	data_req_ex_o,
	data_we_ex_o,
	data_type_ex_o,
	data_sign_ext_ex_o,
	data_reg_offset_ex_o,
	data_load_event_ex_o,
	data_misaligned_ex_o,
	prepost_useincr_ex_o,
	data_misaligned_i,
	data_err_i,
	data_err_ack_o,
	atop_ex_o,
	irq_i,
	irq_sec_i,
	mie_bypass_i,
	mip_o,
	m_irq_enable_i,
	u_irq_enable_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	debug_mode_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	debug_p_elw_no_sleep_o,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	wake_from_sleep_o,
	regfile_waddr_wb_i,
	regfile_we_wb_i,
	regfile_we_wb_power_i,
	regfile_wdata_wb_i,
	regfile_alu_waddr_fw_i,
	regfile_alu_we_fw_i,
	regfile_alu_we_fw_power_i,
	regfile_alu_wdata_fw_i,
	mult_multicycle_i,
	mhpmevent_minstret_o,
	mhpmevent_load_o,
	mhpmevent_store_o,
	mhpmevent_jump_o,
	mhpmevent_branch_o,
	mhpmevent_branch_taken_o,
	mhpmevent_compressed_o,
	mhpmevent_jr_stall_o,
	mhpmevent_imiss_o,
	mhpmevent_ld_stall_o,
	mhpmevent_pipe_stall_o,
	perf_imiss_i,
	mcounteren_i
);
	reg _sv2v_0;
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
	input wire clk;
	input wire clk_ungated_i;
	input wire rst_n;
	input wire scan_cg_en_i;
	input wire fetch_enable_i;
	output wire ctrl_busy_o;
	output wire is_decoding_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	input wire is_compressed_i;
	input wire illegal_c_insn_i;
	output reg branch_in_ex_o;
	input wire branch_decision_i;
	output wire [31:0] jump_target_o;
	output wire [1:0] ctrl_transfer_insn_in_dec_o;
	output wire clear_instr_valid_o;
	output wire pc_set_o;
	output wire [3:0] pc_mux_o;
	output wire [2:0] exc_pc_mux_o;
	output wire [1:0] trap_addr_mux_o;
	input wire is_fetch_failed_i;
	input wire [31:0] pc_id_i;
	output wire halt_if_o;
	output wire id_ready_o;
	input wire ex_ready_i;
	input wire wb_ready_i;
	output wire id_valid_o;
	input wire ex_valid_i;
	output reg [31:0] pc_ex_o;
	output reg [31:0] alu_operand_a_ex_o;
	output reg [31:0] alu_operand_b_ex_o;
	output reg [31:0] alu_operand_c_ex_o;
	output reg [4:0] bmask_a_ex_o;
	output reg [4:0] bmask_b_ex_o;
	output reg [1:0] imm_vec_ext_ex_o;
	output reg [1:0] alu_vec_mode_ex_o;
	output reg [5:0] regfile_waddr_ex_o;
	output reg regfile_we_ex_o;
	output reg [5:0] regfile_alu_waddr_ex_o;
	output reg regfile_alu_we_ex_o;
	output reg alu_en_ex_o;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	output reg [6:0] alu_operator_ex_o;
	output reg alu_is_clpx_ex_o;
	output reg alu_is_subrot_ex_o;
	output reg [1:0] alu_clpx_shift_ex_o;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	output reg [2:0] mult_operator_ex_o;
	output reg [31:0] mult_operand_a_ex_o;
	output reg [31:0] mult_operand_b_ex_o;
	output reg [31:0] mult_operand_c_ex_o;
	output reg mult_en_ex_o;
	output reg mult_sel_subword_ex_o;
	output reg [1:0] mult_signed_mode_ex_o;
	output reg [4:0] mult_imm_ex_o;
	output reg [31:0] mult_dot_op_a_ex_o;
	output reg [31:0] mult_dot_op_b_ex_o;
	output reg [31:0] mult_dot_op_c_ex_o;
	output reg [1:0] mult_dot_signed_ex_o;
	output reg mult_is_clpx_ex_o;
	output reg [1:0] mult_clpx_shift_ex_o;
	output reg mult_clpx_img_ex_o;
	output reg apu_en_ex_o;
	output reg [APU_WOP_CPU - 1:0] apu_op_ex_o;
	output reg [1:0] apu_lat_ex_o;
	output reg [(APU_NARGS_CPU * 32) - 1:0] apu_operands_ex_o;
	output reg [APU_NDSFLAGS_CPU - 1:0] apu_flags_ex_o;
	output reg [5:0] apu_waddr_ex_o;
	output wire [17:0] apu_read_regs_o;
	output wire [2:0] apu_read_regs_valid_o;
	input wire apu_read_dep_i;
	input wire apu_read_dep_for_jalr_i;
	output wire [11:0] apu_write_regs_o;
	output wire [1:0] apu_write_regs_valid_o;
	input wire apu_write_dep_i;
	output wire apu_perf_dep_o;
	input wire apu_busy_i;
	input wire fs_off_i;
	localparam cv32e40p_pkg_C_RM = 3;
	input wire [2:0] frm_i;
	output reg csr_access_ex_o;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	output reg [1:0] csr_op_ex_o;
	input wire [1:0] current_priv_lvl_i;
	output wire csr_irq_sec_o;
	output wire [5:0] csr_cause_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_save_ex_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_uret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_start_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_end_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_cnt_o;
	output wire hwlp_jump_o;
	output wire [31:0] hwlp_target_o;
	output reg data_req_ex_o;
	output reg data_we_ex_o;
	output reg [1:0] data_type_ex_o;
	output reg [1:0] data_sign_ext_ex_o;
	output reg [1:0] data_reg_offset_ex_o;
	output reg data_load_event_ex_o;
	output reg data_misaligned_ex_o;
	output reg prepost_useincr_ex_o;
	input wire data_misaligned_i;
	input wire data_err_i;
	output wire data_err_ack_o;
	output reg [5:0] atop_ex_o;
	input wire [31:0] irq_i;
	input wire irq_sec_i;
	input wire [31:0] mie_bypass_i;
	output wire [31:0] mip_o;
	input wire m_irq_enable_i;
	input wire u_irq_enable_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	output wire [4:0] exc_cause_o;
	output wire debug_mode_o;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output wire debug_p_elw_no_sleep_o;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	output wire wake_from_sleep_o;
	input wire [5:0] regfile_waddr_wb_i;
	input wire regfile_we_wb_i;
	input wire regfile_we_wb_power_i;
	input wire [31:0] regfile_wdata_wb_i;
	input wire [5:0] regfile_alu_waddr_fw_i;
	input wire regfile_alu_we_fw_i;
	input wire regfile_alu_we_fw_power_i;
	input wire [31:0] regfile_alu_wdata_fw_i;
	input wire mult_multicycle_i;
	output reg mhpmevent_minstret_o;
	output reg mhpmevent_load_o;
	output reg mhpmevent_store_o;
	output reg mhpmevent_jump_o;
	output reg mhpmevent_branch_o;
	output reg mhpmevent_branch_taken_o;
	output reg mhpmevent_compressed_o;
	output reg mhpmevent_jr_stall_o;
	output reg mhpmevent_imiss_o;
	output reg mhpmevent_ld_stall_o;
	output reg mhpmevent_pipe_stall_o;
	input wire perf_imiss_i;
	input wire [31:0] mcounteren_i;
	localparam REG_S1_MSB = 19;
	localparam REG_S1_LSB = 15;
	localparam REG_S2_MSB = 24;
	localparam REG_S2_LSB = 20;
	localparam REG_S4_MSB = 31;
	localparam REG_S4_LSB = 27;
	localparam REG_D_MSB = 11;
	localparam REG_D_LSB = 7;
	wire [31:0] instr;
	wire deassert_we;
	wire illegal_insn_dec;
	wire ebrk_insn_dec;
	wire mret_insn_dec;
	wire uret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire wfi_insn_dec;
	wire fencei_insn_dec;
	wire rega_used_dec;
	wire regb_used_dec;
	wire regc_used_dec;
	wire branch_taken_ex;
	wire [1:0] ctrl_transfer_insn_in_id;
	wire [1:0] ctrl_transfer_insn_in_dec;
	wire misaligned_stall;
	wire jr_stall;
	wire load_stall;
	wire csr_apu_stall;
	wire hwlp_mask;
	wire halt_id;
	wire halt_if;
	wire debug_wfi_no_sleep;
	wire [31:0] imm_i_type;
	wire [31:0] imm_iz_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_sb_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_uj_type;
	wire [31:0] imm_z_type;
	wire [31:0] imm_s2_type;
	wire [31:0] imm_bi_type;
	wire [31:0] imm_s3_type;
	wire [31:0] imm_vs_type;
	wire [31:0] imm_vu_type;
	wire [31:0] imm_shuffleb_type;
	wire [31:0] imm_shuffleh_type;
	reg [31:0] imm_shuffle_type;
	wire [31:0] imm_clip_type;
	reg [31:0] imm_a;
	reg [31:0] imm_b;
	reg [31:0] jump_target;
	wire irq_req_ctrl;
	wire irq_sec_ctrl;
	wire irq_wu_ctrl;
	wire [4:0] irq_id_ctrl;
	wire [5:0] regfile_addr_ra_id;
	wire [5:0] regfile_addr_rb_id;
	reg [5:0] regfile_addr_rc_id;
	wire regfile_fp_a;
	wire regfile_fp_b;
	wire regfile_fp_c;
	wire regfile_fp_d;
	wire [5:0] regfile_waddr_id;
	wire [5:0] regfile_alu_waddr_id;
	wire regfile_alu_we_id;
	wire regfile_alu_we_dec_id;
	wire [31:0] regfile_data_ra_id;
	wire [31:0] regfile_data_rb_id;
	wire [31:0] regfile_data_rc_id;
	wire alu_en;
	wire [6:0] alu_operator;
	wire [2:0] alu_op_a_mux_sel;
	wire [2:0] alu_op_b_mux_sel;
	wire [1:0] alu_op_c_mux_sel;
	wire [1:0] regc_mux;
	wire [0:0] imm_a_mux_sel;
	wire [3:0] imm_b_mux_sel;
	wire [1:0] ctrl_transfer_target_mux_sel;
	wire [2:0] mult_operator;
	wire mult_en;
	wire mult_int_en;
	wire mult_sel_subword;
	wire [1:0] mult_signed_mode;
	wire mult_dot_en;
	wire [1:0] mult_dot_signed;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] cv32e40p_fpu_pkg_FP_FORMAT_BITS = 3;
	wire [2:0] fpu_src_fmt;
	wire [2:0] fpu_dst_fmt;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_INT_FORMATS = 4;
	localparam [31:0] cv32e40p_fpu_pkg_INT_FORMAT_BITS = 2;
	wire [1:0] fpu_int_fmt;
	wire apu_en;
	wire [APU_WOP_CPU - 1:0] apu_op;
	wire [1:0] apu_lat;
	wire [(APU_NARGS_CPU * 32) - 1:0] apu_operands;
	wire [APU_NDSFLAGS_CPU - 1:0] apu_flags;
	wire [5:0] apu_waddr;
	reg [17:0] apu_read_regs;
	reg [2:0] apu_read_regs_valid;
	wire [11:0] apu_write_regs;
	wire [1:0] apu_write_regs_valid;
	wire apu_stall;
	wire [2:0] fp_rnd_mode;
	wire regfile_we_id;
	wire regfile_alu_waddr_mux_sel;
	wire data_we_id;
	wire [1:0] data_type_id;
	wire [1:0] data_sign_ext_id;
	wire [1:0] data_reg_offset_id;
	wire data_req_id;
	wire data_load_event_id;
	wire [5:0] atop_id;
	wire [N_HWLP_BITS - 1:0] hwlp_regid;
	wire [2:0] hwlp_we;
	wire [2:0] hwlp_we_masked;
	wire [1:0] hwlp_target_mux_sel;
	wire [1:0] hwlp_start_mux_sel;
	wire hwlp_cnt_mux_sel;
	reg [31:0] hwlp_start;
	reg [31:0] hwlp_end;
	reg [31:0] hwlp_cnt;
	wire [N_HWLP - 1:0] hwlp_dec_cnt;
	wire hwlp_valid;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_status;
	wire prepost_useincr;
	wire [1:0] operand_a_fw_mux_sel;
	wire [1:0] operand_b_fw_mux_sel;
	wire [1:0] operand_c_fw_mux_sel;
	reg [31:0] operand_a_fw_id;
	reg [31:0] operand_b_fw_id;
	reg [31:0] operand_c_fw_id;
	reg [31:0] operand_b;
	reg [31:0] operand_b_vec;
	reg [31:0] operand_c;
	reg [31:0] operand_c_vec;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	wire [31:0] alu_operand_c;
	wire [0:0] bmask_a_mux;
	wire [1:0] bmask_b_mux;
	wire alu_bmask_a_mux_sel;
	wire alu_bmask_b_mux_sel;
	wire [0:0] mult_imm_mux;
	reg [4:0] bmask_a_id_imm;
	reg [4:0] bmask_b_id_imm;
	reg [4:0] bmask_a_id;
	reg [4:0] bmask_b_id;
	wire [1:0] imm_vec_ext_id;
	reg [4:0] mult_imm_id;
	wire alu_vec;
	wire [1:0] alu_vec_mode;
	wire scalar_replication;
	wire scalar_replication_c;
	wire reg_d_ex_is_reg_a_id;
	wire reg_d_ex_is_reg_b_id;
	wire reg_d_ex_is_reg_c_id;
	wire reg_d_wb_is_reg_a_id;
	wire reg_d_wb_is_reg_b_id;
	wire reg_d_wb_is_reg_c_id;
	wire reg_d_alu_is_reg_a_id;
	wire reg_d_alu_is_reg_b_id;
	wire reg_d_alu_is_reg_c_id;
	wire is_clpx;
	wire is_subrot;
	wire mret_dec;
	wire uret_dec;
	wire dret_dec;
	reg id_valid_q;
	wire minstret;
	wire perf_pipeline_stall;
	assign instr = instr_rdata_i;
	assign imm_i_type = {{20 {instr[31]}}, instr[31:20]};
	assign imm_iz_type = {20'b00000000000000000000, instr[31:20]};
	assign imm_s_type = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_sb_type = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type = {instr[31:12], 12'b000000000000};
	assign imm_uj_type = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign imm_z_type = {27'b000000000000000000000000000, instr[REG_S1_MSB:REG_S1_LSB]};
	assign imm_s2_type = {27'b000000000000000000000000000, instr[24:20]};
	assign imm_bi_type = {{27 {instr[24]}}, instr[24:20]};
	assign imm_s3_type = {27'b000000000000000000000000000, instr[29:25]};
	assign imm_vs_type = {{26 {instr[24]}}, instr[24:20], instr[25]};
	assign imm_vu_type = {26'b00000000000000000000000000, instr[24:20], instr[25]};
	assign imm_shuffleb_type = {6'b000000, instr[28:27], 6'b000000, instr[24:23], 6'b000000, instr[22:21], 6'b000000, instr[20], instr[25]};
	assign imm_shuffleh_type = {15'h0000, instr[20], 15'h0000, instr[25]};
	assign imm_clip_type = (32'h00000001 << instr[24:20]) - 1;
	assign regfile_addr_ra_id = {regfile_fp_a, instr[REG_S1_MSB:REG_S1_LSB]};
	assign regfile_addr_rb_id = {regfile_fp_b, instr[REG_S2_MSB:REG_S2_LSB]};
	localparam cv32e40p_pkg_REGC_RD = 2'b01;
	localparam cv32e40p_pkg_REGC_S1 = 2'b10;
	localparam cv32e40p_pkg_REGC_S4 = 2'b00;
	localparam cv32e40p_pkg_REGC_ZERO = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (regc_mux)
			cv32e40p_pkg_REGC_ZERO: regfile_addr_rc_id = 1'sb0;
			cv32e40p_pkg_REGC_RD: regfile_addr_rc_id = {regfile_fp_c, instr[REG_D_MSB:REG_D_LSB]};
			cv32e40p_pkg_REGC_S1: regfile_addr_rc_id = {regfile_fp_c, instr[REG_S1_MSB:REG_S1_LSB]};
			cv32e40p_pkg_REGC_S4: regfile_addr_rc_id = {regfile_fp_c, instr[REG_S4_MSB:REG_S4_LSB]};
		endcase
	end
	assign regfile_waddr_id = {regfile_fp_d, instr[REG_D_MSB:REG_D_LSB]};
	assign regfile_alu_waddr_id = (regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id);
	assign reg_d_ex_is_reg_a_id = ((regfile_waddr_ex_o == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_ex_is_reg_b_id = ((regfile_waddr_ex_o == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_ex_is_reg_c_id = ((regfile_waddr_ex_o == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_a_id = ((regfile_waddr_wb_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_b_id = ((regfile_waddr_wb_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_c_id = ((regfile_waddr_wb_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_a_id = ((regfile_alu_waddr_fw_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_b_id = ((regfile_alu_waddr_fw_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_c_id = ((regfile_alu_waddr_fw_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign clear_instr_valid_o = (id_ready_o | halt_id) | branch_taken_ex;
	assign branch_taken_ex = branch_in_ex_o && branch_decision_i;
	assign mult_en = mult_int_en | mult_dot_en;
	localparam cv32e40p_pkg_JT_COND = 2'b11;
	localparam cv32e40p_pkg_JT_JAL = 2'b01;
	localparam cv32e40p_pkg_JT_JALR = 2'b10;
	always @(*) begin : jump_target_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (ctrl_transfer_target_mux_sel)
			cv32e40p_pkg_JT_JAL: jump_target = pc_id_i + imm_uj_type;
			cv32e40p_pkg_JT_COND: jump_target = pc_id_i + imm_sb_type;
			cv32e40p_pkg_JT_JALR: jump_target = regfile_data_ra_id + imm_i_type;
			default: jump_target = regfile_data_ra_id + imm_i_type;
		endcase
	end
	assign jump_target_o = jump_target;
	localparam cv32e40p_pkg_OP_A_CURRPC = 3'b001;
	localparam cv32e40p_pkg_OP_A_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_A_REGA_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_A_REGB_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_A_REGC_OR_FWD = 3'b100;
	always @(*) begin : alu_operand_a_mux
		if (_sv2v_0)
			;
		case (alu_op_a_mux_sel)
			cv32e40p_pkg_OP_A_REGA_OR_FWD: alu_operand_a = operand_a_fw_id;
			cv32e40p_pkg_OP_A_REGB_OR_FWD: alu_operand_a = operand_b_fw_id;
			cv32e40p_pkg_OP_A_REGC_OR_FWD: alu_operand_a = operand_c_fw_id;
			cv32e40p_pkg_OP_A_CURRPC: alu_operand_a = pc_id_i;
			cv32e40p_pkg_OP_A_IMM: alu_operand_a = imm_a;
			default: alu_operand_a = operand_a_fw_id;
		endcase
	end
	localparam cv32e40p_pkg_IMMA_Z = 1'b0;
	localparam cv32e40p_pkg_IMMA_ZERO = 1'b1;
	always @(*) begin : immediate_a_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (imm_a_mux_sel)
			cv32e40p_pkg_IMMA_Z: imm_a = imm_z_type;
			cv32e40p_pkg_IMMA_ZERO: imm_a = 1'sb0;
		endcase
	end
	localparam cv32e40p_pkg_SEL_FW_EX = 2'b01;
	localparam cv32e40p_pkg_SEL_FW_WB = 2'b10;
	localparam cv32e40p_pkg_SEL_REGFILE = 2'b00;
	always @(*) begin : operand_a_fw_mux
		if (_sv2v_0)
			;
		case (operand_a_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_a_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_a_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_a_fw_id = regfile_data_ra_id;
			default: operand_a_fw_id = regfile_data_ra_id;
		endcase
	end
	localparam cv32e40p_pkg_IMMB_BI = 4'b1011;
	localparam cv32e40p_pkg_IMMB_CLIP = 4'b1001;
	localparam cv32e40p_pkg_IMMB_I = 4'b0000;
	localparam cv32e40p_pkg_IMMB_PCINCR = 4'b0011;
	localparam cv32e40p_pkg_IMMB_S = 4'b0001;
	localparam cv32e40p_pkg_IMMB_S2 = 4'b0100;
	localparam cv32e40p_pkg_IMMB_S3 = 4'b0101;
	localparam cv32e40p_pkg_IMMB_SHUF = 4'b1000;
	localparam cv32e40p_pkg_IMMB_U = 4'b0010;
	localparam cv32e40p_pkg_IMMB_VS = 4'b0110;
	localparam cv32e40p_pkg_IMMB_VU = 4'b0111;
	always @(*) begin : immediate_b_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (imm_b_mux_sel)
			cv32e40p_pkg_IMMB_I: imm_b = imm_i_type;
			cv32e40p_pkg_IMMB_S: imm_b = imm_s_type;
			cv32e40p_pkg_IMMB_U: imm_b = imm_u_type;
			cv32e40p_pkg_IMMB_PCINCR: imm_b = (is_compressed_i ? 32'h00000002 : 32'h00000004);
			cv32e40p_pkg_IMMB_S2: imm_b = imm_s2_type;
			cv32e40p_pkg_IMMB_BI: imm_b = imm_bi_type;
			cv32e40p_pkg_IMMB_S3: imm_b = imm_s3_type;
			cv32e40p_pkg_IMMB_VS: imm_b = imm_vs_type;
			cv32e40p_pkg_IMMB_VU: imm_b = imm_vu_type;
			cv32e40p_pkg_IMMB_SHUF: imm_b = imm_shuffle_type;
			cv32e40p_pkg_IMMB_CLIP: imm_b = {1'b0, imm_clip_type[31:1]};
			default: imm_b = imm_i_type;
		endcase
	end
	localparam cv32e40p_pkg_OP_B_BMASK = 3'b100;
	localparam cv32e40p_pkg_OP_B_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_B_REGA_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_B_REGB_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_B_REGC_OR_FWD = 3'b001;
	always @(*) begin : alu_operand_b_mux
		if (_sv2v_0)
			;
		case (alu_op_b_mux_sel)
			cv32e40p_pkg_OP_B_REGA_OR_FWD: operand_b = operand_a_fw_id;
			cv32e40p_pkg_OP_B_REGB_OR_FWD: operand_b = operand_b_fw_id;
			cv32e40p_pkg_OP_B_REGC_OR_FWD: operand_b = operand_c_fw_id;
			cv32e40p_pkg_OP_B_IMM: operand_b = imm_b;
			cv32e40p_pkg_OP_B_BMASK: operand_b = $unsigned(operand_b_fw_id[4:0]);
			default: operand_b = operand_b_fw_id;
		endcase
	end
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		if (alu_vec_mode == cv32e40p_pkg_VEC_MODE8) begin
			operand_b_vec = {4 {operand_b[7:0]}};
			imm_shuffle_type = imm_shuffleb_type;
		end
		else begin
			operand_b_vec = {2 {operand_b[15:0]}};
			imm_shuffle_type = imm_shuffleh_type;
		end
	end
	assign alu_operand_b = (scalar_replication == 1'b1 ? operand_b_vec : operand_b);
	always @(*) begin : operand_b_fw_mux
		if (_sv2v_0)
			;
		case (operand_b_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_b_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_b_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_b_fw_id = regfile_data_rb_id;
			default: operand_b_fw_id = regfile_data_rb_id;
		endcase
	end
	localparam cv32e40p_pkg_OP_C_JT = 2'b10;
	localparam cv32e40p_pkg_OP_C_REGB_OR_FWD = 2'b01;
	localparam cv32e40p_pkg_OP_C_REGC_OR_FWD = 2'b00;
	always @(*) begin : alu_operand_c_mux
		if (_sv2v_0)
			;
		case (alu_op_c_mux_sel)
			cv32e40p_pkg_OP_C_REGC_OR_FWD: operand_c = operand_c_fw_id;
			cv32e40p_pkg_OP_C_REGB_OR_FWD: operand_c = operand_b_fw_id;
			cv32e40p_pkg_OP_C_JT: operand_c = jump_target;
			default: operand_c = operand_c_fw_id;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (alu_vec_mode == cv32e40p_pkg_VEC_MODE8)
			operand_c_vec = {4 {operand_c[7:0]}};
		else
			operand_c_vec = {2 {operand_c[15:0]}};
	end
	assign alu_operand_c = (scalar_replication_c == 1'b1 ? operand_c_vec : operand_c);
	always @(*) begin : operand_c_fw_mux
		if (_sv2v_0)
			;
		case (operand_c_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_c_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_c_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_c_fw_id = regfile_data_rc_id;
			default: operand_c_fw_id = regfile_data_rc_id;
		endcase
	end
	localparam cv32e40p_pkg_BMASK_A_S3 = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_ZERO = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (bmask_a_mux)
			cv32e40p_pkg_BMASK_A_ZERO: bmask_a_id_imm = 1'sb0;
			cv32e40p_pkg_BMASK_A_S3: bmask_a_id_imm = imm_s3_type[4:0];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_B_ONE = 2'b11;
	localparam cv32e40p_pkg_BMASK_B_S2 = 2'b00;
	localparam cv32e40p_pkg_BMASK_B_S3 = 2'b01;
	localparam cv32e40p_pkg_BMASK_B_ZERO = 2'b10;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (bmask_b_mux)
			cv32e40p_pkg_BMASK_B_ZERO: bmask_b_id_imm = 1'sb0;
			cv32e40p_pkg_BMASK_B_ONE: bmask_b_id_imm = 5'd1;
			cv32e40p_pkg_BMASK_B_S2: bmask_b_id_imm = imm_s2_type[4:0];
			cv32e40p_pkg_BMASK_B_S3: bmask_b_id_imm = imm_s3_type[4:0];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_A_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_REG = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_bmask_a_mux_sel)
			cv32e40p_pkg_BMASK_A_IMM: bmask_a_id = bmask_a_id_imm;
			cv32e40p_pkg_BMASK_A_REG: bmask_a_id = operand_b_fw_id[9:5];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_B_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_B_REG = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_bmask_b_mux_sel)
			cv32e40p_pkg_BMASK_B_IMM: bmask_b_id = bmask_b_id_imm;
			cv32e40p_pkg_BMASK_B_REG: bmask_b_id = operand_b_fw_id[4:0];
		endcase
	end
	generate
		if (!COREV_PULP) begin : genblk1
			assign imm_vec_ext_id = imm_vu_type[1:0];
		end
		else begin : genblk1
			assign imm_vec_ext_id = (alu_vec ? imm_vu_type[1:0] : 2'b00);
		end
	endgenerate
	localparam cv32e40p_pkg_MIMM_S3 = 1'b1;
	localparam cv32e40p_pkg_MIMM_ZERO = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (mult_imm_mux)
			cv32e40p_pkg_MIMM_ZERO: mult_imm_id = 1'sb0;
			cv32e40p_pkg_MIMM_S3: mult_imm_id = imm_s3_type[4:0];
		endcase
	end
	generate
		if (APU == 1) begin : gen_apu
			if (APU_NARGS_CPU >= 1) begin : genblk1
				assign apu_operands[0+:32] = alu_operand_a;
			end
			if (APU_NARGS_CPU >= 2) begin : genblk2
				assign apu_operands[32+:32] = alu_operand_b;
			end
			if (APU_NARGS_CPU >= 3) begin : genblk3
				assign apu_operands[64+:32] = alu_operand_c;
			end
			assign apu_waddr = regfile_alu_waddr_id;
			assign apu_flags = (FPU == 1 ? {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} : {APU_NDSFLAGS_CPU {1'sb0}});
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_a_mux_sel)
					cv32e40p_pkg_OP_A_CURRPC:
						if (ctrl_transfer_target_mux_sel == cv32e40p_pkg_JT_JALR) begin
							apu_read_regs[0+:6] = regfile_addr_ra_id;
							apu_read_regs_valid[0] = 1'b1;
						end
						else begin
							apu_read_regs[0+:6] = regfile_addr_ra_id;
							apu_read_regs_valid[0] = 1'b0;
						end
					cv32e40p_pkg_OP_A_REGA_OR_FWD: begin
						apu_read_regs[0+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[0] = 1'b1;
					end
					cv32e40p_pkg_OP_A_REGB_OR_FWD, cv32e40p_pkg_OP_A_REGC_OR_FWD: begin
						apu_read_regs[0+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[0] = 1'b1;
					end
					default: begin
						apu_read_regs[0+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[0] = 1'b0;
					end
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_b_mux_sel)
					cv32e40p_pkg_OP_B_REGA_OR_FWD: begin
						apu_read_regs[6+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_REGB_OR_FWD, cv32e40p_pkg_OP_B_BMASK: begin
						apu_read_regs[6+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_REGC_OR_FWD: begin
						apu_read_regs[6+:6] = regfile_addr_rc_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_IMM:
						if (alu_bmask_b_mux_sel == cv32e40p_pkg_BMASK_B_REG) begin
							apu_read_regs[6+:6] = regfile_addr_rb_id;
							apu_read_regs_valid[1] = 1'b1;
						end
						else begin
							apu_read_regs[6+:6] = regfile_addr_rb_id;
							apu_read_regs_valid[1] = 1'b0;
						end
					default: begin
						apu_read_regs[6+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[1] = 1'b0;
					end
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_c_mux_sel)
					cv32e40p_pkg_OP_C_REGB_OR_FWD: begin
						apu_read_regs[12+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[2] = 1'b1;
					end
					cv32e40p_pkg_OP_C_REGC_OR_FWD:
						if ((((alu_op_a_mux_sel != cv32e40p_pkg_OP_A_REGC_OR_FWD) && (ctrl_transfer_target_mux_sel != cv32e40p_pkg_JT_JALR)) && !((alu_op_b_mux_sel == cv32e40p_pkg_OP_B_IMM) && (alu_bmask_b_mux_sel == cv32e40p_pkg_BMASK_B_REG))) && (alu_op_b_mux_sel != cv32e40p_pkg_OP_B_BMASK)) begin
							apu_read_regs[12+:6] = regfile_addr_rc_id;
							apu_read_regs_valid[2] = 1'b1;
						end
						else begin
							apu_read_regs[12+:6] = regfile_addr_rc_id;
							apu_read_regs_valid[2] = 1'b0;
						end
					default: begin
						apu_read_regs[12+:6] = regfile_addr_rc_id;
						apu_read_regs_valid[2] = 1'b0;
					end
				endcase
			end
			assign apu_write_regs[0+:6] = regfile_alu_waddr_id;
			assign apu_write_regs_valid[0] = regfile_alu_we_id;
			assign apu_write_regs[6+:6] = regfile_waddr_id;
			assign apu_write_regs_valid[1] = regfile_we_id;
			assign apu_read_regs_o = apu_read_regs;
			assign apu_read_regs_valid_o = apu_read_regs_valid;
			assign apu_write_regs_o = apu_write_regs;
			assign apu_write_regs_valid_o = apu_write_regs_valid;
		end
		else begin : gen_no_apu
			genvar _gv_i_2;
			for (_gv_i_2 = 0; _gv_i_2 < APU_NARGS_CPU; _gv_i_2 = _gv_i_2 + 1) begin : gen_apu_tie_off
				localparam i = _gv_i_2;
				assign apu_operands[i * 32+:32] = 1'sb0;
			end
			wire [18:1] sv2v_tmp_B43AF;
			assign sv2v_tmp_B43AF = 1'sb0;
			always @(*) apu_read_regs = sv2v_tmp_B43AF;
			wire [3:1] sv2v_tmp_093B8;
			assign sv2v_tmp_093B8 = 1'sb0;
			always @(*) apu_read_regs_valid = sv2v_tmp_093B8;
			assign apu_write_regs = 1'sb0;
			assign apu_write_regs_valid = 1'sb0;
			assign apu_waddr = 1'sb0;
			assign apu_flags = 1'sb0;
			assign apu_write_regs_o = 1'sb0;
			assign apu_read_regs_o = 1'sb0;
			assign apu_write_regs_valid_o = 1'sb0;
			assign apu_read_regs_valid_o = 1'sb0;
		end
	endgenerate
	assign apu_perf_dep_o = apu_stall;
	assign csr_apu_stall = csr_access & ((apu_en_ex_o & (apu_lat_ex_o[1] == 1'b1)) | apu_busy_i);
	cv32e40p_register_file_gate #(
		.ADDR_WIDTH(6),
		.DATA_WIDTH(32),
		.FPU(FPU),
		.ZFINX(ZFINX)
	) register_file_i(
		.clk(clk),
		.rst_n(rst_n),
		.scan_cg_en_i(scan_cg_en_i),
		.raddr_a_i(regfile_addr_ra_id),
		.rdata_a_o(regfile_data_ra_id),
		.raddr_b_i(regfile_addr_rb_id),
		.rdata_b_o(regfile_data_rb_id),
		.raddr_c_i(regfile_addr_rc_id),
		.rdata_c_o(regfile_data_rc_id),
		.waddr_a_i(regfile_waddr_wb_i),
		.wdata_a_i(regfile_wdata_wb_i),
		.we_a_i(regfile_we_wb_power_i),
		.waddr_b_i(regfile_alu_waddr_fw_i),
		.wdata_b_i(regfile_alu_wdata_fw_i),
		.we_b_i(regfile_alu_we_fw_power_i)
	);
	cv32e40p_decoder_gate #(
		.COREV_PULP(COREV_PULP),
		.COREV_CLUSTER(COREV_CLUSTER),
		.A_EXTENSION(A_EXTENSION),
		.FPU(FPU),
		.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
		.FPU_OTHERS_LAT(FPU_OTHERS_LAT),
		.ZFINX(ZFINX),
		.PULP_SECURE(PULP_SECURE),
		.USE_PMP(USE_PMP),
		.APU_WOP_CPU(APU_WOP_CPU),
		.DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
	) decoder_i(
		.deassert_we_i(deassert_we),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn_dec),
		.mret_insn_o(mret_insn_dec),
		.uret_insn_o(uret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.mret_dec_o(mret_dec),
		.uret_dec_o(uret_dec),
		.dret_dec_o(dret_dec),
		.ecall_insn_o(ecall_insn_dec),
		.wfi_o(wfi_insn_dec),
		.fencei_insn_o(fencei_insn_dec),
		.rega_used_o(rega_used_dec),
		.regb_used_o(regb_used_dec),
		.regc_used_o(regc_used_dec),
		.reg_fp_a_o(regfile_fp_a),
		.reg_fp_b_o(regfile_fp_b),
		.reg_fp_c_o(regfile_fp_c),
		.reg_fp_d_o(regfile_fp_d),
		.bmask_a_mux_o(bmask_a_mux),
		.bmask_b_mux_o(bmask_b_mux),
		.alu_bmask_a_mux_sel_o(alu_bmask_a_mux_sel),
		.alu_bmask_b_mux_sel_o(alu_bmask_b_mux_sel),
		.instr_rdata_i(instr),
		.illegal_c_insn_i(illegal_c_insn_i),
		.alu_en_o(alu_en),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel),
		.alu_op_c_mux_sel_o(alu_op_c_mux_sel),
		.alu_vec_o(alu_vec),
		.alu_vec_mode_o(alu_vec_mode),
		.scalar_replication_o(scalar_replication),
		.scalar_replication_c_o(scalar_replication_c),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel),
		.regc_mux_o(regc_mux),
		.is_clpx_o(is_clpx),
		.is_subrot_o(is_subrot),
		.mult_operator_o(mult_operator),
		.mult_int_en_o(mult_int_en),
		.mult_sel_subword_o(mult_sel_subword),
		.mult_signed_mode_o(mult_signed_mode),
		.mult_imm_mux_o(mult_imm_mux),
		.mult_dot_en_o(mult_dot_en),
		.mult_dot_signed_o(mult_dot_signed),
		.fs_off_i(fs_off_i),
		.frm_i(frm_i),
		.fpu_src_fmt_o(fpu_src_fmt),
		.fpu_dst_fmt_o(fpu_dst_fmt),
		.fpu_int_fmt_o(fpu_int_fmt),
		.apu_en_o(apu_en),
		.apu_op_o(apu_op),
		.apu_lat_o(apu_lat),
		.fp_rnd_mode_o(fp_rnd_mode),
		.regfile_mem_we_o(regfile_we_id),
		.regfile_alu_we_o(regfile_alu_we_id),
		.regfile_alu_we_dec_o(regfile_alu_we_dec_id),
		.regfile_alu_waddr_sel_o(regfile_alu_waddr_mux_sel),
		.csr_access_o(csr_access),
		.csr_status_o(csr_status),
		.csr_op_o(csr_op),
		.current_priv_lvl_i(current_priv_lvl_i),
		.data_req_o(data_req_id),
		.data_we_o(data_we_id),
		.prepost_useincr_o(prepost_useincr),
		.data_type_o(data_type_id),
		.data_sign_extension_o(data_sign_ext_id),
		.data_reg_offset_o(data_reg_offset_id),
		.data_load_event_o(data_load_event_id),
		.atop_o(atop_id),
		.hwlp_we_o(hwlp_we),
		.hwlp_target_mux_sel_o(hwlp_target_mux_sel),
		.hwlp_start_mux_sel_o(hwlp_start_mux_sel),
		.hwlp_cnt_mux_sel_o(hwlp_cnt_mux_sel),
		.debug_mode_i(debug_mode_o),
		.debug_wfi_no_sleep_i(debug_wfi_no_sleep),
		.ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec_o),
		.ctrl_transfer_insn_in_id_o(ctrl_transfer_insn_in_id),
		.ctrl_transfer_target_mux_sel_o(ctrl_transfer_target_mux_sel),
		.mcounteren_i(mcounteren_i)
	);
	cv32e40p_controller_gate #(
		.COREV_CLUSTER(COREV_CLUSTER),
		.COREV_PULP(COREV_PULP),
		.FPU(FPU)
	) controller_i(
		.clk(clk),
		.clk_ungated_i(clk_ungated_i),
		.rst_n(rst_n),
		.fetch_enable_i(fetch_enable_i),
		.ctrl_busy_o(ctrl_busy_o),
		.is_decoding_o(is_decoding_o),
		.is_fetch_failed_i(is_fetch_failed_i),
		.deassert_we_o(deassert_we),
		.illegal_insn_i(illegal_insn_dec),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.uret_insn_i(uret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.mret_dec_i(mret_dec),
		.uret_dec_i(uret_dec),
		.dret_dec_i(dret_dec),
		.wfi_i(wfi_insn_dec),
		.ebrk_insn_i(ebrk_insn_dec),
		.fencei_insn_i(fencei_insn_dec),
		.csr_status_i(csr_status),
		.hwlp_mask_o(hwlp_mask),
		.instr_valid_i(instr_valid_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.trap_addr_mux_o(trap_addr_mux_o),
		.pc_id_i(pc_id_i),
		.hwlp_start_addr_i(hwlp_start_o),
		.hwlp_end_addr_i(hwlp_end_o),
		.hwlp_counter_i(hwlp_cnt_o),
		.hwlp_dec_cnt_o(hwlp_dec_cnt),
		.hwlp_jump_o(hwlp_jump_o),
		.hwlp_targ_addr_o(hwlp_target_o),
		.data_req_ex_i(data_req_ex_o),
		.data_we_ex_i(data_we_ex_o),
		.data_misaligned_i(data_misaligned_i),
		.data_load_event_i(data_load_event_id),
		.data_err_i(data_err_i),
		.data_err_ack_o(data_err_ack_o),
		.mult_multicycle_i(mult_multicycle_i),
		.apu_en_i(apu_en),
		.apu_read_dep_i(apu_read_dep_i),
		.apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
		.apu_write_dep_i(apu_write_dep_i),
		.apu_stall_o(apu_stall),
		.branch_taken_ex_i(branch_taken_ex),
		.ctrl_transfer_insn_in_id_i(ctrl_transfer_insn_in_id),
		.ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec_o),
		.irq_wu_ctrl_i(irq_wu_ctrl),
		.irq_req_ctrl_i(irq_req_ctrl),
		.irq_sec_ctrl_i(irq_sec_ctrl),
		.irq_id_ctrl_i(irq_id_ctrl),
		.current_priv_lvl_i(current_priv_lvl_i),
		.irq_ack_o(irq_ack_o),
		.irq_id_o(irq_id_o),
		.debug_mode_o(debug_mode_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.debug_ebreaku_i(debug_ebreaku_i),
		.trigger_match_i(trigger_match_i),
		.debug_p_elw_no_sleep_o(debug_p_elw_no_sleep_o),
		.debug_wfi_no_sleep_o(debug_wfi_no_sleep),
		.debug_havereset_o(debug_havereset_o),
		.debug_running_o(debug_running_o),
		.debug_halted_o(debug_halted_o),
		.wake_from_sleep_o(wake_from_sleep_o),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_cause_o(csr_cause_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_save_ex_o(csr_save_ex_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_uret_id_o(csr_restore_uret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.csr_irq_sec_o(csr_irq_sec_o),
		.regfile_we_id_i(regfile_alu_we_dec_id),
		.regfile_alu_waddr_id_i(regfile_alu_waddr_id),
		.regfile_we_ex_i(regfile_we_ex_o),
		.regfile_waddr_ex_i(regfile_waddr_ex_o),
		.regfile_we_wb_i(regfile_we_wb_i),
		.regfile_alu_we_fw_i(regfile_alu_we_fw_i),
		.reg_d_ex_is_reg_a_i(reg_d_ex_is_reg_a_id),
		.reg_d_ex_is_reg_b_i(reg_d_ex_is_reg_b_id),
		.reg_d_ex_is_reg_c_i(reg_d_ex_is_reg_c_id),
		.reg_d_wb_is_reg_a_i(reg_d_wb_is_reg_a_id),
		.reg_d_wb_is_reg_b_i(reg_d_wb_is_reg_b_id),
		.reg_d_wb_is_reg_c_i(reg_d_wb_is_reg_c_id),
		.reg_d_alu_is_reg_a_i(reg_d_alu_is_reg_a_id),
		.reg_d_alu_is_reg_b_i(reg_d_alu_is_reg_b_id),
		.reg_d_alu_is_reg_c_i(reg_d_alu_is_reg_c_id),
		.operand_a_fw_mux_sel_o(operand_a_fw_mux_sel),
		.operand_b_fw_mux_sel_o(operand_b_fw_mux_sel),
		.operand_c_fw_mux_sel_o(operand_c_fw_mux_sel),
		.halt_if_o(halt_if),
		.halt_id_o(halt_id),
		.misaligned_stall_o(misaligned_stall),
		.jr_stall_o(jr_stall),
		.load_stall_o(load_stall),
		.id_ready_i(id_ready_o),
		.id_valid_i(id_valid_o),
		.ex_valid_i(ex_valid_i),
		.wb_ready_i(wb_ready_i),
		.perf_pipeline_stall_o(perf_pipeline_stall)
	);
	cv32e40p_int_controller_gate #(.PULP_SECURE(PULP_SECURE)) int_controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.irq_i(irq_i),
		.irq_sec_i(irq_sec_i),
		.irq_req_ctrl_o(irq_req_ctrl),
		.irq_sec_ctrl_o(irq_sec_ctrl),
		.irq_id_ctrl_o(irq_id_ctrl),
		.irq_wu_ctrl_o(irq_wu_ctrl),
		.mie_bypass_i(mie_bypass_i),
		.mip_o(mip_o),
		.m_ie_i(m_irq_enable_i),
		.u_ie_i(u_irq_enable_i),
		.current_priv_lvl_i(current_priv_lvl_i)
	);
	generate
		if (COREV_PULP) begin : gen_hwloop_regs
			cv32e40p_hwloop_regs_gate #(.N_REGS(N_HWLP)) hwloop_regs_i(
				.clk(clk),
				.rst_n(rst_n),
				.hwlp_start_data_i(hwlp_start),
				.hwlp_end_data_i(hwlp_end),
				.hwlp_cnt_data_i(hwlp_cnt),
				.hwlp_we_i(hwlp_we_masked),
				.hwlp_regid_i(hwlp_regid),
				.valid_i(hwlp_valid),
				.hwlp_start_addr_o(hwlp_start_o),
				.hwlp_end_addr_o(hwlp_end_o),
				.hwlp_counter_o(hwlp_cnt_o),
				.hwlp_dec_cnt_i(hwlp_dec_cnt)
			);
			assign hwlp_valid = instr_valid_i & clear_instr_valid_o;
			assign hwlp_regid = instr[7];
			always @(*) begin
				if (_sv2v_0)
					;
				case (hwlp_target_mux_sel)
					2'b00: hwlp_end = pc_id_i + {imm_iz_type[29:0], 2'b00};
					2'b01: hwlp_end = pc_id_i + {imm_z_type[29:0], 2'b00};
					2'b10: hwlp_end = operand_a_fw_id;
					default: hwlp_end = operand_a_fw_id;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				case (hwlp_start_mux_sel)
					2'b00: hwlp_start = hwlp_end;
					2'b01: hwlp_start = pc_id_i + 4;
					2'b10: hwlp_start = operand_a_fw_id;
					default: hwlp_start = operand_a_fw_id;
				endcase
			end
			always @(*) begin : hwlp_cnt_mux
				if (_sv2v_0)
					;
				case (hwlp_cnt_mux_sel)
					1'b0: hwlp_cnt = imm_iz_type;
					1'b1: hwlp_cnt = operand_a_fw_id;
				endcase
			end
			assign hwlp_we_masked = (hwlp_we & ~{3 {hwlp_mask}}) & {3 {id_ready_o}};
		end
		else begin : gen_no_hwloop_regs
			assign hwlp_start_o = 'b0;
			assign hwlp_end_o = 'b0;
			assign hwlp_cnt_o = 'b0;
			assign hwlp_valid = 'b0;
			assign hwlp_we_masked = 'b0;
			wire [32:1] sv2v_tmp_5AC61;
			assign sv2v_tmp_5AC61 = 'b0;
			always @(*) hwlp_start = sv2v_tmp_5AC61;
			wire [32:1] sv2v_tmp_2B670;
			assign sv2v_tmp_2B670 = 'b0;
			always @(*) hwlp_end = sv2v_tmp_2B670;
			wire [32:1] sv2v_tmp_03706;
			assign sv2v_tmp_03706 = 'b0;
			always @(*) hwlp_cnt = sv2v_tmp_03706;
			assign hwlp_regid = 'b0;
		end
	endgenerate
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	function automatic [6:0] sv2v_cast_C07C4;
		input reg [6:0] inp;
		sv2v_cast_C07C4 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_9F558;
		input reg [2:0] inp;
		sv2v_cast_9F558 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_EB06E;
		input reg [1:0] inp;
		sv2v_cast_EB06E = inp;
	endfunction
	always @(posedge clk or negedge rst_n) begin : ID_EX_PIPE_REGISTERS
		if (rst_n == 1'b0) begin
			alu_en_ex_o <= 1'sb0;
			alu_operator_ex_o <= sv2v_cast_C07C4(7'b0000011);
			alu_operand_a_ex_o <= 1'sb0;
			alu_operand_b_ex_o <= 1'sb0;
			alu_operand_c_ex_o <= 1'sb0;
			bmask_a_ex_o <= 1'sb0;
			bmask_b_ex_o <= 1'sb0;
			imm_vec_ext_ex_o <= 1'sb0;
			alu_vec_mode_ex_o <= 1'sb0;
			alu_clpx_shift_ex_o <= 2'b00;
			alu_is_clpx_ex_o <= 1'b0;
			alu_is_subrot_ex_o <= 1'b0;
			mult_operator_ex_o <= sv2v_cast_9F558(3'b000);
			mult_operand_a_ex_o <= 1'sb0;
			mult_operand_b_ex_o <= 1'sb0;
			mult_operand_c_ex_o <= 1'sb0;
			mult_en_ex_o <= 1'b0;
			mult_sel_subword_ex_o <= 1'b0;
			mult_signed_mode_ex_o <= 2'b00;
			mult_imm_ex_o <= 1'sb0;
			mult_dot_op_a_ex_o <= 1'sb0;
			mult_dot_op_b_ex_o <= 1'sb0;
			mult_dot_op_c_ex_o <= 1'sb0;
			mult_dot_signed_ex_o <= 1'sb0;
			mult_is_clpx_ex_o <= 1'b0;
			mult_clpx_shift_ex_o <= 2'b00;
			mult_clpx_img_ex_o <= 1'b0;
			apu_en_ex_o <= 1'sb0;
			apu_op_ex_o <= 1'sb0;
			apu_lat_ex_o <= 1'sb0;
			apu_operands_ex_o[0+:32] <= 1'sb0;
			apu_operands_ex_o[32+:32] <= 1'sb0;
			apu_operands_ex_o[64+:32] <= 1'sb0;
			apu_flags_ex_o <= 1'sb0;
			apu_waddr_ex_o <= 1'sb0;
			regfile_waddr_ex_o <= 6'b000000;
			regfile_we_ex_o <= 1'b0;
			regfile_alu_waddr_ex_o <= 6'b000000;
			regfile_alu_we_ex_o <= 1'b0;
			prepost_useincr_ex_o <= 1'b0;
			csr_access_ex_o <= 1'b0;
			csr_op_ex_o <= sv2v_cast_EB06E(2'b00);
			data_we_ex_o <= 1'b0;
			data_type_ex_o <= 2'b00;
			data_sign_ext_ex_o <= 2'b00;
			data_reg_offset_ex_o <= 2'b00;
			data_req_ex_o <= 1'b0;
			data_load_event_ex_o <= 1'b0;
			atop_ex_o <= 5'b00000;
			data_misaligned_ex_o <= 1'b0;
			pc_ex_o <= 1'sb0;
			branch_in_ex_o <= 1'b0;
		end
		else if (data_misaligned_i) begin
			if (ex_ready_i) begin
				if (prepost_useincr_ex_o == 1'b1)
					alu_operand_a_ex_o <= operand_a_fw_id;
				alu_operand_b_ex_o <= 32'h00000004;
				regfile_alu_we_ex_o <= 1'b0;
				prepost_useincr_ex_o <= 1'b1;
				data_misaligned_ex_o <= 1'b1;
			end
		end
		else if (mult_multicycle_i)
			mult_operand_c_ex_o <= operand_c_fw_id;
		else if (id_valid_o) begin
			alu_en_ex_o <= alu_en;
			if (alu_en) begin
				alu_operator_ex_o <= alu_operator;
				alu_operand_a_ex_o <= alu_operand_a;
				if ((alu_op_b_mux_sel == cv32e40p_pkg_OP_B_REGB_OR_FWD) && ((alu_operator == sv2v_cast_C07C4(7'b0010110)) || (alu_operator == sv2v_cast_C07C4(7'b0010111))))
					alu_operand_b_ex_o <= {1'b0, alu_operand_b[30:0]};
				else
					alu_operand_b_ex_o <= alu_operand_b;
				alu_operand_c_ex_o <= alu_operand_c;
				bmask_a_ex_o <= bmask_a_id;
				bmask_b_ex_o <= bmask_b_id;
				imm_vec_ext_ex_o <= imm_vec_ext_id;
				alu_vec_mode_ex_o <= alu_vec_mode;
				alu_is_clpx_ex_o <= is_clpx;
				alu_clpx_shift_ex_o <= instr[14:13];
				alu_is_subrot_ex_o <= is_subrot;
			end
			mult_en_ex_o <= mult_en;
			if (mult_int_en) begin
				mult_operator_ex_o <= mult_operator;
				mult_sel_subword_ex_o <= mult_sel_subword;
				mult_signed_mode_ex_o <= mult_signed_mode;
				mult_operand_a_ex_o <= alu_operand_a;
				mult_operand_b_ex_o <= alu_operand_b;
				mult_operand_c_ex_o <= alu_operand_c;
				mult_imm_ex_o <= mult_imm_id;
			end
			if (mult_dot_en) begin
				mult_operator_ex_o <= mult_operator;
				mult_dot_signed_ex_o <= mult_dot_signed;
				mult_dot_op_a_ex_o <= alu_operand_a;
				mult_dot_op_b_ex_o <= alu_operand_b;
				mult_dot_op_c_ex_o <= alu_operand_c;
				mult_is_clpx_ex_o <= is_clpx;
				mult_clpx_shift_ex_o <= instr[14:13];
				mult_clpx_img_ex_o <= instr[25];
			end
			apu_en_ex_o <= apu_en;
			if (apu_en) begin
				apu_op_ex_o <= apu_op;
				apu_lat_ex_o <= apu_lat;
				apu_operands_ex_o <= apu_operands;
				apu_flags_ex_o <= apu_flags;
				apu_waddr_ex_o <= apu_waddr;
			end
			regfile_we_ex_o <= regfile_we_id;
			if (regfile_we_id)
				regfile_waddr_ex_o <= regfile_waddr_id;
			regfile_alu_we_ex_o <= regfile_alu_we_id;
			if (regfile_alu_we_id)
				regfile_alu_waddr_ex_o <= regfile_alu_waddr_id;
			prepost_useincr_ex_o <= prepost_useincr;
			csr_access_ex_o <= csr_access;
			csr_op_ex_o <= csr_op;
			data_req_ex_o <= data_req_id;
			if (data_req_id) begin
				data_we_ex_o <= data_we_id;
				data_type_ex_o <= data_type_id;
				data_sign_ext_ex_o <= data_sign_ext_id;
				data_reg_offset_ex_o <= data_reg_offset_id;
				data_load_event_ex_o <= data_load_event_id;
				atop_ex_o <= atop_id;
			end
			else
				data_load_event_ex_o <= 1'b0;
			data_misaligned_ex_o <= 1'b0;
			if ((ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND) || data_req_id)
				pc_ex_o <= pc_id_i;
			branch_in_ex_o <= ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND;
		end
		else if (ex_ready_i) begin
			regfile_we_ex_o <= 1'b0;
			regfile_alu_we_ex_o <= 1'b0;
			csr_op_ex_o <= sv2v_cast_EB06E(2'b00);
			data_req_ex_o <= 1'b0;
			data_load_event_ex_o <= 1'b0;
			data_misaligned_ex_o <= 1'b0;
			branch_in_ex_o <= 1'b0;
			apu_en_ex_o <= 1'b0;
			alu_operator_ex_o <= sv2v_cast_C07C4(7'b0000011);
			mult_en_ex_o <= 1'b0;
			alu_en_ex_o <= 1'b1;
		end
		else if (csr_access_ex_o)
			regfile_alu_we_ex_o <= 1'b0;
	end
	assign minstret = (id_valid_o && is_decoding_o) && !((illegal_insn_dec || ebrk_insn_dec) || ecall_insn_dec);
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			id_valid_q <= 1'b0;
			mhpmevent_minstret_o <= 1'b0;
			mhpmevent_load_o <= 1'b0;
			mhpmevent_store_o <= 1'b0;
			mhpmevent_jump_o <= 1'b0;
			mhpmevent_branch_o <= 1'b0;
			mhpmevent_compressed_o <= 1'b0;
			mhpmevent_branch_taken_o <= 1'b0;
			mhpmevent_jr_stall_o <= 1'b0;
			mhpmevent_imiss_o <= 1'b0;
			mhpmevent_ld_stall_o <= 1'b0;
			mhpmevent_pipe_stall_o <= 1'b0;
		end
		else begin
			id_valid_q <= id_valid_o;
			mhpmevent_minstret_o <= minstret;
			mhpmevent_load_o <= (minstret && data_req_id) && !data_we_id;
			mhpmevent_store_o <= (minstret && data_req_id) && data_we_id;
			mhpmevent_jump_o <= minstret && ((ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_JAL) || (ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_JALR));
			mhpmevent_branch_o <= minstret && (ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND);
			mhpmevent_compressed_o <= minstret && is_compressed_i;
			mhpmevent_branch_taken_o <= mhpmevent_branch_o && branch_decision_i;
			mhpmevent_imiss_o <= perf_imiss_i;
			mhpmevent_jr_stall_o <= (jr_stall && !halt_id) && id_valid_q;
			mhpmevent_ld_stall_o <= (load_stall && !halt_id) && id_valid_q;
			mhpmevent_pipe_stall_o <= perf_pipeline_stall;
		end
	assign id_ready_o = ((((~misaligned_stall & ~jr_stall) & ~load_stall) & ~apu_stall) & ~csr_apu_stall) & ex_ready_i;
	assign id_valid_o = ~halt_id & id_ready_o;
	assign halt_if_o = halt_if;
	initial _sv2v_0 = 0;
endmodule
