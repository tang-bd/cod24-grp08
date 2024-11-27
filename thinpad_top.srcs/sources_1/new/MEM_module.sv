`default_nettype none
module MEM_module(
    input wire clk,
    input wire reset,


    input wire [31:0] wb_dat_i,
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
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
    always_comb begin
    end

endmodule