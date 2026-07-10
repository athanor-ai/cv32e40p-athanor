module hwlp_flush_expr_miter(
  input  logic hwlp_jump_i,
  input  logic fifo_empty_i,
  input  logic resp_valid_i,
  output logic old_o,
  output logic new_o,
  output logic diff_o
);
  assign old_o = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);
  assign new_o = (!fifo_empty_i || resp_valid_i);
  assign diff_o = old_o ^ new_o;
endmodule
