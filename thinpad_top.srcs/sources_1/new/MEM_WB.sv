`include "./common/constants.svh"
module MEM_WB(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,
    input wire [31:0] pc_i,
    input wire [4:0] inst_op_i,
    input wire [2:0] inst_type_i,
    input wire [31:0] alu_y_i,
    input wire [4:0] rf_waddr_i,
    input wire [31:0] rf_wdata_i,

    output reg [4:0] rf_waddr_o,
    output reg [31:0] rf_wdata_o,
    output reg rf_we_o
);
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            rf_waddr_o <= 32'h0;
            rf_wdata_o <= 32'h0;
            rf_we_o <= 0;
        end else begin
            if (stall_i) begin
                // stall
            end else if (bubble_i) begin
                rf_waddr_o <= 32'h0;
                rf_wdata_o <= 32'h0;
                rf_we_o <= 0;
            end else begin
                rf_waddr_o <= rf_waddr_i;

                case (inst_type_i)
                    R_TYPE: begin
                        rf_wdata_o <= alu_y_i;
                        rf_we_o <= 1;
                    end
                    I_TYPE: begin
                        case (inst_op_i)
                            ADDI: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            ANDI: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            ORI: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            SLLI: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            SRLI: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            LB: begin
                                rf_wdata_o <= {{24{rf_wdata_i[7]}}, rf_wdata_i[7:0]};
                                rf_we_o <= 1;
                            end
                            LW: begin
                                rf_wdata_o <= rf_wdata_i;
                                rf_we_o <= 1;
                            end
                            JALR: begin
                                rf_wdata_o <= pc_i + 4;
                                rf_we_o <= 1;
                            end
                            PCNT: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            CTZ: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            CSRRW: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 1;
                            end
                            default: begin
                                rf_wdata_o <= alu_y_i;
                                rf_we_o <= 0;
                            end
                        endcase
                    end
                    U_TYPE: begin
                        rf_wdata_o <= alu_y_i;
                        rf_we_o <= 1;
                    end
                    J_TYPE: begin
                        rf_wdata_o <= pc_i + 4;
                        rf_we_o <= 1;
                    end
                    default: begin
                        rf_wdata_o <= alu_y_i;
                        rf_we_o <= 0;
                    end
                endcase
            end
        end
    end
endmodule