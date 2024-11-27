`default_nettype none
module ID_EXE_REG_module(
    input wire clk,
    input wire reset,
    input wire [4:0] rd_reg_i,
    input wire [6:0] opcode_i,
    input wire [2:0] funct_i,
    input wire [31:0] imm_i,
    input wire [31:0] oprand1_reg_i,
    input wire [31:0] oprand2_reg_i,

    output reg [4:0] rd_reg_o,
    output reg [6:0] opcode_o,
    output reg [2:0] funct_o,
    output reg [31:0] imm_o,
    output reg [31:0] oprand1_reg_o,
    output reg [31:0] oprand2_reg_o
);
    always_ff @(posedge clk) begin
        if (reset) begin
        end else begin
        end
    end
endmodule