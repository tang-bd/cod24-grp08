`default_nettype none
module EXE_module(
    input wire reset,
    input wire [31:0] inst_reg,
    input wire [31:0] oprand1_reg,
    input wire [31:0] oprand2_reg,
    input wire [6:0] opcode,
    input wire [2:0] funct,
    input wire [31:0] imm,
    output reg [31:0] result_reg
    
);
reg [31:0] result_reg;
always_comb begin
    case(opcode)
        7'b0010011: begin   //ANDI,ADDI 
            if(funct == 3'b000) begin //ADDI
                result_reg = oprand1_reg + oprand2_reg;
            end else if(funct == 3'b111) begin //ANDI
                result_reg = oprand1_reg & oprand2_reg;
            end
        end
        7'b0110011: begin   //ADD
            result_reg = oprand1_reg + oprand2_reg;
        end
        default: begin
        end
    endcase
end
endmodule