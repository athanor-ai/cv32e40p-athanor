module prefetch_hwlp_nextcnt_expr_miter(
  input  logic        hwlp_jump_i,
  input  logic        fifo_empty_i,
  input  logic        resp_valid_i,
  input  logic [2:0]  cnt_q,
  input  logic        count_up,
  input  logic        count_down,
  output logic        old_hwlp_flush_resp_o,
  output logic        new_hwlp_flush_resp_o,
  output logic [2:0]  old_next_cnt_o,
  output logic [2:0]  new_next_cnt_o,
  output logic        diff_o
);
  always_comb begin
    case ({count_up, count_down})
      2'b00: old_next_cnt_o = cnt_q;
      2'b01: old_next_cnt_o = cnt_q - 1'b1;
      2'b10: old_next_cnt_o = cnt_q + 1'b1;
      2'b11: old_next_cnt_o = cnt_q;
    endcase
  end

  assign old_hwlp_flush_resp_o = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);
  assign new_hwlp_flush_resp_o = hwlp_jump_i && (!fifo_empty_i || resp_valid_i);
  assign new_next_cnt_o = cnt_q + count_up;
  assign diff_o = (old_hwlp_flush_resp_o ^ new_hwlp_flush_resp_o) || (old_next_cnt_o != new_next_cnt_o);
endmodule
