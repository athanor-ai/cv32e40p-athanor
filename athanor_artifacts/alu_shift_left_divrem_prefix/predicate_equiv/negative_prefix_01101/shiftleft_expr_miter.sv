
module shiftleft_expr_miter (
    input logic [6:0] operator_i,
    output logic old_shift_left,
    output logic new_shift_left,
    output logic diff_o
);
  localparam logic [6:0] ALU_SLL  = 7'b0100110;
  localparam logic [6:0] ALU_BINS = 7'b1010111;
  localparam logic [6:0] ALU_FL1  = 7'b0101110;
  localparam logic [6:0] ALU_CLB  = 7'b0101011;
  localparam logic [6:0] ALU_DIVU = 7'b0110000;
  localparam logic [6:0] ALU_DIV  = 7'b0110001;
  localparam logic [6:0] ALU_REMU = 7'b0110010;
  localparam logic [6:0] ALU_REM  = 7'b0110011;
  localparam logic [6:0] ALU_BREV = 7'b0100101;

  assign old_shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||
                          (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||
                          (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                          (operator_i == ALU_REM) || (operator_i == ALU_REMU) ||
                          (operator_i == ALU_BREV);
  assign new_shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||
                          (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||
                          (operator_i[6:2] == 5'b01101) ||
                          (operator_i == ALU_BREV);
  assign diff_o = old_shift_left ^ new_shift_left;
endmodule
