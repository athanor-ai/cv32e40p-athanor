
module alu_combo_expr_miter (
    input logic enable_i,
    input logic is_subrot_i,
    input logic [6:0] operator_i,
    output logic old_shift_use_round,
    output logic new_shift_use_round,
    output logic old_div_valid,
    output logic new_div_valid,
    output logic old_adder_op_b_negate,
    output logic new_adder_op_b_negate,
    output logic diff_o
);
  localparam logic [6:0] ALU_ADD   = 7'b0011000;
  localparam logic [6:0] ALU_SUB   = 7'b0011001;
  localparam logic [6:0] ALU_ADDR  = 7'b0011010;
  localparam logic [6:0] ALU_SUBR  = 7'b0011011;
  localparam logic [6:0] ALU_ADDU  = 7'b0011100;
  localparam logic [6:0] ALU_SUBU  = 7'b0011101;
  localparam logic [6:0] ALU_ADDUR = 7'b0011110;
  localparam logic [6:0] ALU_SUBUR = 7'b0011111;
  localparam logic [6:0] ALU_DIVU  = 7'b0110000;
  localparam logic [6:0] ALU_DIV   = 7'b0110001;
  localparam logic [6:0] ALU_REMU  = 7'b0110010;
  localparam logic [6:0] ALU_REM   = 7'b0110011;

  assign old_shift_use_round = (operator_i == ALU_ADD)   || (operator_i == ALU_SUB)   ||
                               (operator_i == ALU_ADDR)  || (operator_i == ALU_SUBR)  ||
                               (operator_i == ALU_ADDU)  || (operator_i == ALU_SUBU)  ||
                               (operator_i == ALU_ADDUR) || (operator_i == ALU_SUBUR);
  assign new_shift_use_round = (operator_i[6:3] == 4'b0011);

  assign old_div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                                     (operator_i == ALU_REM) || (operator_i == ALU_REMU));
  assign new_div_valid = enable_i & (operator_i[6:2] == 5'b01100);

  assign old_adder_op_b_negate = (operator_i == ALU_SUB) || (operator_i == ALU_SUBR) ||
                                 (operator_i == ALU_SUBU) || (operator_i == ALU_SUBUR) || is_subrot_i;
  assign new_adder_op_b_negate = ((operator_i[6:3] == 4'b0011) & ~operator_i[0]) | is_subrot_i;

  assign diff_o = (old_shift_use_round ^ new_shift_use_round) |
                  (old_div_valid ^ new_div_valid) |
                  (old_adder_op_b_negate ^ new_adder_op_b_negate);
endmodule
