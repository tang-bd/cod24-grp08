`include "./common/constants.svh"
module EX_MEM(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,
    input wire [31:0] pc_i,
    input wire [31:0] alu_y_i,
    input wire [31:0] rf_rdata_b_i,
    input wire [4:0] rf_waddr_i,
    input wire [4:0] inst_op_i,
    input wire [2:0] inst_type_i,

    output reg [31:0] pc_o,
    output reg [31:0] alu_y_o,
    output reg [31:0] rf_rdata_b_o,
    output reg [4:0] rf_waddr_o,
    output reg [4:0] inst_op_o,
    output reg [2:0] inst_type_o
);
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_o <= 32'h0;
            alu_y_o <= 32'h0;
            rf_rdata_b_o <= 32'h0;
            rf_waddr_o <= 32'h0;
            inst_op_o <= UNKNOWN_INST_OP;
            inst_type_o <= UNKNOWN_INST_TYPE;
        end else begin
            if (stall_i) begin

            end else if (bubble_i) begin
                pc_o <= 32'h0;
                alu_y_o <= 32'h0;
                rf_rdata_b_o <= 32'h0;
                rf_waddr_o <= 32'h0;
                inst_op_o <= UNKNOWN_INST_OP;
                inst_type_o <= UNKNOWN_INST_TYPE;
            end else begin
                pc_o <= pc_i;
                alu_y_o <= alu_y_i;
                rf_rdata_b_o <= rf_rdata_b_i;
                rf_waddr_o <= rf_waddr_i;
                inst_op_o <= inst_op_i;
                inst_type_o <= inst_type_i;
            end
        end
    end
endmodule