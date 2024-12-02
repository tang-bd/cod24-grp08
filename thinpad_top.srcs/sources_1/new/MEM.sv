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

    output reg fence_o,
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
            rf_we_o <= 0;
        end else begin
            if (stall_i) begin
                case (inst_type_i)
                    R_TYPE: begin
                        rf_we_o = 1;
                        fence_o = 0;
                        wb_cyc_o = 0;
                        wb_stb_o = 0;
                        wb_adr_o = 32'h0;
                        wb_dat_o = 32'h0;
                        wb_sel_o = 4'b1111;
                        wb_we_o = 0;
                    end
                    I_TYPE: begin
                        case (inst_op_i)
                            ADDI: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            ANDI: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            ORI: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            SLLI: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            SRLI: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            LB: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 1;
                                wb_stb_o = 1;
                                wb_adr_o = alu_y_i;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 1 << (alu_y_i[1:0]);
                                wb_we_o = 0;
                            end
                            LW: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 1;
                                wb_stb_o = 1;
                                wb_adr_o = alu_y_i;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            JALR: begin
                                rf_we_o = 1;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = alu_y_i;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            FENCE_I: begin
                                rf_we_o = 0;
                                fence_o = 1;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                            default: begin
                                rf_we_o = 0;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                        endcase
                    end
                    S_TYPE: begin
                        case (inst_op_i)
                            SB: begin
                                rf_we_o = 0;
                                fence_o = 0;
                                wb_cyc_o = 1;
                                wb_stb_o = 1;
                                wb_adr_o = alu_y_i;
                                wb_dat_o = rf_rdata_b_i;
                                wb_sel_o = 1 << (alu_y_i[1:0]);
                                wb_we_o = 1;
                            end
                            SW: begin
                                rf_we_o = 0;
                                fence_o = 0;
                                wb_cyc_o = 1;
                                wb_stb_o = 1;
                                wb_adr_o = alu_y_i;
                                wb_dat_o = rf_rdata_b_i;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 1;
                            end
                            default: begin
                                rf_we_o = 0;
                                fence_o = 0;
                                wb_cyc_o = 0;
                                wb_stb_o = 0;
                                wb_adr_o = 32'h0;
                                wb_dat_o = 32'h0;
                                wb_sel_o = 4'b1111;
                                wb_we_o = 0;
                            end
                        endcase
                    end
                    B_TYPE: begin
                        rf_we_o = 0;
                        fence_o = 0;
                        wb_cyc_o = 0;
                        wb_stb_o = 0;
                        wb_adr_o = 32'h0;
                        wb_dat_o = 32'h0;
                        wb_sel_o = 4'b1111;
                        wb_we_o = 0;
                    end
                    U_TYPE: begin
                        rf_we_o = 1;
                        fence_o = 0;
                        wb_cyc_o = 0;
                        wb_stb_o = 0;
                        wb_adr_o = 32'h0;
                        wb_dat_o = 32'h0;
                        wb_sel_o = 4'b1111;
                        wb_we_o = 0;
                    end
                    J_TYPE: begin
                        rf_we_o = 1;
                        fence_o = 0;
                        wb_cyc_o = 0;
                        wb_stb_o = 0;
                        wb_adr_o = 32'h0;
                        wb_dat_o = 32'h0;
                        wb_sel_o = 4'b1111;
                        wb_we_o = 0;
                    end
                    default: begin
                        rf_we_o = 0;
                        fence_o = 0;
                        wb_cyc_o = 0;
                        wb_stb_o = 0;
                        wb_adr_o = 32'h0;
                        wb_dat_o = 32'h0;
                        wb_sel_o = 4'b1111;
                        wb_we_o = 0;
                    end
                endcase
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
                wb_cyc_o = 1'b0;
                wb_stb_o = 1'b0;
                wb_we_o = 1'b0;
            end
        end
    end
endmodule