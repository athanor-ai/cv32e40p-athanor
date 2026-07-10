
module divvalid_expr_miter (
    input logic enable_i,
    input logic [6:0] operator_i,
    output logic old_div_valid,
    output logic new_div_valid,
    output logic diff_o
);
  localparam logic [6:0] ALU_DIVU = 7'b0110000;
  localparam logic [6:0] ALU_DIV  = 7'b0110001;
  localparam logic [6:0] ALU_REMU = 7'b0110010;
  localparam logic [6:0] ALU_REM  = 7'b0110011;

  assign old_div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                         (operator_i == ALU_REM) || (operator_i == ALU_REMU));
  assign new_div_valid = enable_i & (operator_i[6:2] == 5'b01100);
  assign diff_o = old_div_valid ^ new_div_valid;
endmodule
