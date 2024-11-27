`default_nettype none
module RegFile_32(
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    input wire we,
    input wire [4:0] raddr_a,
    output reg [31:0] rdata_a,
    input wire [4:0] raddr_b,
    output reg [31:0] rdata_b,
    input wire clk
    );
    logic [31:0] rf [0:31];
    always_ff @(posedge clk) begin
        if (we) begin
            if (waddr !== 0) begin
                rf[waddr] <= wdata;
            end
        end
    end    

    always_comb begin
        if (raddr_a !== 0) begin
            rdata_a <= rf[raddr_a];
        end else begin
            rdata_a <= 32'b0;
        end
        if (raddr_b !== 0) begin
            rdata_b <= rf[raddr_b];
        end else begin
            rdata_b <= 32'b0;
        end
    end
endmodule
