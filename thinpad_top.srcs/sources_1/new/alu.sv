`include "./common/constants.svh"
module alu(
  input  wire [31:0] alu_a,
  input  wire [31:0] alu_b,
  input  wire [ 2:0] alu_op,
  output reg  [31:0] alu_y
);

  always_comb begin
    case (alu_op)
      ALU_ADD: alu_y = alu_a + alu_b;
      ALU_SLL: alu_y = alu_a << alu_b;
      ALU_SLT: alu_y = ($signed(alu_a) < $signed(alu_b)) ? 16'h0001 : 16'h0000;
      ALU_SLTU: alu_y = (alu_a < alu_b) ? 16'h0001 : 16'h0000;
      ALU_XOR: alu_y = alu_a ^ alu_b;
      ALU_SRL: alu_y = alu_a >> alu_b;
      ALU_OR: alu_y = alu_a | alu_b;
      ALU_AND: alu_y = alu_a & alu_b;
      default: alu_y = 16'h0000;
    endcase
  end
endmodule
