`include "./common/constants.svh"
module IF_ID(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,
    input wire [31:0] pc_i,
    input wire [31:0] inst_i,

    output reg [31:0] pc_o,
    output reg [31:0] inst_o,
    output reg [4:0] rf_raddr_a_o,
    output reg [4:0] rf_raddr_b_o
);
    always_comb begin
        rf_raddr_a_o = inst_o[19:15];
        rf_raddr_b_o = inst_o[24:20];
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_o <= 32'h0;
            inst_o <= 32'h0;
        end else begin
            if (stall_i) begin

            end else if (bubble_i) begin
                pc_o <= 32'h0;
                inst_o <= 32'h0;
            end else begin
                pc_o <= pc_i;
                inst_o <= inst_i;
            end
        end
    end
endmodule