`default_nettype none
module ID_module(
    input wire reset,
    input wire [31:0] inst_reg,
    output reg [4:0] rf_raddr_a,
    output reg [4:0] rf_raddr_b,
    output reg [4:0] rd_reg,
    output reg [6:0] opcode,
    output reg [2:0] funct,
    output reg [31:0] imm,
    output reg [31:0] oprand1_reg,
    output reg [31:0] oprand2_reg
);

  //指令解析，rs1,rs2,rd,opcode,funct
  always_comb begin
      case(inst_reg[6:0])
          7'b0110111: imm = {{12{inst_reg[31]}}, inst_reg[31:12]}; // LUI
          7'b1100011: imm = {{19{inst_reg[31]}}, inst_reg[31], inst_reg[7], inst_reg[30:25], inst_reg[11:8], 1'b0}; // BEQ
          7'b0000011: imm = {{20{inst_reg[31]}}, inst_reg[31:20]}; // LB
          7'b0100011: imm = {{20{inst_reg[31]}}, inst_reg[31:25],inst_reg[11:7]}; // SB,SW
          7'b0010011: imm = {{20{inst_reg[31]}}, inst_reg[31:20]}; // ANDI,ADDI
          7'b0110011: imm = 0; // ADD
          default: imm = 32'b0;
      endcase
      rf_raddr_a = inst_reg[19:15];
      rf_raddr_b = inst_reg[24:20];
      rd_reg = inst_reg[11:7];
      opcode = inst_reg[6:0];
      funct = inst_reg[14:12];
      case (opcode)
        7'b0110111:begin   //LUI
            oprand1_reg <= imm;
            oprand2_reg <= 32'b0;
        end
        7'b1100011:begin   //BEQ
            oprand1_reg <= rf_rdata_a;
            oprand2_reg <= rf_rdata_b;
        end
        7'b0000011:begin   //LB
            oprand1_reg <= rf_rdata_a;
            oprand2_reg <= imm;
        end
        7'b0100011:begin   //SB,SW
            oprand1_reg <= rf_rdata_a;
            oprand2_reg <= imm;
        end
        7'b0010011: begin   //ANDI,ADDI 
            oprand1_reg <= rf_rdata_a;
            oprand2_reg <= imm;
        end
        7'b0110011: begin   //ADD
            oprand1_reg <= rf_rdata_a;
            oprand2_reg <= rf_rdata_b;
        end
        default: begin
        end
      endcase
  end
endmodule