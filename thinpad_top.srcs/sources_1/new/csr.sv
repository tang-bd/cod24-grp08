`include "./common/constants.svh"
module csr(
    input wire clk_i,
    input wire rst_i,
    input wire [11:0] csr_raddr,
    input reg [31:0] csr_rdata,
    input wire [11:0] csr_waddr,
    output reg [31:0] csr_wdata,
    input wire csr_we,

    output reg [31:0] satp_o
);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            satp_o <= 32'h0000_0000;
        end else begin
            if (csr_we) begin
                case (csr_waddr)
                    12'h180: begin
                        satp_o <= csr_wdata;
                    end
                endcase
            end
        end
    end
    
    always_comb begin
        case (csr_raddr)
            12'h180: begin
                csr_rdata = satp_o;
            end
            default: begin
                csr_rdata = 32'h0000_0000;
            end
        endcase
    end
endmodule