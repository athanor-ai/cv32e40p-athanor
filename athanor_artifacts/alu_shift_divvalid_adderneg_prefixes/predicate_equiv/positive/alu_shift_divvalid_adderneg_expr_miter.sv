
module alu_shift_divvalid_adderneg_expr_miter (
    input logic enable_i,
    input logic is_subrot_i,
    input logic [6:0] operator_i,
    output logic old_shift_left,
    output logic new_shift_left,
    output logic old_div_valid,
    output logic new_div_valid,
    output logic old_adder_op_b_negate,
    output logic new_adder_op_b_negate,
    output logic diff_o
);
  localparam logic [6:0] ALU_SLL   = 7'b0100110;
  localparam logic [6:0] ALU_BINS  = 7'b1010111;
  localparam logic [6:0] ALU_FL1   = 7'b0101110;
  localparam logic [6:0] ALU_CLB   = 7'b0101011;
  localparam logic [6:0] ALU_BREV  = 7'b0100101;
  localparam logic [6:0] ALU_SUB   = 7'b0011001;
  localparam logic [6:0] ALU_SUBR  = 7'b0011011;
  localparam logic [6:0] ALU_SUBU  = 7'b0011101;
  localparam logic [6:0] ALU_SUBUR = 7'b0011111;
  localparam logic [6:0] ALU_DIVU  = 7'b0110000;
  localparam logic [6:0] ALU_DIV   = 7'b0110001;
  localparam logic [6:0] ALU_REMU  = 7'b0110010;
  localparam logic [6:0] ALU_REM   = 7'b0110011;

  assign old_shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||
                          (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||
                          (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                          (operator_i == ALU_REM) || (operator_i == ALU_REMU) ||
                          (operator_i == ALU_BREV);
  assign new_shift_left = (operator_i == ALU_SLL) || (operator_i == ALU_BINS) ||
                          (operator_i == ALU_FL1) || (operator_i == ALU_CLB)  ||
                          (operator_i[6:2] == 5'b01100) ||
                          (operator_i == ALU_BREV);

  assign old_div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                                     (operator_i == ALU_REM) || (operator_i == ALU_REMU));
  assign new_div_valid = enable_i & (operator_i[6:2] == 5'b01100);

  assign old_adder_op_b_negate = (operator_i == ALU_SUB) || (operator_i == ALU_SUBR) ||
                                 (operator_i == ALU_SUBU) || (operator_i == ALU_SUBUR) || is_subrot_i;
  assign new_adder_op_b_negate = ((operator_i[6:3] == 4'b0011) & operator_i[0]) | is_subrot_i;

  assign diff_o = (old_shift_left ^ new_shift_left) |
                  (old_div_valid ^ new_div_valid) |
                  (old_adder_op_b_negate ^ new_adder_op_b_negate);
endmodule
