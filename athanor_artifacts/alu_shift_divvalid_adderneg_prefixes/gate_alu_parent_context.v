module cv32e40p_popcnt (
	in_i,
	result_o
);
	input wire [31:0] in_i;
	output wire [5:0] result_o;
	wire [31:0] cnt_l1;
	wire [23:0] cnt_l2;
	wire [15:0] cnt_l3;
	wire [9:0] cnt_l4;
	genvar _gv_l_1;
	genvar _gv_m_1;
	genvar _gv_n_1;
	genvar _gv_p_1;
	generate
		for (_gv_l_1 = 0; _gv_l_1 < 16; _gv_l_1 = _gv_l_1 + 1) begin : gen_cnt_l1
			localparam l = _gv_l_1;
			assign cnt_l1[l * 2+:2] = {1'b0, in_i[2 * l]} + {1'b0, in_i[(2 * l) + 1]};
		end
		for (_gv_m_1 = 0; _gv_m_1 < 8; _gv_m_1 = _gv_m_1 + 1) begin : gen_cnt_l2
			localparam m = _gv_m_1;
			assign cnt_l2[m * 3+:3] = {1'b0, cnt_l1[(2 * m) * 2+:2]} + {1'b0, cnt_l1[((2 * m) + 1) * 2+:2]};
		end
		for (_gv_n_1 = 0; _gv_n_1 < 4; _gv_n_1 = _gv_n_1 + 1) begin : gen_cnt_l3
			localparam n = _gv_n_1;
			assign cnt_l3[n * 4+:4] = {1'b0, cnt_l2[(2 * n) * 3+:3]} + {1'b0, cnt_l2[((2 * n) + 1) * 3+:3]};
		end
		for (_gv_p_1 = 0; _gv_p_1 < 2; _gv_p_1 = _gv_p_1 + 1) begin : gen_cnt_l4
			localparam p = _gv_p_1;
			assign cnt_l4[p * 5+:5] = {1'b0, cnt_l3[(2 * p) * 4+:4]} + {1'b0, cnt_l3[((2 * p) + 1) * 4+:4]};
		end
	endgenerate
	assign result_o = {1'b0, cnt_l4[0+:5]} + {1'b0, cnt_l4[5+:5]};
endmodule
module cv32e40p_ff_one (
	in_i,
	first_one_o,
	no_ones_o
);
	parameter LEN = 32;
	input wire [LEN - 1:0] in_i;
	output wire [$clog2(LEN) - 1:0] first_one_o;
	output wire no_ones_o;
	localparam NUM_LEVELS = $clog2(LEN);
	wire [(LEN * NUM_LEVELS) - 1:0] index_lut;
	wire [(2 ** NUM_LEVELS) - 1:0] sel_nodes;
	wire [((2 ** NUM_LEVELS) * NUM_LEVELS) - 1:0] index_nodes;
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 0; _gv_j_1 < LEN; _gv_j_1 = _gv_j_1 + 1) begin : gen_index_lut
			localparam j = _gv_j_1;
			assign index_lut[j * NUM_LEVELS+:NUM_LEVELS] = $unsigned(j);
		end
	endgenerate
	genvar _gv_k_1;
	genvar _gv_l_2;
	genvar _gv_level_1;
	assign sel_nodes[(2 ** NUM_LEVELS) - 1] = 1'b0;
	generate
		for (_gv_level_1 = 0; _gv_level_1 < NUM_LEVELS; _gv_level_1 = _gv_level_1 + 1) begin : gen_tree
			localparam level = _gv_level_1;
			if (level < (NUM_LEVELS - 1)) begin : gen_non_root_level
				for (_gv_l_2 = 0; _gv_l_2 < (2 ** level); _gv_l_2 = _gv_l_2 + 1) begin : gen_node
					localparam l = _gv_l_2;
					assign sel_nodes[((2 ** level) - 1) + l] = sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] | sel_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) + 1];
					assign index_nodes[(((2 ** level) - 1) + l) * NUM_LEVELS+:NUM_LEVELS] = (sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] == 1'b1 ? index_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) * NUM_LEVELS+:NUM_LEVELS] : index_nodes[((((2 ** (level + 1)) - 1) + (l * 2)) + 1) * NUM_LEVELS+:NUM_LEVELS]);
				end
			end
			if (level == (NUM_LEVELS - 1)) begin : gen_root_level
				for (_gv_k_1 = 0; _gv_k_1 < (2 ** level); _gv_k_1 = _gv_k_1 + 1) begin : gen_node
					localparam k = _gv_k_1;
					if ((k * 2) < (LEN - 1)) begin : gen_two
						assign sel_nodes[((2 ** level) - 1) + k] = in_i[k * 2] | in_i[(k * 2) + 1];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = (in_i[k * 2] == 1'b1 ? index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS] : index_lut[((k * 2) + 1) * NUM_LEVELS+:NUM_LEVELS]);
					end
					if ((k * 2) == (LEN - 1)) begin : gen_one
						assign sel_nodes[((2 ** level) - 1) + k] = in_i[k * 2];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS];
					end
					if ((k * 2) > (LEN - 1)) begin : gen_out_of_range
						assign sel_nodes[((2 ** level) - 1) + k] = 1'b0;
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = 1'sb0;
					end
				end
			end
		end
	endgenerate
	assign first_one_o = index_nodes[0+:NUM_LEVELS];
	assign no_ones_o = ~sel_nodes[0];
endmodule
module cv32e40p_alu_div (
	Clk_CI,
	Rst_RBI,
	OpA_DI,
	OpB_DI,
	OpBShift_DI,
	OpBIsZero_SI,
	OpBSign_SI,
	OpCode_SI,
	InVld_SI,
	OutRdy_SI,
	OutVld_SO,
	Res_DO
);
	reg _sv2v_0;
	parameter C_WIDTH = 32;
	parameter C_LOG_WIDTH = 6;
	input wire Clk_CI;
	input wire Rst_RBI;
	input wire [C_WIDTH - 1:0] OpA_DI;
	input wire [C_WIDTH - 1:0] OpB_DI;
	input wire [C_LOG_WIDTH - 1:0] OpBShift_DI;
	input wire OpBIsZero_SI;
	input wire OpBSign_SI;
	input wire [1:0] OpCode_SI;
	input wire InVld_SI;
	input wire OutRdy_SI;
	output reg OutVld_SO;
	output wire [C_WIDTH - 1:0] Res_DO;
	reg [C_WIDTH - 1:0] ResReg_DP;
	wire [C_WIDTH - 1:0] ResReg_DN;
	wire [C_WIDTH - 1:0] ResReg_DP_rev;
	reg [C_WIDTH - 1:0] AReg_DP;
	wire [C_WIDTH - 1:0] AReg_DN;
	reg [C_WIDTH - 1:0] BReg_DP;
	wire [C_WIDTH - 1:0] BReg_DN;
	wire RemSel_SN;
	reg RemSel_SP;
	wire CompInv_SN;
	reg CompInv_SP;
	wire ResInv_SN;
	reg ResInv_SP;
	wire [C_WIDTH - 1:0] AddMux_D;
	wire [C_WIDTH - 1:0] AddOut_D;
	wire [C_WIDTH - 1:0] AddTmp_D;
	wire [C_WIDTH - 1:0] BMux_D;
	wire [C_WIDTH - 1:0] OutMux_D;
	reg [C_LOG_WIDTH - 1:0] Cnt_DP;
	wire [C_LOG_WIDTH - 1:0] Cnt_DN;
	wire CntZero_S;
	reg ARegEn_S;
	reg BRegEn_S;
	reg ResRegEn_S;
	wire ABComp_S;
	wire PmSel_S;
	reg LoadEn_S;
	reg [1:0] State_SN;
	reg [1:0] State_SP;
	assign PmSel_S = LoadEn_S & ~(OpCode_SI[0] & (OpA_DI[C_WIDTH - 1] ^ OpBSign_SI));
	assign AddMux_D = (LoadEn_S ? OpA_DI : BReg_DP);
	assign BMux_D = (LoadEn_S ? OpB_DI : {CompInv_SP, BReg_DP[C_WIDTH - 1:1]});
	genvar _gv_index_1;
	generate
		for (_gv_index_1 = 0; _gv_index_1 < C_WIDTH; _gv_index_1 = _gv_index_1 + 1) begin : gen_bit_swapping
			localparam index = _gv_index_1;
			assign ResReg_DP_rev[index] = ResReg_DP[(C_WIDTH - 1) - index];
		end
	endgenerate
	assign OutMux_D = (RemSel_SP ? AReg_DP : ResReg_DP_rev);
	assign Res_DO = (ResInv_SP ? -$signed(OutMux_D) : OutMux_D);
	assign ABComp_S = ((AReg_DP == BReg_DP) | ((AReg_DP > BReg_DP) ^ CompInv_SP)) & (|AReg_DP | OpBIsZero_SI);
	assign AddTmp_D = (LoadEn_S ? 0 : AReg_DP);
	assign AddOut_D = (PmSel_S ? AddTmp_D + AddMux_D : AddTmp_D - $signed(AddMux_D));
	assign Cnt_DN = (LoadEn_S ? OpBShift_DI : (~CntZero_S ? Cnt_DP - 1 : Cnt_DP));
	assign CntZero_S = ~(|Cnt_DP);
	always @(*) begin : p_fsm
		if (_sv2v_0)
			;
		State_SN = State_SP;
		OutVld_SO = 1'b0;
		LoadEn_S = 1'b0;
		ARegEn_S = 1'b0;
		BRegEn_S = 1'b0;
		ResRegEn_S = 1'b0;
		case (State_SP)
			2'd0: begin
				OutVld_SO = 1'b1;
				if (InVld_SI) begin
					OutVld_SO = 1'b0;
					ARegEn_S = 1'b1;
					BRegEn_S = 1'b1;
					LoadEn_S = 1'b1;
					State_SN = 2'd1;
				end
			end
			2'd1: begin
				ARegEn_S = ABComp_S;
				BRegEn_S = 1'b1;
				ResRegEn_S = 1'b1;
				if (CntZero_S)
					State_SN = 2'd2;
			end
			2'd2: begin
				OutVld_SO = 1'b1;
				if (OutRdy_SI)
					State_SN = 2'd0;
			end
			default:
				;
		endcase
	end
	assign RemSel_SN = (LoadEn_S ? OpCode_SI[1] : RemSel_SP);
	assign CompInv_SN = (LoadEn_S ? OpBSign_SI : CompInv_SP);
	assign ResInv_SN = (LoadEn_S ? ((~OpBIsZero_SI | OpCode_SI[1]) & OpCode_SI[0]) & (OpA_DI[C_WIDTH - 1] ^ OpBSign_SI) : ResInv_SP);
	assign AReg_DN = (ARegEn_S ? AddOut_D : AReg_DP);
	assign BReg_DN = (BRegEn_S ? BMux_D : BReg_DP);
	assign ResReg_DN = (LoadEn_S ? {C_WIDTH {1'sb0}} : (ResRegEn_S ? {ABComp_S, ResReg_DP[C_WIDTH - 1:1]} : ResReg_DP));
	always @(posedge Clk_CI or negedge Rst_RBI) begin : p_regs
		if (~Rst_RBI) begin
			State_SP <= 2'd0;
			AReg_DP <= 1'sb0;
			BReg_DP <= 1'sb0;
			ResReg_DP <= 1'sb0;
			Cnt_DP <= 1'sb0;
			RemSel_SP <= 1'b0;
			CompInv_SP <= 1'b0;
			ResInv_SP <= 1'b0;
		end
		else begin
			State_SP <= State_SN;
			AReg_DP <= AReg_DN;
			BReg_DP <= BReg_DN;
			ResReg_DP <= ResReg_DN;
			Cnt_DP <= Cnt_DN;
			RemSel_SP <= RemSel_SN;
			CompInv_SP <= CompInv_SN;
			ResInv_SP <= ResInv_SN;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_alu (
	clk,
	rst_n,
	enable_i,
	operator_i,
	operand_a_i,
	operand_b_i,
	operand_c_i,
	vector_mode_i,
	bmask_a_i,
	bmask_b_i,
	imm_vec_ext_i,
	is_clpx_i,
	is_subrot_i,
	clpx_shift_i,
	result_o,
	comparison_result_o,
	ready_o,
	ex_ready_i
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire enable_i;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	input wire [6:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire [31:0] operand_c_i;
	input wire [1:0] vector_mode_i;
	input wire [4:0] bmask_a_i;
	input wire [4:0] bmask_b_i;
	input wire [1:0] imm_vec_ext_i;
	input wire is_clpx_i;
	input wire is_subrot_i;
	input wire [1:0] clpx_shift_i;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire ready_o;
	input wire ex_ready_i;
	wire [31:0] operand_a_rev;
	wire [31:0] operand_a_neg;
	wire [31:0] operand_a_neg_rev;
	assign operand_a_neg = ~operand_a_i;
	genvar _gv_k_2;
	generate
		for (_gv_k_2 = 0; _gv_k_2 < 32; _gv_k_2 = _gv_k_2 + 1) begin : gen_operand_a_rev
			localparam k = _gv_k_2;
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	genvar _gv_m_2;
	generate
		for (_gv_m_2 = 0; _gv_m_2 < 32; _gv_m_2 = _gv_m_2 + 1) begin : gen_operand_a_neg_rev
			localparam m = _gv_m_2;
			assign operand_a_neg_rev[m] = operand_a_neg[31 - m];
		end
	endgenerate
	wire [31:0] operand_b_neg;
	assign operand_b_neg = ~operand_b_i;
	wire [5:0] div_shift;
	wire div_valid;
	wire [31:0] bmask;
	wire adder_op_b_negate;
	wire [31:0] adder_op_a;
	wire [31:0] adder_op_b;
	reg [35:0] adder_in_a;
	reg [35:0] adder_in_b;
	wire [31:0] adder_result;
	wire [36:0] adder_result_expanded;
	assign adder_op_b_negate = ((operator_i[6:3] == 4'b0011) & operator_i[0]) | is_subrot_i;
	function automatic [6:0] sv2v_cast_C07C4;
		input reg [6:0] inp;
		sv2v_cast_C07C4 = inp;
	endfunction
	assign adder_op_a = (operator_i == sv2v_cast_C07C4(7'b0010100) ? operand_a_neg : (is_subrot_i ? {operand_b_i[15:0], operand_a_i[31:16]} : operand_a_i));
	assign adder_op_b = (adder_op_b_negate ? (is_subrot_i ? ~{operand_a_i[15:0], operand_b_i[31:16]} : operand_b_neg) : operand_b_i);
	localparam cv32e40p_pkg_VEC_MODE16 = 2'b10;
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		adder_in_a[0] = 1'b1;
		adder_in_a[8:1] = adder_op_a[7:0];
		adder_in_a[9] = 1'b1;
		adder_in_a[17:10] = adder_op_a[15:8];
		adder_in_a[18] = 1'b1;
		adder_in_a[26:19] = adder_op_a[23:16];
		adder_in_a[27] = 1'b1;
		adder_in_a[35:28] = adder_op_a[31:24];
		adder_in_b[0] = 1'b0;
		adder_in_b[8:1] = adder_op_b[7:0];
		adder_in_b[9] = 1'b0;
		adder_in_b[17:10] = adder_op_b[15:8];
		adder_in_b[18] = 1'b0;
		adder_in_b[26:19] = adder_op_b[23:16];
		adder_in_b[27] = 1'b0;
		adder_in_b[35:28] = adder_op_b[31:24];
		if (adder_op_b_negate || ((operator_i == sv2v_cast_C07C4(7'b0010100)) || (operator_i == sv2v_cast_C07C4(7'b0010110)))) begin
			adder_in_b[0] = 1'b1;
			case (vector_mode_i)
				cv32e40p_pkg_VEC_MODE16: adder_in_b[18] = 1'b1;
				cv32e40p_pkg_VEC_MODE8: begin
					adder_in_b[9] = 1'b1;
					adder_in_b[18] = 1'b1;
					adder_in_b[27] = 1'b1;
				end
			endcase
		end
		else
			case (vector_mode_i)
				cv32e40p_pkg_VEC_MODE16: adder_in_a[18] = 1'b0;
				cv32e40p_pkg_VEC_MODE8: begin
					adder_in_a[9] = 1'b0;
					adder_in_a[18] = 1'b0;
					adder_in_a[27] = 1'b0;
				end
			endcase
	end
	assign adder_result_expanded = $signed(adder_in_a) + $signed(adder_in_b);
	assign adder_result = {adder_result_expanded[35:28], adder_result_expanded[26:19], adder_result_expanded[17:10], adder_result_expanded[8:1]};
	wire [31:0] adder_round_value;
	wire [31:0] adder_round_result;
	assign adder_round_value = ((((operator_i == sv2v_cast_C07C4(7'b0011100)) || (operator_i == sv2v_cast_C07C4(7'b0011101))) || (operator_i == sv2v_cast_C07C4(7'b0011110))) || (operator_i == sv2v_cast_C07C4(7'b0011111)) ? {1'b0, bmask[31:1]} : {32 {1'sb0}});
	assign adder_round_result = adder_result + adder_round_value;
	wire shift_left;
	wire shift_use_round;
	wire shift_arithmetic;
	reg [31:0] shift_amt_left;
	wire [31:0] shift_amt;
	wire [31:0] shift_amt_int;
	wire [31:0] shift_amt_norm;
	wire [31:0] shift_op_a;
	wire [31:0] shift_result;
	reg [31:0] shift_right_result;
	wire [31:0] shift_left_result;
	wire [15:0] clpx_shift_ex;
	assign shift_amt = (div_valid ? div_shift : operand_b_i);
	always @(*) begin
		if (_sv2v_0)
			;
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				shift_amt_left[15:0] = shift_amt[31:16];
				shift_amt_left[31:16] = shift_amt[15:0];
			end
			cv32e40p_pkg_VEC_MODE8: begin
				shift_amt_left[7:0] = shift_amt[31:24];
				shift_amt_left[15:8] = shift_amt[23:16];
				shift_amt_left[23:16] = shift_amt[15:8];
				shift_amt_left[31:24] = shift_amt[7:0];
			end
			default: shift_amt_left[31:0] = shift_amt[31:0];
		endcase
	end
	assign shift_left = (((((operator_i == sv2v_cast_C07C4(7'b0100111)) || (operator_i == sv2v_cast_C07C4(7'b0101010))) || (operator_i == sv2v_cast_C07C4(7'b0110111))) || (operator_i == sv2v_cast_C07C4(7'b0110101))) || (operator_i[6:2] == 5'b01100)) || (operator_i == sv2v_cast_C07C4(7'b1001001));
	assign shift_use_round = (((((((operator_i == sv2v_cast_C07C4(7'b0011000)) || (operator_i == sv2v_cast_C07C4(7'b0011001))) || (operator_i == sv2v_cast_C07C4(7'b0011100))) || (operator_i == sv2v_cast_C07C4(7'b0011101))) || (operator_i == sv2v_cast_C07C4(7'b0011010))) || (operator_i == sv2v_cast_C07C4(7'b0011011))) || (operator_i == sv2v_cast_C07C4(7'b0011110))) || (operator_i == sv2v_cast_C07C4(7'b0011111));
	assign shift_arithmetic = (((((operator_i == sv2v_cast_C07C4(7'b0100100)) || (operator_i == sv2v_cast_C07C4(7'b0101000))) || (operator_i == sv2v_cast_C07C4(7'b0011000))) || (operator_i == sv2v_cast_C07C4(7'b0011001))) || (operator_i == sv2v_cast_C07C4(7'b0011100))) || (operator_i == sv2v_cast_C07C4(7'b0011101));
	assign shift_op_a = (shift_left ? operand_a_rev : (shift_use_round ? adder_round_result : operand_a_i));
	assign shift_amt_int = (shift_use_round ? shift_amt_norm : (shift_left ? shift_amt_left : shift_amt));
	assign shift_amt_norm = (is_clpx_i ? {clpx_shift_ex, clpx_shift_ex} : {4 {3'b000, bmask_b_i}});
	assign clpx_shift_ex = $unsigned(clpx_shift_i);
	wire [63:0] shift_op_a_32;
	assign shift_op_a_32 = (operator_i == sv2v_cast_C07C4(7'b0100110) ? {shift_op_a, shift_op_a} : $signed({{32 {shift_arithmetic & shift_op_a[31]}}, shift_op_a}));
	always @(*) begin
		if (_sv2v_0)
			;
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				shift_right_result[31:16] = $signed({shift_arithmetic & shift_op_a[31], shift_op_a[31:16]}) >>> shift_amt_int[19:16];
				shift_right_result[15:0] = $signed({shift_arithmetic & shift_op_a[15], shift_op_a[15:0]}) >>> shift_amt_int[3:0];
			end
			cv32e40p_pkg_VEC_MODE8: begin
				shift_right_result[31:24] = $signed({shift_arithmetic & shift_op_a[31], shift_op_a[31:24]}) >>> shift_amt_int[26:24];
				shift_right_result[23:16] = $signed({shift_arithmetic & shift_op_a[23], shift_op_a[23:16]}) >>> shift_amt_int[18:16];
				shift_right_result[15:8] = $signed({shift_arithmetic & shift_op_a[15], shift_op_a[15:8]}) >>> shift_amt_int[10:8];
				shift_right_result[7:0] = $signed({shift_arithmetic & shift_op_a[7], shift_op_a[7:0]}) >>> shift_amt_int[2:0];
			end
			default: shift_right_result = shift_op_a_32 >> shift_amt_int[4:0];
		endcase
	end
	genvar _gv_j_2;
	generate
		for (_gv_j_2 = 0; _gv_j_2 < 32; _gv_j_2 = _gv_j_2 + 1) begin : gen_shift_left_result
			localparam j = _gv_j_2;
			assign shift_left_result[j] = shift_right_result[31 - j];
		end
	endgenerate
	assign shift_result = (shift_left ? shift_left_result : shift_right_result);
	reg [3:0] is_equal;
	reg [3:0] is_greater;
	reg [3:0] cmp_signed;
	wire [3:0] is_equal_vec;
	wire [3:0] is_greater_vec;
	reg [31:0] operand_b_eq;
	wire is_equal_clip;
	always @(*) begin
		if (_sv2v_0)
			;
		operand_b_eq = operand_b_neg;
		if (operator_i == sv2v_cast_C07C4(7'b0010111))
			operand_b_eq = 1'sb0;
		else
			operand_b_eq = operand_b_neg;
	end
	assign is_equal_clip = operand_a_i == operand_b_eq;
	always @(*) begin
		if (_sv2v_0)
			;
		cmp_signed = 4'b0000;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_C07C4(7'b0001000), sv2v_cast_C07C4(7'b0001010), sv2v_cast_C07C4(7'b0000000), sv2v_cast_C07C4(7'b0000100), sv2v_cast_C07C4(7'b0000010), sv2v_cast_C07C4(7'b0000110), sv2v_cast_C07C4(7'b0010000), sv2v_cast_C07C4(7'b0010010), sv2v_cast_C07C4(7'b0010100), sv2v_cast_C07C4(7'b0010110), sv2v_cast_C07C4(7'b0010111):
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: cmp_signed[3:0] = 4'b1111;
					cv32e40p_pkg_VEC_MODE16: cmp_signed[3:0] = 4'b1010;
					default: cmp_signed[3:0] = 4'b1000;
				endcase
			default:
				;
		endcase
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 4; _gv_i_1 = _gv_i_1 + 1) begin : gen_is_vec
			localparam i = _gv_i_1;
			assign is_equal_vec[i] = operand_a_i[(8 * i) + 7:8 * i] == operand_b_i[(8 * i) + 7:i * 8];
			assign is_greater_vec[i] = $signed({operand_a_i[(8 * i) + 7] & cmp_signed[i], operand_a_i[(8 * i) + 7:8 * i]}) > $signed({operand_b_i[(8 * i) + 7] & cmp_signed[i], operand_b_i[(8 * i) + 7:i * 8]});
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		is_equal[3:0] = {4 {((is_equal_vec[3] & is_equal_vec[2]) & is_equal_vec[1]) & is_equal_vec[0]}};
		is_greater[3:0] = {4 {is_greater_vec[3] | (is_equal_vec[3] & (is_greater_vec[2] | (is_equal_vec[2] & (is_greater_vec[1] | (is_equal_vec[1] & is_greater_vec[0])))))}};
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				is_equal[1:0] = {2 {is_equal_vec[0] & is_equal_vec[1]}};
				is_equal[3:2] = {2 {is_equal_vec[2] & is_equal_vec[3]}};
				is_greater[1:0] = {2 {is_greater_vec[1] | (is_equal_vec[1] & is_greater_vec[0])}};
				is_greater[3:2] = {2 {is_greater_vec[3] | (is_equal_vec[3] & is_greater_vec[2])}};
			end
			cv32e40p_pkg_VEC_MODE8: begin
				is_equal[3:0] = is_equal_vec[3:0];
				is_greater[3:0] = is_greater_vec[3:0];
			end
			default:
				;
		endcase
	end
	reg [3:0] cmp_result;
	always @(*) begin
		if (_sv2v_0)
			;
		cmp_result = is_equal;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_C07C4(7'b0001100): cmp_result = is_equal;
			sv2v_cast_C07C4(7'b0001101): cmp_result = ~is_equal;
			sv2v_cast_C07C4(7'b0001000), sv2v_cast_C07C4(7'b0001001): cmp_result = is_greater;
			sv2v_cast_C07C4(7'b0001010), sv2v_cast_C07C4(7'b0001011): cmp_result = is_greater | is_equal;
			sv2v_cast_C07C4(7'b0000000), sv2v_cast_C07C4(7'b0000010), sv2v_cast_C07C4(7'b0000001), sv2v_cast_C07C4(7'b0000011): cmp_result = ~(is_greater | is_equal);
			sv2v_cast_C07C4(7'b0000110), sv2v_cast_C07C4(7'b0000111), sv2v_cast_C07C4(7'b0000100), sv2v_cast_C07C4(7'b0000101): cmp_result = ~is_greater;
			default:
				;
		endcase
	end
	assign comparison_result_o = cmp_result[3];
	wire [31:0] result_minmax;
	wire [3:0] sel_minmax;
	wire do_min;
	wire [31:0] minmax_b;
	assign minmax_b = (operator_i == sv2v_cast_C07C4(7'b0010100) ? adder_result : operand_b_i);
	assign do_min = (((operator_i == sv2v_cast_C07C4(7'b0010000)) || (operator_i == sv2v_cast_C07C4(7'b0010001))) || (operator_i == sv2v_cast_C07C4(7'b0010110))) || (operator_i == sv2v_cast_C07C4(7'b0010111));
	assign sel_minmax[3:0] = is_greater ^ {4 {do_min}};
	assign result_minmax[31:24] = (sel_minmax[3] == 1'b1 ? operand_a_i[31:24] : minmax_b[31:24]);
	assign result_minmax[23:16] = (sel_minmax[2] == 1'b1 ? operand_a_i[23:16] : minmax_b[23:16]);
	assign result_minmax[15:8] = (sel_minmax[1] == 1'b1 ? operand_a_i[15:8] : minmax_b[15:8]);
	assign result_minmax[7:0] = (sel_minmax[0] == 1'b1 ? operand_a_i[7:0] : minmax_b[7:0]);
	reg [31:0] clip_result;
	always @(*) begin
		if (_sv2v_0)
			;
		clip_result = result_minmax;
		if (operator_i == sv2v_cast_C07C4(7'b0010111)) begin
			if (operand_a_i[31] || is_equal_clip)
				clip_result = 1'sb0;
			else
				clip_result = result_minmax;
		end
		else if (adder_result_expanded[36] || is_equal_clip)
			clip_result = operand_b_neg;
		else
			clip_result = result_minmax;
	end
	reg [7:0] shuffle_byte_sel;
	reg [3:0] shuffle_reg_sel;
	reg [1:0] shuffle_reg1_sel;
	reg [1:0] shuffle_reg0_sel;
	reg [3:0] shuffle_through;
	wire [31:0] shuffle_r1;
	wire [31:0] shuffle_r0;
	wire [31:0] shuffle_r1_in;
	wire [31:0] shuffle_r0_in;
	wire [31:0] shuffle_result;
	wire [31:0] pack_result;
	always @(*) begin
		if (_sv2v_0)
			;
		shuffle_reg_sel = 1'sb0;
		shuffle_reg1_sel = 2'b01;
		shuffle_reg0_sel = 2'b10;
		shuffle_through = 1'sb1;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_C07C4(7'b0111111), sv2v_cast_C07C4(7'b0111110): begin
				if (operator_i == sv2v_cast_C07C4(7'b0111110))
					shuffle_reg1_sel = 2'b11;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_reg_sel[3:1] = 3'b111;
					shuffle_reg_sel[0] = 1'b0;
				end
				else begin
					shuffle_reg_sel[3:2] = 2'b11;
					shuffle_reg_sel[1:0] = 2'b00;
				end
			end
			sv2v_cast_C07C4(7'b0111000): begin
				shuffle_reg1_sel = 2'b00;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_through = 4'b0011;
					shuffle_reg_sel = 4'b0001;
				end
				else
					shuffle_reg_sel = 4'b0011;
			end
			sv2v_cast_C07C4(7'b0111001): begin
				shuffle_reg1_sel = 2'b00;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_through = 4'b1100;
					shuffle_reg_sel = 4'b0100;
				end
				else
					shuffle_reg_sel = 4'b0011;
			end
			sv2v_cast_C07C4(7'b0111011):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_reg_sel[3] = ~operand_b_i[26];
						shuffle_reg_sel[2] = ~operand_b_i[18];
						shuffle_reg_sel[1] = ~operand_b_i[10];
						shuffle_reg_sel[0] = ~operand_b_i[2];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_reg_sel[3] = ~operand_b_i[17];
						shuffle_reg_sel[2] = ~operand_b_i[17];
						shuffle_reg_sel[1] = ~operand_b_i[1];
						shuffle_reg_sel[0] = ~operand_b_i[1];
					end
					default:
						;
				endcase
			sv2v_cast_C07C4(7'b0101101):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_reg0_sel = 2'b00;
						(* full_case, parallel_case *)
						case (imm_vec_ext_i)
							2'b00: shuffle_reg_sel[3:0] = 4'b1110;
							2'b01: shuffle_reg_sel[3:0] = 4'b1101;
							2'b10: shuffle_reg_sel[3:0] = 4'b1011;
							2'b11: shuffle_reg_sel[3:0] = 4'b0111;
						endcase
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_reg0_sel = 2'b01;
						shuffle_reg_sel[3] = ~imm_vec_ext_i[0];
						shuffle_reg_sel[2] = ~imm_vec_ext_i[0];
						shuffle_reg_sel[1] = imm_vec_ext_i[0];
						shuffle_reg_sel[0] = imm_vec_ext_i[0];
					end
					default:
						;
				endcase
			default:
				;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		shuffle_byte_sel = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_C07C4(7'b0111110), sv2v_cast_C07C4(7'b0111111):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[4+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[2+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[0+:2] = imm_vec_ext_i[1:0];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[4+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[2+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[0+:2] = {imm_vec_ext_i[0], 1'b0};
					end
					default:
						;
				endcase
			sv2v_cast_C07C4(7'b0111000):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = 2'b00;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b00;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = 2'b01;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b01;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					default:
						;
				endcase
			sv2v_cast_C07C4(7'b0111001):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = 2'b00;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b00;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = 2'b11;
						shuffle_byte_sel[4+:2] = 2'b10;
						shuffle_byte_sel[2+:2] = 2'b11;
						shuffle_byte_sel[0+:2] = 2'b10;
					end
					default:
						;
				endcase
			sv2v_cast_C07C4(7'b0111011), sv2v_cast_C07C4(7'b0111010):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = operand_b_i[25:24];
						shuffle_byte_sel[4+:2] = operand_b_i[17:16];
						shuffle_byte_sel[2+:2] = operand_b_i[9:8];
						shuffle_byte_sel[0+:2] = operand_b_i[1:0];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = {operand_b_i[16], 1'b1};
						shuffle_byte_sel[4+:2] = {operand_b_i[16], 1'b0};
						shuffle_byte_sel[2+:2] = {operand_b_i[0], 1'b1};
						shuffle_byte_sel[0+:2] = {operand_b_i[0], 1'b0};
					end
					default:
						;
				endcase
			sv2v_cast_C07C4(7'b0101101): begin
				shuffle_byte_sel[6+:2] = 2'b11;
				shuffle_byte_sel[4+:2] = 2'b10;
				shuffle_byte_sel[2+:2] = 2'b01;
				shuffle_byte_sel[0+:2] = 2'b00;
			end
			default:
				;
		endcase
	end
	assign shuffle_r0_in = (shuffle_reg0_sel[1] ? operand_a_i : (shuffle_reg0_sel[0] ? {2 {operand_a_i[15:0]}} : {4 {operand_a_i[7:0]}}));
	assign shuffle_r1_in = (shuffle_reg1_sel[1] ? {{8 {operand_a_i[31]}}, {8 {operand_a_i[23]}}, {8 {operand_a_i[15]}}, {8 {operand_a_i[7]}}} : (shuffle_reg1_sel[0] ? operand_c_i : operand_b_i));
	assign shuffle_r0[31:24] = (shuffle_byte_sel[7] ? (shuffle_byte_sel[6] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[6] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[23:16] = (shuffle_byte_sel[5] ? (shuffle_byte_sel[4] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[4] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[15:8] = (shuffle_byte_sel[3] ? (shuffle_byte_sel[2] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[2] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[7:0] = (shuffle_byte_sel[1] ? (shuffle_byte_sel[0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[0] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r1[31:24] = (shuffle_byte_sel[7] ? (shuffle_byte_sel[6] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[6] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[23:16] = (shuffle_byte_sel[5] ? (shuffle_byte_sel[4] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[4] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[15:8] = (shuffle_byte_sel[3] ? (shuffle_byte_sel[2] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[2] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[7:0] = (shuffle_byte_sel[1] ? (shuffle_byte_sel[0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[0] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_result[31:24] = (shuffle_reg_sel[3] ? shuffle_r1[31:24] : shuffle_r0[31:24]);
	assign shuffle_result[23:16] = (shuffle_reg_sel[2] ? shuffle_r1[23:16] : shuffle_r0[23:16]);
	assign shuffle_result[15:8] = (shuffle_reg_sel[1] ? shuffle_r1[15:8] : shuffle_r0[15:8]);
	assign shuffle_result[7:0] = (shuffle_reg_sel[0] ? shuffle_r1[7:0] : shuffle_r0[7:0]);
	assign pack_result[31:24] = (shuffle_through[3] ? shuffle_result[31:24] : operand_c_i[31:24]);
	assign pack_result[23:16] = (shuffle_through[2] ? shuffle_result[23:16] : operand_c_i[23:16]);
	assign pack_result[15:8] = (shuffle_through[1] ? shuffle_result[15:8] : operand_c_i[15:8]);
	assign pack_result[7:0] = (shuffle_through[0] ? shuffle_result[7:0] : operand_c_i[7:0]);
	reg [31:0] ff_input;
	wire [5:0] cnt_result;
	wire [5:0] clb_result;
	wire [4:0] ff1_result;
	wire ff_no_one;
	wire [4:0] fl1_result;
	reg [5:0] bitop_result;
	cv32e40p_popcnt popcnt_i(
		.in_i(operand_a_i),
		.result_o(cnt_result)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		ff_input = 1'sb0;
		case (operator_i)
			sv2v_cast_C07C4(7'b0110110): ff_input = operand_a_i;
			sv2v_cast_C07C4(7'b0110000), sv2v_cast_C07C4(7'b0110010), sv2v_cast_C07C4(7'b0110111): ff_input = operand_a_rev;
			sv2v_cast_C07C4(7'b0110001), sv2v_cast_C07C4(7'b0110011), sv2v_cast_C07C4(7'b0110101):
				if (operand_a_i[31])
					ff_input = operand_a_neg_rev;
				else
					ff_input = operand_a_rev;
		endcase
	end
	cv32e40p_ff_one ff_one_i(
		.in_i(ff_input),
		.first_one_o(ff1_result),
		.no_ones_o(ff_no_one)
	);
	assign fl1_result = 5'd31 - ff1_result;
	assign clb_result = ff1_result - 5'd1;
	always @(*) begin
		if (_sv2v_0)
			;
		bitop_result = 1'sb0;
		case (operator_i)
			sv2v_cast_C07C4(7'b0110110): bitop_result = (ff_no_one ? 6'd32 : {1'b0, ff1_result});
			sv2v_cast_C07C4(7'b0110111): bitop_result = (ff_no_one ? 6'd32 : {1'b0, fl1_result});
			sv2v_cast_C07C4(7'b0110100): bitop_result = cnt_result;
			sv2v_cast_C07C4(7'b0110101):
				if (ff_no_one) begin
					if (operand_a_i[31])
						bitop_result = 6'd31;
					else
						bitop_result = 1'sb0;
				end
				else
					bitop_result = clb_result;
			default:
				;
		endcase
	end
	wire extract_is_signed;
	wire extract_sign;
	wire [31:0] bmask_first;
	wire [31:0] bmask_inv;
	wire [31:0] bextins_and;
	wire [31:0] bextins_result;
	wire [31:0] bclr_result;
	wire [31:0] bset_result;
	assign bmask_first = 32'hfffffffe << bmask_a_i;
	assign bmask = ~bmask_first << bmask_b_i;
	assign bmask_inv = ~bmask;
	assign bextins_and = (operator_i == sv2v_cast_C07C4(7'b0101010) ? operand_c_i : {32 {extract_sign}});
	assign extract_is_signed = operator_i == sv2v_cast_C07C4(7'b0101000);
	assign extract_sign = extract_is_signed & shift_result[bmask_a_i];
	assign bextins_result = (bmask & shift_result) | (bextins_and & bmask_inv);
	assign bclr_result = operand_a_i & bmask_inv;
	assign bset_result = operand_a_i | bmask;
	wire [31:0] radix_2_rev;
	wire [31:0] radix_4_rev;
	wire [31:0] radix_8_rev;
	reg [31:0] reverse_result;
	wire [1:0] radix_mux_sel;
	assign radix_mux_sel = bmask_a_i[1:0];
	generate
		for (_gv_j_2 = 0; _gv_j_2 < 32; _gv_j_2 = _gv_j_2 + 1) begin : gen_radix_2_rev
			localparam j = _gv_j_2;
			assign radix_2_rev[j] = shift_result[31 - j];
		end
		for (_gv_j_2 = 0; _gv_j_2 < 16; _gv_j_2 = _gv_j_2 + 1) begin : gen_radix_4_rev
			localparam j = _gv_j_2;
			assign radix_4_rev[(2 * j) + 1:2 * j] = shift_result[31 - (j * 2):(31 - (j * 2)) - 1];
		end
		for (_gv_j_2 = 0; _gv_j_2 < 10; _gv_j_2 = _gv_j_2 + 1) begin : gen_radix_8_rev
			localparam j = _gv_j_2;
			assign radix_8_rev[(3 * j) + 2:3 * j] = shift_result[31 - (j * 3):(31 - (j * 3)) - 2];
		end
	endgenerate
	assign radix_8_rev[31:30] = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		reverse_result = 1'sb0;
		(* full_case, parallel_case *)
		case (radix_mux_sel)
			2'b00: reverse_result = radix_2_rev;
			2'b01: reverse_result = radix_4_rev;
			2'b10: reverse_result = radix_8_rev;
			default: reverse_result = radix_2_rev;
		endcase
	end
	wire [31:0] result_div;
	wire div_ready;
	wire div_signed;
	wire div_op_a_signed;
	wire [5:0] div_shift_int;
	assign div_signed = operator_i[0];
	assign div_op_a_signed = operand_a_i[31] & div_signed;
	assign div_shift_int = (ff_no_one ? 6'd31 : clb_result);
	assign div_shift = div_shift_int + (div_op_a_signed ? 6'd0 : 6'd1);
	assign div_valid = enable_i & (operator_i[6:2] == 5'b01100);
	cv32e40p_alu_div alu_div_i(
		.Clk_CI(clk),
		.Rst_RBI(rst_n),
		.OpA_DI(operand_b_i),
		.OpB_DI(shift_left_result),
		.OpBShift_DI(div_shift),
		.OpBIsZero_SI(cnt_result == 0),
		.OpBSign_SI(div_op_a_signed),
		.OpCode_SI(operator_i[1:0]),
		.Res_DO(result_div),
		.InVld_SI(div_valid),
		.OutRdy_SI(ex_ready_i),
		.OutVld_SO(div_ready)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_C07C4(7'b0010101): result_o = operand_a_i & operand_b_i;
			sv2v_cast_C07C4(7'b0101110): result_o = operand_a_i | operand_b_i;
			sv2v_cast_C07C4(7'b0101111): result_o = operand_a_i ^ operand_b_i;
			sv2v_cast_C07C4(7'b0011000), sv2v_cast_C07C4(7'b0011100), sv2v_cast_C07C4(7'b0011010), sv2v_cast_C07C4(7'b0011110), sv2v_cast_C07C4(7'b0011001), sv2v_cast_C07C4(7'b0011101), sv2v_cast_C07C4(7'b0011011), sv2v_cast_C07C4(7'b0011111), sv2v_cast_C07C4(7'b0100111), sv2v_cast_C07C4(7'b0100101), sv2v_cast_C07C4(7'b0100100), sv2v_cast_C07C4(7'b0100110): result_o = shift_result;
			sv2v_cast_C07C4(7'b0101010), sv2v_cast_C07C4(7'b0101000), sv2v_cast_C07C4(7'b0101001): result_o = bextins_result;
			sv2v_cast_C07C4(7'b0101011): result_o = bclr_result;
			sv2v_cast_C07C4(7'b0101100): result_o = bset_result;
			sv2v_cast_C07C4(7'b1001001): result_o = reverse_result;
			sv2v_cast_C07C4(7'b0111010), sv2v_cast_C07C4(7'b0111011), sv2v_cast_C07C4(7'b0111000), sv2v_cast_C07C4(7'b0111001), sv2v_cast_C07C4(7'b0111111), sv2v_cast_C07C4(7'b0111110), sv2v_cast_C07C4(7'b0101101): result_o = pack_result;
			sv2v_cast_C07C4(7'b0010000), sv2v_cast_C07C4(7'b0010001), sv2v_cast_C07C4(7'b0010010), sv2v_cast_C07C4(7'b0010011): result_o = result_minmax;
			sv2v_cast_C07C4(7'b0010100): result_o = (is_clpx_i ? {adder_result[31:16], operand_a_i[15:0]} : result_minmax);
			sv2v_cast_C07C4(7'b0010110), sv2v_cast_C07C4(7'b0010111): result_o = clip_result;
			sv2v_cast_C07C4(7'b0001100), sv2v_cast_C07C4(7'b0001101), sv2v_cast_C07C4(7'b0001001), sv2v_cast_C07C4(7'b0001011), sv2v_cast_C07C4(7'b0000001), sv2v_cast_C07C4(7'b0000101), sv2v_cast_C07C4(7'b0001000), sv2v_cast_C07C4(7'b0001010), sv2v_cast_C07C4(7'b0000000), sv2v_cast_C07C4(7'b0000100): begin
				result_o[31:24] = {8 {cmp_result[3]}};
				result_o[23:16] = {8 {cmp_result[2]}};
				result_o[15:8] = {8 {cmp_result[1]}};
				result_o[7:0] = {8 {cmp_result[0]}};
			end
			sv2v_cast_C07C4(7'b0000010), sv2v_cast_C07C4(7'b0000011), sv2v_cast_C07C4(7'b0000110), sv2v_cast_C07C4(7'b0000111): result_o = {31'b0000000000000000000000000000000, comparison_result_o};
			sv2v_cast_C07C4(7'b0110110), sv2v_cast_C07C4(7'b0110111), sv2v_cast_C07C4(7'b0110101), sv2v_cast_C07C4(7'b0110100): result_o = {26'h0000000, bitop_result[5:0]};
			sv2v_cast_C07C4(7'b0110001), sv2v_cast_C07C4(7'b0110000), sv2v_cast_C07C4(7'b0110011), sv2v_cast_C07C4(7'b0110010): result_o = result_div;
			default:
				;
		endcase
	end
	assign ready_o = div_ready;
	initial _sv2v_0 = 0;
endmodule

module cv32e40p_alu_parent_context (
    input wire        clk,
    input wire        rst_n,
    input wire        ex_ready_i,
    input wire        alu_en_i,
    input wire [6:0]  alu_operator_i,
    input wire [31:0] alu_operand_a_i,
    input wire [31:0] alu_operand_b_i,
    input wire [31:0] alu_operand_c_i,
    input wire [1:0]  alu_vec_mode_i,
    input wire [4:0]  bmask_a_i,
    input wire [4:0]  bmask_b_i,
    input wire [1:0]  imm_vec_ext_i,
    input wire        alu_is_clpx_i,
    input wire        alu_is_subrot_i,
    input wire [1:0]  alu_clpx_shift_i,
    input wire        regfile_alu_we_i,
    input wire [5:0]  regfile_alu_waddr_i,
    input wire        csr_access_i,
    input wire [31:0] csr_rdata_i,
    output wire [31:0] regfile_alu_wdata_fw_o,
    output wire [5:0]  regfile_alu_waddr_fw_o,
    output wire        regfile_alu_we_fw_o,
    output wire        regfile_alu_we_fw_power_o,
    output wire [31:0] jump_target_o,
    output wire        branch_decision_o,
    output wire        alu_ready_o
);
  wire [31:0] alu_result;
  wire        alu_cmp_result;

  cv32e40p_alu alu_i (
      .clk        (clk),
      .rst_n      (rst_n),
      .enable_i   (alu_en_i),
      .operator_i (alu_operator_i),
      .operand_a_i(alu_operand_a_i),
      .operand_b_i(alu_operand_b_i),
      .operand_c_i(alu_operand_c_i),
      .vector_mode_i(alu_vec_mode_i),
      .bmask_a_i    (bmask_a_i),
      .bmask_b_i    (bmask_b_i),
      .imm_vec_ext_i(imm_vec_ext_i),
      .is_clpx_i   (alu_is_clpx_i),
      .clpx_shift_i(alu_clpx_shift_i),
      .is_subrot_i (alu_is_subrot_i),
      .result_o           (alu_result),
      .comparison_result_o(alu_cmp_result),
      .ready_o   (alu_ready_o),
      .ex_ready_i(ex_ready_i)
  );

  assign regfile_alu_we_fw_o       = regfile_alu_we_i;
  assign regfile_alu_we_fw_power_o = regfile_alu_we_i & alu_ready_o;
  assign regfile_alu_waddr_fw_o    = regfile_alu_waddr_i;
  assign regfile_alu_wdata_fw_o    = csr_access_i ? csr_rdata_i : (alu_en_i ? alu_result : 32'b0);
  assign branch_decision_o         = alu_cmp_result;
  assign jump_target_o             = alu_operand_c_i;
endmodule
