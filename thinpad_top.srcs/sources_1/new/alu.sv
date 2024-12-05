`include "./common/constants.svh"
module alu(
  input  wire [31:0] alu_a,
  input  wire [31:0] alu_b,
  input  wire [ 3:0] alu_op,
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
      ALU_PCNT: begin
        alu_y = 0;
        for (int i = 0; i < 32; i++) begin
          alu_y = alu_y + alu_a[i];
        end
      end
      ALU_CTZ: begin
        alu_y = 0;
        for (int i = 0; i < 32; i++) begin
          if ((alu_a>>i)&1) begin
            alu_y = i;
            break;
          end
        end
      end
      ALU_SBSET: begin
        alu_y = alu_a | (1 << (alu_b&31));
      end
      ALU_SHA512SUM0R: begin
        alu_y = (alu_a << 25) ^ (alu_a << 30) ^ (alu_a >> 28) ^ (alu_b >> 7) ^ (alu_b >> 2) ^ (alu_b << 4);
      end
      default: alu_y = 16'h0000;
    endcase
  end
endmodule
