`include "./common/constants.svh"
module IF(
    input wire clk_i,
    input wire rst_i,
    input wire bubble_i,
    input wire [31:0] jump_addr_i,

    output reg [31:0] pc_o,
    output reg [31:0] inst_o,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [3:0] wb_sel_o,
    output reg wb_we_o
);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_o <= 32'h80000000;
            inst_o <= 32'b0;

            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
        end else begin
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= pc_o;
            wb_dat_o <= 32'b0;
            wb_sel_o <= 4'b1111;
            wb_we_o <= 1'b0;

            if (wb_ack_i) begin
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;
                wb_adr_o <= pc_o + 4;

                pc_o <= pc_o + 4;
                inst_o <= wb_dat_i;
            end else if (bubble_i) begin
                wb_adr_o <= jump_addr_i;
                pc_o <= jump_addr_i;
            end
        end
    end
endmodule