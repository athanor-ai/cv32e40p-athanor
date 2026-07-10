
module compressed_l71_predicate_miter (
    input  logic [31:0] instr_i,
    output logic old_zero,
    output logic new_zero,
    output logic diff_o
);
  assign old_zero = (instr_i[12:5] == 8'b00000000);
  assign new_zero = (~|instr_i[12:6]);
  assign diff_o = old_zero ^ new_zero;
endmodule
