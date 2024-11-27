`default_nettype none
module EXE_MEM_REG_module(
    input wire clk,
    input wire reset,
    input wire [31:0] result_reg_i,
    input wire [4:0] rd_reg_i,
    output reg [31:0] result_reg_o,
    output reg [4:0] rd_reg_o,
);
    always_ff @(posedge clk) begin
        if (reset) begin
            result_reg_o <= 32'b0;
            rd_reg_o <= 8'b0;
        end else begin
            result_reg_o <= result_reg_i;
            rd_reg_o <= rd_reg_i;
        end
    end
endmodule