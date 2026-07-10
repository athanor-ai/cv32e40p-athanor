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
			assign hwlp_flush_resp = hwlp_jump_i && (!fifo_empty_i || resp_valid_i);
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
