`include "./common/constants.svh"
module imm_gen(
  input  wire [31:0] imm_gen_inst,
  input wire [2:0] imm_gen_type,
  output reg  [31:0] imm_gen_data
);
    always_comb begin
      case (imm_gen_type)
        R_TYPE: imm_gen_data = 32'h00000000;
        I_TYPE: imm_gen_data = {{20{imm_gen_inst[31]}}, imm_gen_inst[31:20]};
        S_TYPE: imm_gen_data = {{20{imm_gen_inst[31]}}, imm_gen_inst[31:25], imm_gen_inst[11:7]};
        B_TYPE: imm_gen_data = {{19{imm_gen_inst[31]}}, imm_gen_inst[31], imm_gen_inst[7], imm_gen_inst[30:25], imm_gen_inst[11:8], 1'b0};
        U_TYPE: imm_gen_data = {imm_gen_inst[31:12], 12'h000};
        J_TYPE: imm_gen_data = {{11{imm_gen_inst[31]}}, imm_gen_inst[31], imm_gen_inst[19:12], imm_gen_inst[20], imm_gen_inst[30:21], 1'b0};
        default: imm_gen_data = 32'h00000000;
      endcase
    end

endmodule