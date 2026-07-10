module cv32e40p_obi_interface (
	clk,
	rst_n,
	trans_valid_i,
	trans_ready_o,
	trans_addr_i,
	trans_we_i,
	trans_be_i,
	trans_wdata_i,
	trans_atop_i,
	resp_valid_o,
	resp_rdata_o,
	resp_err_o,
	obi_req_o,
	obi_gnt_i,
	obi_addr_o,
	obi_we_o,
	obi_be_o,
	obi_wdata_o,
	obi_atop_o,
	obi_rdata_i,
	obi_rvalid_i,
	obi_err_i
);
	reg _sv2v_0;
	parameter TRANS_STABLE = 0;
	input wire clk;
	input wire rst_n;
	input wire trans_valid_i;
	output wire trans_ready_o;
	input wire [31:0] trans_addr_i;
	input wire trans_we_i;
	input wire [3:0] trans_be_i;
	input wire [31:0] trans_wdata_i;
	input wire [5:0] trans_atop_i;
	output wire resp_valid_o;
	output wire [31:0] resp_rdata_o;
	output wire resp_err_o;
	output reg obi_req_o;
	input wire obi_gnt_i;
	output reg [31:0] obi_addr_o;
	output reg obi_we_o;
	output reg [3:0] obi_be_o;
	output reg [31:0] obi_wdata_o;
	output reg [5:0] obi_atop_o;
	input wire [31:0] obi_rdata_i;
	input wire obi_rvalid_i;
	input wire obi_err_i;
	reg state_q;
	reg next_state;
	assign resp_valid_o = obi_rvalid_i;
	assign resp_rdata_o = obi_rdata_i;
	assign resp_err_o = obi_err_i;
	generate
		if (TRANS_STABLE) begin : gen_trans_stable
			wire [1:1] sv2v_tmp_E8019;
			assign sv2v_tmp_E8019 = trans_valid_i;
			always @(*) obi_req_o = sv2v_tmp_E8019;
			wire [32:1] sv2v_tmp_2DFD9;
			assign sv2v_tmp_2DFD9 = trans_addr_i;
			always @(*) obi_addr_o = sv2v_tmp_2DFD9;
			wire [1:1] sv2v_tmp_367C5;
			assign sv2v_tmp_367C5 = trans_we_i;
			always @(*) obi_we_o = sv2v_tmp_367C5;
			wire [4:1] sv2v_tmp_738B5;
			assign sv2v_tmp_738B5 = trans_be_i;
			always @(*) obi_be_o = sv2v_tmp_738B5;
			wire [32:1] sv2v_tmp_F8E9B;
			assign sv2v_tmp_F8E9B = trans_wdata_i;
			always @(*) obi_wdata_o = sv2v_tmp_F8E9B;
			wire [6:1] sv2v_tmp_E7AA9;
			assign sv2v_tmp_E7AA9 = trans_atop_i;
			always @(*) obi_atop_o = sv2v_tmp_E7AA9;
			assign trans_ready_o = obi_gnt_i;
			wire [1:1] sv2v_tmp_7058D;
			assign sv2v_tmp_7058D = 1'd0;
			always @(*) state_q = sv2v_tmp_7058D;
			wire [1:1] sv2v_tmp_B3134;
			assign sv2v_tmp_B3134 = 1'd0;
			always @(*) next_state = sv2v_tmp_B3134;
		end
		else begin : gen_no_trans_stable
			reg [31:0] obi_addr_q;
			reg obi_we_q;
			reg [3:0] obi_be_q;
			reg [31:0] obi_wdata_q;
			reg [5:0] obi_atop_q;
			always @(*) begin
				if (_sv2v_0)
					;
				next_state = state_q;
				case (state_q)
					1'd0:
						if (obi_req_o && !obi_gnt_i)
							next_state = 1'd1;
					1'd1:
						if (obi_gnt_i)
							next_state = 1'd0;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				if (state_q == 1'd0) begin
					obi_req_o = trans_valid_i;
					obi_addr_o = trans_addr_i;
					obi_we_o = trans_we_i;
					obi_be_o = trans_be_i;
					obi_wdata_o = trans_wdata_i;
					obi_atop_o = trans_atop_i;
				end
				else begin
					obi_req_o = 1'b1;
					obi_addr_o = obi_addr_q;
					obi_we_o = obi_we_q;
					obi_be_o = obi_be_q;
					obi_wdata_o = obi_wdata_q;
					obi_atop_o = obi_atop_q;
				end
			end
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0) begin
					state_q <= 1'd0;
					obi_addr_q <= 32'b00000000000000000000000000000000;
					obi_we_q <= 1'b0;
					obi_be_q <= 4'b0000;
					obi_wdata_q <= 32'b00000000000000000000000000000000;
					obi_atop_q <= 6'b000000;
				end
				else begin
					state_q <= next_state;
					if ((state_q == 1'd0) && (next_state == 1'd1)) begin
						obi_addr_q <= obi_addr_o;
						obi_we_q <= obi_we_o;
						obi_be_q <= obi_be_o;
						obi_wdata_q <= obi_wdata_o;
						obi_atop_q <= obi_atop_o;
					end
				end
			assign trans_ready_o = state_q == 1'd0;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_fifo (
	clk_i,
	rst_ni,
	flush_i,
	flush_but_first_i,
	testmode_i,
	full_o,
	empty_o,
	cnt_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	reg _sv2v_0;
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire flush_but_first_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire [ADDR_DEPTH:0] cnt_o;
	input wire [DATA_WIDTH - 1:0] data_i;
	input wire push_i;
	output reg [DATA_WIDTH - 1:0] data_o;
	input wire pop_i;
	localparam [31:0] FIFO_DEPTH = (DEPTH > 0 ? DEPTH : 1);
	reg gate_clock;
	reg [ADDR_DEPTH - 1:0] read_pointer_n;
	reg [ADDR_DEPTH - 1:0] read_pointer_q;
	reg [ADDR_DEPTH - 1:0] write_pointer_n;
	reg [ADDR_DEPTH - 1:0] write_pointer_q;
	reg [ADDR_DEPTH:0] status_cnt_n;
	reg [ADDR_DEPTH:0] status_cnt_q;
	reg [(FIFO_DEPTH * DATA_WIDTH) - 1:0] mem_n;
	reg [(FIFO_DEPTH * DATA_WIDTH) - 1:0] mem_q;
	assign cnt_o = status_cnt_q;
	generate
		if (DEPTH == 0) begin : gen_zero_depth
			assign empty_o = ~push_i;
			assign full_o = ~pop_i;
		end
		else begin : gen_non_zero_depth
			assign full_o = status_cnt_q == FIFO_DEPTH[ADDR_DEPTH:0];
			assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
		end
	endgenerate
	always @(*) begin : read_write_comb
		if (_sv2v_0)
			;
		read_pointer_n = read_pointer_q;
		write_pointer_n = write_pointer_q;
		status_cnt_n = status_cnt_q;
		data_o = (DEPTH == 0 ? data_i : mem_q[read_pointer_q * DATA_WIDTH+:DATA_WIDTH]);
		mem_n = mem_q;
		gate_clock = 1'b1;
		if (push_i && ~full_o) begin
			mem_n[write_pointer_q * DATA_WIDTH+:DATA_WIDTH] = data_i;
			gate_clock = 1'b0;
			if (write_pointer_q == (FIFO_DEPTH[ADDR_DEPTH - 1:0] - 1))
				write_pointer_n = 1'sb0;
			else
				write_pointer_n = write_pointer_q + 1;
			status_cnt_n = status_cnt_q + 1;
		end
		if (pop_i && ~empty_o) begin
			if (read_pointer_n == (FIFO_DEPTH[ADDR_DEPTH - 1:0] - 1))
				read_pointer_n = 1'sb0;
			else
				read_pointer_n = read_pointer_q + 1;
			status_cnt_n = status_cnt_q - 1;
		end
		if (((push_i && pop_i) && ~full_o) && ~empty_o)
			status_cnt_n = status_cnt_q;
		if ((FALL_THROUGH && (status_cnt_q == 0)) && push_i) begin
			data_o = data_i;
			if (pop_i) begin
				status_cnt_n = status_cnt_q;
				read_pointer_n = read_pointer_q;
				write_pointer_n = write_pointer_q;
			end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else
			(* full_case, parallel_case *)
			case (1'b1)
				flush_i: begin
					read_pointer_q <= 1'sb0;
					write_pointer_q <= 1'sb0;
					status_cnt_q <= 1'sb0;
				end
				flush_but_first_i: begin
					read_pointer_q <= (status_cnt_q > 0 ? read_pointer_q : {ADDR_DEPTH {1'sb0}});
					write_pointer_q <= (status_cnt_q > 0 ? read_pointer_q + 1 : {ADDR_DEPTH {1'sb0}});
					status_cnt_q <= (status_cnt_q > 0 ? 1'b1 : {(ADDR_DEPTH >= 0 ? ADDR_DEPTH + 1 : 1 - ADDR_DEPTH) {1'sb0}});
				end
				default: begin
					read_pointer_q <= read_pointer_n;
					write_pointer_q <= write_pointer_n;
					status_cnt_q <= status_cnt_n;
				end
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mem_q <= 1'sb0;
		else if (!gate_clock)
			mem_q <= mem_n;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_prefetch_controller (
	clk,
	rst_n,
	req_i,
	branch_i,
	branch_addr_i,
	busy_o,
	hwlp_jump_i,
	hwlp_target_i,
	trans_valid_o,
	trans_ready_i,
	trans_addr_o,
	resp_valid_i,
	fetch_ready_i,
	fetch_valid_o,
	fifo_push_o,
	fifo_pop_o,
	fifo_flush_o,
	fifo_flush_but_first_o,
	fifo_cnt_i,
	fifo_empty_i
);
	reg _sv2v_0;
	parameter PULP_OBI = 0;
	parameter COREV_PULP = 1;
	parameter DEPTH = 4;
	parameter FIFO_ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk;
	input wire rst_n;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] branch_addr_i;
	output wire busy_o;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	output wire trans_valid_o;
	input wire trans_ready_i;
	output reg [31:0] trans_addr_o;
	input wire resp_valid_i;
	input wire fetch_ready_i;
	output wire fetch_valid_o;
	output wire fifo_push_o;
	output wire fifo_pop_o;
	output wire fifo_flush_o;
	output wire fifo_flush_but_first_o;
	input wire [FIFO_ADDR_DEPTH:0] fifo_cnt_i;
	input wire fifo_empty_i;
	reg state_q;
	reg next_state;
	reg [FIFO_ADDR_DEPTH:0] cnt_q;
	reg [FIFO_ADDR_DEPTH:0] next_cnt;
	wire count_up;
	wire count_down;
	reg [FIFO_ADDR_DEPTH:0] flush_cnt_q;
	reg [FIFO_ADDR_DEPTH:0] next_flush_cnt;
	reg [31:0] trans_addr_q;
	wire [31:0] trans_addr_incr;
	wire [31:0] aligned_branch_addr;
	wire fifo_valid;
	wire [FIFO_ADDR_DEPTH:0] fifo_cnt_masked;
	wire hwlp_wait_resp_flush;
	reg hwlp_flush_after_resp;
	reg [FIFO_ADDR_DEPTH:0] hwlp_flush_cnt_delayed_q;
	wire hwlp_flush_resp_delayed;
	wire hwlp_flush_resp;
	assign busy_o = (cnt_q != 3'b000) || trans_valid_o;
	assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > 0));
	assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};
	assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;
	generate
		if (PULP_OBI == 0) begin : gen_no_pulp_obi
			assign trans_valid_o = req_i && ((fifo_cnt_masked + cnt_q) < DEPTH);
		end
		else begin : gen_pulp_obi
			assign trans_valid_o = (cnt_q == 3'b000 ? req_i && ((fifo_cnt_masked + cnt_q) < DEPTH) : (req_i && ((fifo_cnt_masked + cnt_q) < DEPTH)) && resp_valid_i);
		end
	endgenerate
	assign fifo_cnt_masked = (branch_i || hwlp_jump_i ? {(FIFO_ADDR_DEPTH >= 0 ? FIFO_ADDR_DEPTH + 1 : 1 - FIFO_ADDR_DEPTH) {1'sb0}} : fifo_cnt_i);
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = state_q;
		trans_addr_o = trans_addr_q;
		case (state_q)
			1'd0: begin
				if (branch_i)
					trans_addr_o = aligned_branch_addr;
				else if (hwlp_jump_i)
					trans_addr_o = hwlp_target_i;
				else
					trans_addr_o = trans_addr_incr;
				if ((branch_i || hwlp_jump_i) && !(trans_valid_o && trans_ready_i))
					next_state = 1'd1;
			end
			1'd1: begin
				trans_addr_o = (branch_i ? aligned_branch_addr : trans_addr_q);
				if (trans_valid_o && trans_ready_i)
					next_state = 1'd0;
			end
		endcase
	end
	assign fifo_valid = !fifo_empty_i;
	assign fifo_push_o = (resp_valid_i && (fifo_valid || !fetch_ready_i)) && !(branch_i || (flush_cnt_q > 0));
	assign fifo_pop_o = fifo_valid && fetch_ready_i;
	assign count_up = trans_valid_o && trans_ready_i;
	assign count_down = resp_valid_i;
	always @(*) begin
		if (_sv2v_0)
			;
		case ({count_up, count_down})
			2'b00: next_cnt = cnt_q;
			2'b01: next_cnt = cnt_q - 1'b1;
			2'b10: next_cnt = cnt_q + 1'b1;
			2'b11: next_cnt = cnt_q;
		endcase
	end
	generate
		if (COREV_PULP) begin : gen_hwlp
			assign fifo_flush_o = branch_i || ((hwlp_jump_i && !fifo_empty_i) && fifo_pop_o);
			assign fifo_flush_but_first_o = (hwlp_jump_i && !fifo_empty_i) && !fifo_pop_o;
			assign hwlp_flush_resp = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);
			assign hwlp_wait_resp_flush = hwlp_jump_i && (fifo_empty_i && !resp_valid_i);
			always @(posedge clk or negedge rst_n)
				if (~rst_n) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
				else if (branch_i) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
				else if (hwlp_wait_resp_flush) begin
					hwlp_flush_after_resp <= 1'b1;
					hwlp_flush_cnt_delayed_q <= cnt_q - 1'b1;
				end
				else if (hwlp_flush_resp_delayed) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
			assign hwlp_flush_resp_delayed = hwlp_flush_after_resp && resp_valid_i;
		end
		else begin : gen_no_hwlp
			assign fifo_flush_o = branch_i;
			assign fifo_flush_but_first_o = 1'b0;
			assign hwlp_flush_resp = 1'b0;
			assign hwlp_wait_resp_flush = 1'b0;
			wire [1:1] sv2v_tmp_9BC28;
			assign sv2v_tmp_9BC28 = 1'b0;
			always @(*) hwlp_flush_after_resp = sv2v_tmp_9BC28;
			wire [(FIFO_ADDR_DEPTH >= 0 ? FIFO_ADDR_DEPTH + 1 : 1 - FIFO_ADDR_DEPTH):1] sv2v_tmp_2B514;
			assign sv2v_tmp_2B514 = 2'b00;
			always @(*) hwlp_flush_cnt_delayed_q = sv2v_tmp_2B514;
			assign hwlp_flush_resp_delayed = 1'b0;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		next_flush_cnt = flush_cnt_q;
		if (branch_i || hwlp_flush_resp) begin
			next_flush_cnt = cnt_q;
			if (resp_valid_i && (cnt_q > 0))
				next_flush_cnt = cnt_q - 1'b1;
		end
		else if (hwlp_flush_resp_delayed)
			next_flush_cnt = hwlp_flush_cnt_delayed_q;
		else if (resp_valid_i && (flush_cnt_q > 0))
			next_flush_cnt = flush_cnt_q - 1'b1;
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			state_q <= 1'd0;
			cnt_q <= 1'sb0;
			flush_cnt_q <= 1'sb0;
			trans_addr_q <= 1'sb0;
		end
		else begin
			state_q <= next_state;
			cnt_q <= next_cnt;
			flush_cnt_q <= next_flush_cnt;
			if ((branch_i || hwlp_jump_i) || (trans_valid_o && trans_ready_i))
				trans_addr_q <= trans_addr_o;
		end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_prefetch_buffer (
	clk,
	rst_n,
	req_i,
	branch_i,
	branch_addr_i,
	hwlp_jump_i,
	hwlp_target_i,
	fetch_ready_i,
	fetch_valid_o,
	fetch_rdata_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rvalid_i,
	instr_err_i,
	instr_err_pmp_i,
	busy_o
);
	parameter PULP_OBI = 0;
	parameter COREV_PULP = 1;
	input wire clk;
	input wire rst_n;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] branch_addr_i;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	input wire fetch_ready_i;
	output wire fetch_valid_o;
	output wire [31:0] fetch_rdata_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_rvalid_i;
	input wire instr_err_i;
	input wire instr_err_pmp_i;
	output wire busy_o;
	localparam FIFO_DEPTH = 2;
	localparam [31:0] FIFO_ADDR_DEPTH = 1;
	wire trans_valid;
	wire trans_ready;
	wire [31:0] trans_addr;
	wire fifo_flush;
	wire fifo_flush_but_first;
	wire [FIFO_ADDR_DEPTH:0] fifo_cnt;
	wire [31:0] fifo_rdata;
	wire fifo_push;
	wire fifo_pop;
	wire fifo_empty;
	wire resp_valid;
	wire [31:0] resp_rdata;
	wire resp_err;
	cv32e40p_prefetch_controller #(
		.DEPTH(FIFO_DEPTH),
		.PULP_OBI(PULP_OBI),
		.COREV_PULP(COREV_PULP)
	) prefetch_controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.req_i(req_i),
		.branch_i(branch_i),
		.branch_addr_i(branch_addr_i),
		.busy_o(busy_o),
		.hwlp_jump_i(hwlp_jump_i),
		.hwlp_target_i(hwlp_target_i),
		.trans_valid_o(trans_valid),
		.trans_ready_i(trans_ready),
		.trans_addr_o(trans_addr),
		.resp_valid_i(resp_valid),
		.fetch_ready_i(fetch_ready_i),
		.fetch_valid_o(fetch_valid_o),
		.fifo_push_o(fifo_push),
		.fifo_pop_o(fifo_pop),
		.fifo_flush_o(fifo_flush),
		.fifo_flush_but_first_o(fifo_flush_but_first),
		.fifo_cnt_i(fifo_cnt),
		.fifo_empty_i(fifo_empty)
	);
	cv32e40p_fifo #(
		.FALL_THROUGH(1'b0),
		.DATA_WIDTH(32),
		.DEPTH(FIFO_DEPTH)
	) fifo_i(
		.clk_i(clk),
		.rst_ni(rst_n),
		.flush_i(fifo_flush),
		.flush_but_first_i(fifo_flush_but_first),
		.testmode_i(1'b0),
		.full_o(),
		.empty_o(fifo_empty),
		.cnt_o(fifo_cnt),
		.data_i(resp_rdata),
		.push_i(fifo_push),
		.data_o(fifo_rdata),
		.pop_i(fifo_pop)
	);
	assign fetch_rdata_o = (fifo_empty ? resp_rdata : fifo_rdata);
	cv32e40p_obi_interface #(.TRANS_STABLE(0)) instruction_obi_i(
		.clk(clk),
		.rst_n(rst_n),
		.trans_valid_i(trans_valid),
		.trans_ready_o(trans_ready),
		.trans_addr_i({trans_addr[31:2], 2'b00}),
		.trans_we_i(1'b0),
		.trans_be_i(4'b1111),
		.trans_wdata_i(32'b00000000000000000000000000000000),
		.trans_atop_i(6'b000000),
		.resp_valid_o(resp_valid),
		.resp_rdata_o(resp_rdata),
		.resp_err_o(resp_err),
		.obi_req_o(instr_req_o),
		.obi_gnt_i(instr_gnt_i),
		.obi_addr_o(instr_addr_o),
		.obi_we_o(),
		.obi_be_o(),
		.obi_wdata_o(),
		.obi_atop_o(),
		.obi_rdata_i(instr_rdata_i),
		.obi_rvalid_i(instr_rvalid_i),
		.obi_err_i(instr_err_i)
	);
endmodule
module cv32e40p_aligner (
	clk,
	rst_n,
	fetch_valid_i,
	aligner_ready_o,
	if_valid_i,
	fetch_rdata_i,
	instr_aligned_o,
	instr_valid_o,
	branch_addr_i,
	branch_i,
	hwlp_addr_i,
	hwlp_update_pc_i,
	pc_o
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire fetch_valid_i;
	output reg aligner_ready_o;
	input wire if_valid_i;
	input wire [31:0] fetch_rdata_i;
	output reg [31:0] instr_aligned_o;
	output reg instr_valid_o;
	input wire [31:0] branch_addr_i;
	input wire branch_i;
	input wire [31:0] hwlp_addr_i;
	input wire hwlp_update_pc_i;
	output wire [31:0] pc_o;
	reg [2:0] state;
	reg [2:0] next_state;
	reg [15:0] r_instr_h;
	reg [31:0] hwlp_addr_q;
	reg [31:0] pc_q;
	reg [31:0] pc_n;
	reg update_state;
	wire [31:0] pc_plus4;
	wire [31:0] pc_plus2;
	reg aligner_ready_q;
	reg hwlp_update_pc_q;
	assign pc_o = pc_q;
	assign pc_plus2 = pc_q + 2;
	assign pc_plus4 = pc_q + 4;
	always @(posedge clk or negedge rst_n) begin : proc_SEQ_FSM
		if (~rst_n) begin
			state <= 3'd0;
			r_instr_h <= 1'sb0;
			hwlp_addr_q <= 1'sb0;
			pc_q <= 1'sb0;
			aligner_ready_q <= 1'b0;
			hwlp_update_pc_q <= 1'b0;
		end
		else if (update_state) begin
			pc_q <= pc_n;
			state <= next_state;
			r_instr_h <= fetch_rdata_i[31:16];
			aligner_ready_q <= aligner_ready_o;
			hwlp_update_pc_q <= 1'b0;
		end
		else if (hwlp_update_pc_i) begin
			hwlp_addr_q <= hwlp_addr_i;
			hwlp_update_pc_q <= 1'b1;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		pc_n = pc_q;
		instr_valid_o = fetch_valid_i;
		instr_aligned_o = fetch_rdata_i;
		aligner_ready_o = 1'b1;
		update_state = 1'b0;
		next_state = state;
		case (state)
			3'd0:
				if (fetch_rdata_i[1:0] == 2'b11) begin
					next_state = 3'd0;
					pc_n = pc_plus4;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
					if (hwlp_update_pc_i || hwlp_update_pc_q)
						pc_n = (hwlp_update_pc_i ? hwlp_addr_i : hwlp_addr_q);
				end
				else begin
					next_state = 3'd1;
					pc_n = pc_plus2;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
				end
			3'd1:
				if (r_instr_h[1:0] == 2'b11) begin
					next_state = 3'd1;
					pc_n = pc_plus4;
					instr_aligned_o = {fetch_rdata_i[15:0], r_instr_h[15:0]};
					update_state = fetch_valid_i & if_valid_i;
				end
				else begin
					instr_aligned_o = {fetch_rdata_i[31:16], r_instr_h[15:0]};
					next_state = 3'd2;
					instr_valid_o = 1'b1;
					pc_n = pc_plus2;
					aligner_ready_o = !fetch_valid_i;
					update_state = if_valid_i;
				end
			3'd2: begin
				instr_valid_o = !aligner_ready_q || fetch_valid_i;
				if (fetch_rdata_i[1:0] == 2'b11) begin
					next_state = 3'd0;
					pc_n = pc_plus4;
					instr_aligned_o = fetch_rdata_i;
					update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
				end
				else begin
					next_state = 3'd1;
					pc_n = pc_plus2;
					instr_aligned_o = fetch_rdata_i;
					update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
				end
			end
			3'd3:
				if (fetch_rdata_i[17:16] == 2'b11) begin
					next_state = 3'd1;
					instr_valid_o = 1'b0;
					pc_n = pc_q;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
				end
				else begin
					next_state = 3'd0;
					pc_n = pc_plus2;
					instr_aligned_o = {fetch_rdata_i[31:16], fetch_rdata_i[31:16]};
					update_state = fetch_valid_i & if_valid_i;
				end
		endcase
		if (branch_i) begin
			update_state = 1'b1;
			pc_n = branch_addr_i;
			next_state = (branch_addr_i[1] ? 3'd3 : 3'd0);
		end
	end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_compressed_decoder (
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
						if (~|{instr_i[12], instr_i[6:2]})
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
module cv32e40p_if_stage (
	clk,
	rst_n,
	m_trap_base_addr_i,
	u_trap_base_addr_i,
	trap_addr_mux_i,
	boot_addr_i,
	dm_exception_addr_i,
	dm_halt_addr_i,
	req_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_err_i,
	instr_err_pmp_i,
	instr_valid_id_o,
	instr_rdata_id_o,
	is_compressed_id_o,
	illegal_c_insn_id_o,
	pc_if_o,
	pc_id_o,
	is_fetch_failed_o,
	clear_instr_valid_i,
	pc_set_i,
	mepc_i,
	uepc_i,
	depc_i,
	pc_mux_i,
	exc_pc_mux_i,
	m_exc_vec_pc_mux_i,
	u_exc_vec_pc_mux_i,
	csr_mtvec_init_o,
	jump_target_id_i,
	jump_target_ex_i,
	hwlp_jump_i,
	hwlp_target_i,
	halt_if_i,
	id_ready_i,
	if_busy_o,
	perf_imiss_o
);
	reg _sv2v_0;
	parameter COREV_PULP = 0;
	parameter PULP_OBI = 0;
	parameter PULP_SECURE = 0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire clk;
	input wire rst_n;
	input wire [23:0] m_trap_base_addr_i;
	input wire [23:0] u_trap_base_addr_i;
	input wire [1:0] trap_addr_mux_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] dm_exception_addr_i;
	input wire [31:0] dm_halt_addr_i;
	input wire req_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_err_pmp_i;
	output reg instr_valid_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg is_compressed_id_o;
	output reg illegal_c_insn_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	output reg is_fetch_failed_o;
	input wire clear_instr_valid_i;
	input wire pc_set_i;
	input wire [31:0] mepc_i;
	input wire [31:0] uepc_i;
	input wire [31:0] depc_i;
	input wire [3:0] pc_mux_i;
	input wire [2:0] exc_pc_mux_i;
	input wire [4:0] m_exc_vec_pc_mux_i;
	input wire [4:0] u_exc_vec_pc_mux_i;
	output wire csr_mtvec_init_o;
	input wire [31:0] jump_target_id_i;
	input wire [31:0] jump_target_ex_i;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	input wire halt_if_i;
	input wire id_ready_i;
	output wire if_busy_o;
	output wire perf_imiss_o;
	wire if_valid;
	wire if_ready;
	wire prefetch_busy;
	reg branch_req;
	reg [31:0] branch_addr_n;
	wire fetch_valid;
	reg fetch_ready;
	wire [31:0] fetch_rdata;
	reg [31:0] exc_pc;
	reg [23:0] trap_base_addr;
	reg [4:0] exc_vec_pc_mux;
	wire fetch_failed;
	wire aligner_ready;
	wire instr_valid;
	wire illegal_c_insn;
	wire [31:0] instr_aligned;
	wire [31:0] instr_decompressed;
	wire instr_compressed_int;
	localparam cv32e40p_pkg_EXC_PC_DBD = 3'b010;
	localparam cv32e40p_pkg_EXC_PC_DBE = 3'b011;
	localparam cv32e40p_pkg_EXC_PC_EXCEPTION = 3'b000;
	localparam cv32e40p_pkg_EXC_PC_IRQ = 3'b001;
	localparam cv32e40p_pkg_TRAP_MACHINE = 2'b00;
	localparam cv32e40p_pkg_TRAP_USER = 2'b01;
	always @(*) begin : EXC_PC_MUX
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (trap_addr_mux_i)
			cv32e40p_pkg_TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;
			cv32e40p_pkg_TRAP_USER: trap_base_addr = u_trap_base_addr_i;
			default: trap_base_addr = m_trap_base_addr_i;
		endcase
		(* full_case, parallel_case *)
		case (trap_addr_mux_i)
			cv32e40p_pkg_TRAP_MACHINE: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
			cv32e40p_pkg_TRAP_USER: exc_vec_pc_mux = u_exc_vec_pc_mux_i;
			default: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
		endcase
		(* full_case, parallel_case *)
		case (exc_pc_mux_i)
			cv32e40p_pkg_EXC_PC_EXCEPTION: exc_pc = {trap_base_addr, 8'h00};
			cv32e40p_pkg_EXC_PC_IRQ: exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux, 2'b00};
			cv32e40p_pkg_EXC_PC_DBD: exc_pc = {dm_halt_addr_i[31:2], 2'b00};
			cv32e40p_pkg_EXC_PC_DBE: exc_pc = {dm_exception_addr_i[31:2], 2'b00};
			default: exc_pc = {trap_base_addr, 8'h00};
		endcase
	end
	localparam cv32e40p_pkg_PC_BOOT = 4'b0000;
	localparam cv32e40p_pkg_PC_BRANCH = 4'b0011;
	localparam cv32e40p_pkg_PC_DRET = 4'b0111;
	localparam cv32e40p_pkg_PC_EXCEPTION = 4'b0100;
	localparam cv32e40p_pkg_PC_FENCEI = 4'b0001;
	localparam cv32e40p_pkg_PC_HWLOOP = 4'b1000;
	localparam cv32e40p_pkg_PC_JUMP = 4'b0010;
	localparam cv32e40p_pkg_PC_MRET = 4'b0101;
	localparam cv32e40p_pkg_PC_URET = 4'b0110;
	always @(*) begin
		if (_sv2v_0)
			;
		branch_addr_n = {boot_addr_i[31:2], 2'b00};
		(* full_case, parallel_case *)
		case (pc_mux_i)
			cv32e40p_pkg_PC_BOOT: branch_addr_n = {boot_addr_i[31:2], 2'b00};
			cv32e40p_pkg_PC_JUMP: branch_addr_n = jump_target_id_i;
			cv32e40p_pkg_PC_BRANCH: branch_addr_n = jump_target_ex_i;
			cv32e40p_pkg_PC_EXCEPTION: branch_addr_n = exc_pc;
			cv32e40p_pkg_PC_MRET: branch_addr_n = mepc_i;
			cv32e40p_pkg_PC_URET: branch_addr_n = uepc_i;
			cv32e40p_pkg_PC_DRET: branch_addr_n = depc_i;
			cv32e40p_pkg_PC_FENCEI: branch_addr_n = pc_id_o + 4;
			cv32e40p_pkg_PC_HWLOOP: branch_addr_n = hwlp_target_i;
			default:
				;
		endcase
	end
	assign csr_mtvec_init_o = (pc_mux_i == cv32e40p_pkg_PC_BOOT) & pc_set_i;
	assign fetch_failed = 1'b0;
	cv32e40p_prefetch_buffer #(
		.PULP_OBI(PULP_OBI),
		.COREV_PULP(COREV_PULP)
	) prefetch_buffer_i(
		.clk(clk),
		.rst_n(rst_n),
		.req_i(req_i),
		.branch_i(branch_req),
		.branch_addr_i({branch_addr_n[31:1], 1'b0}),
		.hwlp_jump_i(hwlp_jump_i),
		.hwlp_target_i(hwlp_target_i),
		.fetch_ready_i(fetch_ready),
		.fetch_valid_o(fetch_valid),
		.fetch_rdata_o(fetch_rdata),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_err_i(instr_err_i),
		.instr_err_pmp_i(instr_err_pmp_i),
		.instr_rdata_i(instr_rdata_i),
		.busy_o(prefetch_busy)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		fetch_ready = 1'b0;
		branch_req = 1'b0;
		if (pc_set_i)
			branch_req = 1'b1;
		else if (fetch_valid) begin
			if (req_i && if_valid)
				fetch_ready = aligner_ready;
		end
	end
	assign if_busy_o = prefetch_busy;
	assign perf_imiss_o = !fetch_valid && !branch_req;
	always @(posedge clk or negedge rst_n) begin : IF_ID_PIPE_REGISTERS
		if (rst_n == 1'b0) begin
			instr_valid_id_o <= 1'b0;
			instr_rdata_id_o <= 1'sb0;
			is_fetch_failed_o <= 1'b0;
			pc_id_o <= 1'sb0;
			is_compressed_id_o <= 1'b0;
			illegal_c_insn_id_o <= 1'b0;
		end
		else if (if_valid && instr_valid) begin
			instr_valid_id_o <= 1'b1;
			instr_rdata_id_o <= instr_decompressed;
			is_compressed_id_o <= instr_compressed_int;
			illegal_c_insn_id_o <= illegal_c_insn;
			is_fetch_failed_o <= 1'b0;
			pc_id_o <= pc_if_o;
		end
		else if (clear_instr_valid_i) begin
			instr_valid_id_o <= 1'b0;
			is_fetch_failed_o <= fetch_failed;
		end
	end
	assign if_ready = fetch_valid & id_ready_i;
	assign if_valid = ~halt_if_i & if_ready;
	cv32e40p_aligner aligner_i(
		.clk(clk),
		.rst_n(rst_n),
		.fetch_valid_i(fetch_valid),
		.aligner_ready_o(aligner_ready),
		.if_valid_i(if_valid),
		.fetch_rdata_i(fetch_rdata),
		.instr_aligned_o(instr_aligned),
		.instr_valid_o(instr_valid),
		.branch_addr_i({branch_addr_n[31:1], 1'b0}),
		.branch_i(branch_req),
		.hwlp_addr_i(hwlp_target_i),
		.hwlp_update_pc_i(hwlp_jump_i),
		.pc_o(pc_if_o)
	);
	cv32e40p_compressed_decoder #(
		.FPU(FPU),
		.ZFINX(ZFINX)
	) compressed_decoder_i(
		.instr_i(instr_aligned),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_compressed_int),
		.illegal_instr_o(illegal_c_insn)
	);
	initial _sv2v_0 = 0;
endmodule
