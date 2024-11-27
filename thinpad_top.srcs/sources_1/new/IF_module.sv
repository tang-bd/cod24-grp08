`default_nettype none
module IF_module(
    input wire clk,
    input wire reset,
    input wire [31:0] pc_reg,
    output reg [31:0] inst_reg,
    output reg [31:0] pc_next_reg,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [7:0] wb_sel_o,
    output reg wb_we_o,
);
    always_ff @(posedge clk) begin
        if (reset) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
        end else begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
        end
        if (wb_ack_i) begin
            wb_stb_o <= 0;
            wb_cyc_o <= 0;
        end
    end
);
    always_comb begin
        wb_adr_o = pc_reg;
        wb_we_o = 0;
        wb_sel_o = 4'b1111;
        if(wb_ack_i) begin
            inst_reg=wb_dat_i;
            pc_next_reg=pc_reg+4;
        end
    end
endmodule

