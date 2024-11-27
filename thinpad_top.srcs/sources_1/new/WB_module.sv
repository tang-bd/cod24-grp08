`default_nettype none
module WB_module(
    input wire reset,
    input wire [4:0] rd_reg,
    input wire [31:0] result_reg,
    input wire [7:0] opcode,
    output reg [4:0] rf_waddr,    
    output reg [31:0] rf_wdata,
    output reg rf_we_o
);
    always_comb begin
        case (opcode)
            7'b0110111: begin //LUI
            end
            7'b1100011: begin //BEQ
            end
            7'b0010011: begin //ANDI,ADDI
                rf_we<=1;
                rf_wdata<=result_reg;
                rf_waddr<=rd_reg;
            end
            7'b0110011: begin //ADD
            end
            7'b0000011: begin //LB
            end
            7'b0100011: begin //SB,SW
            end
            default: begin
            end
        endcase
    end
endmodule