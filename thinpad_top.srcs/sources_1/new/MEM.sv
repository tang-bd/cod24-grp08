`include "./common/constants.svh"
module MEM(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire [4:0] inst_op_i,
    input wire [2:0] inst_type_i,
    input wire [31:0] alu_y_i,
    input wire [31:0] rf_rdata_b_i,

    output reg [31:0] rf_wdata_o,
    output reg rf_we_o,

    input reg [63:0] mtime_i,
    output reg [63:0] mtime_o,
    output reg [31:0] mtime0_o,
    output reg mtime0_we,
    output reg [31:0] mtime1_o,
    output reg mtime1_we,

    input reg [63:0] mtimecmp_i,
    output reg [63:0] mtimecmp_o,
    output reg [31:0] mtimecmp0_o,
    output reg mtimecmp0_we,
    output reg [31:0] mtimecmp1_o,
    output reg mtimecmp1_we,

    output reg fence_i_o,
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [3:0] wb_sel_o,
    output reg wb_we_o
);
    reg [31:0] rf_wdata_reg;
    reg [6:0] time_reg;
    reg data_ready;

    always_comb begin
        if (wb_ack_i) begin
            case (inst_op_i)
                LB: begin
                    rf_wdata_o = (wb_dat_i >> 8 * (wb_adr_o[1:0]));
                end
                default: begin
                    rf_wdata_o = wb_dat_i;
                end
            endcase
        end else begin
            rf_wdata_o = rf_wdata_reg;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            rf_wdata_reg <= 32'h0;
            time_reg <= 7'h0;
            data_ready <= 0;
            rf_we_o <= 0;
        end else begin
            time_reg <= (time_reg + 1) % 10000;
            mtime0_we <= 0;
            mtime1_we <= 0;
            mtimecmp0_we <= 0;
            mtimecmp1_we <= 0;
            if (stall_i) begin
                if (!data_ready) begin
                    case (inst_type_i)
                        R_TYPE: begin
                            rf_we_o <= 1;
                            fence_i_o <= 0;
                            
                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_adr_o <= 32'h0;
                            wb_dat_o <= 32'h0;
                            wb_sel_o <= 4'b1111;
                            wb_we_o <= 0;
                        end
                        I_TYPE: begin
                            case (inst_op_i)
                                ADDI: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                ANDI: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                ORI: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                SLLI: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                SRLI: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                LB: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 1;
                                    wb_stb_o <= 1;
                                    wb_adr_o <= alu_y_i;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 1 << (alu_y_i[1:0]);
                                    wb_we_o <= 0;
                                end
                                LW: begin
                                    if (alu_y_i == `CLINT_MTIME || alu_y_i == `CLINT_MTIME + 4 || alu_y_i == `CLINT_MTIMECMP || alu_y_i == `CLINT_MTIMECMP + 4) begin
                                        rf_we_o <= 0;
                                        fence_i_o <= 0;
                                        
                                        wb_cyc_o <= 0;
                                        wb_stb_o <= 0;
                                        wb_adr_o <= 32'h0;
                                        wb_dat_o <= 32'h0;
                                        wb_sel_o <= 4'b1111;
                                        wb_we_o <= 0;

                                        data_ready <= 1;
                                        if (alu_y_i == `CLINT_MTIME) begin
                                            rf_wdata_reg <= mtime_i[31:0];
                                        end else if (alu_y_i == `CLINT_MTIME + 4) begin
                                            rf_wdata_reg <= mtime_i[63:32];
                                        end else if (alu_y_i == `CLINT_MTIMECMP) begin
                                            rf_wdata_reg <= mtimecmp_i[31:0];
                                        end else if (alu_y_i == `CLINT_MTIMECMP + 4) begin
                                            rf_wdata_reg <= mtimecmp_i[63:32];
                                        end else begin
                                            rf_wdata_reg <= wb_dat_i;
                                        end
                                    end else begin
                                        rf_we_o <= 1;
                                        fence_i_o <= 0;
                                        
                                        wb_cyc_o <= 1;
                                        wb_stb_o <= 1;
                                        wb_adr_o <= alu_y_i;
                                        wb_dat_o <= 32'h0;
                                        wb_sel_o <= 4'b1111;
                                        wb_we_o <= 0;
                                    end
                                end
                                JALR: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= alu_y_i;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                PCNT: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                CTZ: begin
                                    rf_we_o <= 1;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                FENCE_I: begin
                                    rf_we_o <= 0;
                                    fence_i_o <= 1;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                                default: begin
                                    rf_we_o <= 0;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                            endcase
                        end
                        S_TYPE: begin
                            case (inst_op_i)
                                SB: begin
                                    rf_we_o <= 0;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 1;
                                    wb_stb_o <= 1;
                                    wb_adr_o <= alu_y_i;
                                    wb_dat_o <= rf_rdata_b_i;
                                    wb_sel_o <= 1 << (alu_y_i[1:0]);
                                    wb_we_o <= 1;
                                end
                                SW: begin
                                    if (alu_y_i == `CLINT_MTIME) begin
                                        mtime0_o <= rf_rdata_b_i;
                                        mtime0_we <= 1;

                                        data_ready <= 1;
                                    end else if (alu_y_i == `CLINT_MTIME + 4) begin
                                        mtime1_o <= rf_rdata_b_i;
                                        mtime1_we <= 1;

                                        data_ready <= 1;
                                    end else if (alu_y_i == `CLINT_MTIMECMP) begin
                                        mtimecmp0_o <= rf_rdata_b_i;
                                        mtimecmp0_we <= 1;

                                        data_ready <= 1;
                                    end else if (alu_y_i == `CLINT_MTIMECMP + 4) begin
                                        mtimecmp1_o <= rf_rdata_b_i;
                                        mtimecmp1_we <= 1;

                                        data_ready <= 1;
                                    end else begin
                                        rf_we_o <= 0;
                                        fence_i_o <= 0;
                                        
                                        wb_cyc_o <= 1;
                                        wb_stb_o <= 1;
                                        wb_adr_o <= alu_y_i;
                                        wb_dat_o <= rf_rdata_b_i;
                                        wb_sel_o <= 4'b1111;
                                        wb_we_o <= 1;
                                    end
                                end
                                default: begin
                                    rf_we_o <= 0;
                                    fence_i_o <= 0;
                                    
                                    wb_cyc_o <= 0;
                                    wb_stb_o <= 0;
                                    wb_adr_o <= 32'h0;
                                    wb_dat_o <= 32'h0;
                                    wb_sel_o <= 4'b1111;
                                    wb_we_o <= 0;
                                end
                            endcase
                        end
                        B_TYPE: begin
                            rf_we_o <= 0;
                            fence_i_o <= 0;
                            
                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_adr_o <= 32'h0;
                            wb_dat_o <= 32'h0;
                            wb_sel_o <= 4'b1111;
                            wb_we_o <= 0;
                        end
                        U_TYPE: begin
                            rf_we_o <= 1;
                            fence_i_o <= 0;
                            
                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_adr_o <= 32'h0;
                            wb_dat_o <= 32'h0;
                            wb_sel_o <= 4'b1111;
                            wb_we_o <= 0;
                        end
                        J_TYPE: begin
                            rf_we_o <= 1;
                            fence_i_o <= 0;
                            
                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_adr_o <= 32'h0;
                            wb_dat_o <= 32'h0;
                            wb_sel_o <= 4'b1111;
                            wb_we_o <= 0;
                        end
                        default: begin
                            rf_we_o <= 0;
                            fence_i_o <= 0;
                            
                            wb_cyc_o <= 0;
                            wb_stb_o <= 0;
                            wb_adr_o <= 32'h0;
                            wb_dat_o <= 32'h0;
                            wb_sel_o <= 4'b1111;
                            wb_we_o <= 0;
                        end
                    endcase
                end
            end else begin
                data_ready <= 0;

                if (time_reg == 9999) begin
                    mtime_o <= (mtime_i % (1 << 63)) + 1;
                    mtime0_we <= 1;
                    mtime1_we <= 1;
                end
            end

            if (wb_ack_i) begin
                case (inst_op_i)
                    LB: begin
                        rf_wdata_reg <= (wb_dat_i >> 8 * (wb_adr_o[1:0]));
                    end
                    default: begin
                        rf_wdata_reg <= wb_dat_i;
                    end
                endcase
                if (stall_i) begin
                    data_ready <= 1;
                end
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;
                wb_we_o <= 1'b0;
            end
        end
    end
endmodule