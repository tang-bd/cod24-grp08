`include "./common/constants.svh"
module csr(
    input wire clk_i,
    input wire rst_i,
    input wire [11:0] csr_raddr,
    output reg [31:0] csr_rdata,
    input wire [11:0] csr_waddr,
    input reg [31:0] csr_wdata,
    input wire csr_we,

    output reg [31:0] mstatus_o,
    output reg [31:0] mie_o,
    output reg [31:0] mtvec_o,
    output reg [31:0] mscratch_o,
    output reg [31:0] mepc_o,
    output reg [31:0] mcause_o,
    output reg [31:0] mip_o,
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
                    12'h300: begin
                        mstatus_o <= csr_wdata;
                    end
                    12'h304: begin
                        mie_o <= csr_wdata;
                    end
                    12'h305: begin
                        mtvec_o <= csr_wdata;
                    end
                    12'h340: begin
                        mscratch_o <= csr_wdata;
                    end
                    12'h341: begin
                        mepc_o <= csr_wdata;
                    end
                    12'h342: begin
                        mcause_o <= csr_wdata;
                    end
                    12'h344: begin
                        mip_o <= csr_wdata;
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
            12'h300: begin
                csr_rdata = mstatus_o;
            end
            12'h304: begin
                csr_rdata = mie_o;
            end
            12'h305: begin
                csr_rdata = mtvec_o;
            end
            12'h340: begin
                csr_rdata = mscratch_o;
            end
            12'h341: begin
                csr_rdata = mepc_o;
            end
            12'h342: begin
                csr_rdata = mcause_o;
            end
            12'h344: begin
                csr_rdata = mip_o;
            end
            default: begin
                csr_rdata = 32'h0000_0000;
            end
        endcase
    end
endmodule