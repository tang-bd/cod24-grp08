`include "./common/constants.svh"
module csr(
    input wire clk_i,
    input wire rst_i,
    input wire [11:0] csr_raddr,
    output reg [31:0] csr_rdata,
    input wire [11:0] csr_waddr,
    input reg [31:0] csr_wdata,
    input wire csr_we,

    input wire [1:0] privilege_mode_i,
    output reg [1:0] privilege_mode_o,
    input wire privilege_mode_we,

    input wire [31:0] mstatus_i,
    output reg [31:0] mstatus_o,
    input wire mstatus_we,

    input wire [31:0] mie_i,
    output reg [31:0] mie_o,
    input wire mie_we,

    input wire [31:0] mtvec_i,
    output reg [31:0] mtvec_o,
    input wire mtvec_we,

    input wire [31:0] mscratch_i,
    output reg [31:0] mscratch_o,
    input wire mscratch_we,

    input wire [31:0] mepc_i,
    output reg [31:0] mepc_o,
    input wire mepc_we,

    input wire [31:0] mcause_i,
    output reg [31:0] mcause_o,
    input wire mcause_we,

    input wire [31:0] mip_i,
    output reg [31:0] mip_o,
    input wire mip_we,

    output reg [31:0] satp_o,

    output reg [63:0] mtime_o,
    input wire [63:0] mtime_i,
    input wire [31:0] mtime0_i,
    input wire mtime0_we,
    input wire [31:0] mtime1_i,
    input wire mtime1_we,

    output reg [63:0] mtimecmp_o,
    input wire [63:0] mtimecmp_i,
    input wire [31:0] mtimecmp0_i,
    input wire mtimecmp0_we,
    input wire [31:0] mtimecmp1_i,
    input wire mtimecmp1_we
);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            privilege_mode_o <= 2'b11;
            mstatus_o <= 32'h0000_0000;
            mie_o <= 32'h0000_0000;
            mtvec_o <= 32'h0000_0000;
            mscratch_o <= 32'h0000_0000;
            mepc_o <= 32'h0000_0000;
            mcause_o <= 32'h0000_0000;
            mip_o <= 32'h0000_0000;
            satp_o <= 32'h0000_0000;

            mtime_o <= 64'h0000_0000_0000_0000;
            mtimecmp_o <= 64'h0000_0000_0000_0000;
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
                endcase
            end

            if (privilege_mode_we) begin
                privilege_mode_o <= privilege_mode_i;
            end

            if (mstatus_we) begin
                mstatus_o <= mstatus_i;
            end

            if (mie_we) begin
                mie_o <= mie_i;
            end

            if (mtvec_we) begin
                mtvec_o <= mtvec_i;
            end

            if (mscratch_we) begin
                mscratch_o <= mscratch_i;
            end

            if (mepc_we) begin
                mepc_o <= mepc_i;
            end

            if (mcause_we) begin
                mcause_o <= mcause_i;
            end

            if (mip_we) begin
                mip_o <= mip_i;
            end

            if (mtime0_we && mtime1_we) begin
                mtime_o <= mtime_i;
            end else if (mtime0_we) begin
                mtime_o[31:0] <= mtime0_i;
            end else if (mtime1_we) begin
                mtime_o[63:32] <= mtime1_i;
            end

            if (mtimecmp0_we && mtimecmp1_we) begin
                mtimecmp_o <= mtimecmp_i;
            end else if (mtimecmp0_we) begin
                mtimecmp_o[31:0] <= mtimecmp0_i;
            end else if (mtimecmp1_we) begin
                mtimecmp_o[63:32] <= mtimecmp1_i;
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