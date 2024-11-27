`default_nettype none
module IF_ID_REG_module(
    input wire clk,
    input wire reset,
    input wire [31:0] inst_reg_i,
    output reg [31:0] inst_reg_o
);
    always_ff @(posedge clk) begin
        if (reset) begin
            inst_reg_o <= 32'b0;
        end else begin
            inst_reg_o <= inst_reg_i;
        end
    end
endmodule