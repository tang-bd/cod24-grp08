`include "./common/constants.svh"
module ID_EX(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,
    input wire [31:0] pc_i,
    input wire [31:0] inst_i,

    output reg [31:0] pc_o,
    output reg [4:0] inst_op_o,
    output reg [2:0] inst_type_o,
    output reg [4:0] rf_raddr_a_o,
    output reg [4:0] rf_raddr_b_o,
    output reg [4:0] rf_waddr_o,
    output reg [31:0] imm_gen_inst_o,
    output reg [2:0] imm_gen_type_o,
    output reg read_mem_o
);
    reg [31:0] inst_reg;

    always_comb begin
        case(inst_reg[6:0])
            7'b0110011: begin
                inst_type_o = R_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = ADD;
                    3'b001: inst_op_o = SBSET;
                    3'b011: inst_op_o = SLTU;
                    3'b111: inst_op_o = AND;
                    3'b110: inst_op_o = OR;
                    3'b100: inst_op_o = XOR;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b0010011: begin
                inst_type_o = I_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = ADDI;
                    3'b111: inst_op_o = ANDI;
                    3'b110: inst_op_o = ORI;
                    3'b001: begin
                        if(inst_reg[31:25]==7'b0000000) begin
                            inst_op_o = SLLI;
                        end
                        else if(inst_reg[31:25]==7'b0110000) begin
                            if(inst_reg[24:20]==5'b00010) begin
                                inst_op_o = PCNT;
                            end
                            else if(inst_reg[24:20]==5'b00001) begin
                                inst_op_o = CTZ;
                            end
                            else begin
                                inst_op_o = UNKNOWN_INST_OP;
                            end
                        end
                        else begin
                            inst_op_o = UNKNOWN_INST_OP;
                        end
                    end
                    3'b101: inst_op_o = SRLI;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b0000011: begin
                inst_type_o = I_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = LB;
                    3'b010: inst_op_o = LW;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b1100111: begin
                inst_type_o = I_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = JALR;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b0001111: begin
                inst_type_o = I_TYPE;
                inst_op_o = FENCE_I;
            end
            7'b1110011: begin
                inst_type_o = I_TYPE;
                case (inst_reg[14:12])
                    3'b000: begin
                        case (inst_reg[31:20])
                            12'h000: inst_op_o = ECALL;
                            12'h001: inst_op_o = EBREAK;
                            12'h302: inst_op_o = MRET;
                            default: inst_op_o = UNKNOWN_INST_OP;
                        endcase
                    end
                    3'b001: inst_op_o = CSRRW;
                    3'b010: inst_op_o = CSRRS;
                    3'b011: inst_op_o = CSRRC;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b0100011: begin
                inst_type_o = S_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = SB;
                    3'b010: inst_op_o = SW;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b1100011: begin
                inst_type_o = B_TYPE;
                case(inst_reg[14:12])
                    3'b000: inst_op_o = BEQ;
                    3'b001: inst_op_o = BNE;
                    default: inst_op_o = UNKNOWN_INST_OP;
                endcase
            end
            7'b0110111: begin
                inst_type_o = U_TYPE;
                inst_op_o = LUI;
            end
            7'b0010111: begin
                inst_type_o = U_TYPE;
                inst_op_o = AUIPC;
            end
            7'b1101111: begin
                inst_type_o = J_TYPE;
                inst_op_o = JAL;
            end
            default: begin
                inst_type_o = UNKNOWN_INST_TYPE;
                inst_op_o = UNKNOWN_INST_OP;
            end
        endcase

        case (inst_type_o)
            I_TYPE: begin
                case (inst_op_o)
                    LB: begin
                        read_mem_o = 1;
                    end
                    LW: begin
                        read_mem_o = 1;
                    end
                    default: begin
                        read_mem_o = 0;
                    end
                endcase
            end
            default: begin
                read_mem_o = 0;
            end
        endcase

        rf_raddr_a_o = inst_reg[19:15];
        rf_raddr_b_o = inst_reg[24:20];
        rf_waddr_o = inst_reg[11:7];

        imm_gen_inst_o = inst_reg;
        imm_gen_type_o = inst_type_o;
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_o <= 32'h0;
            inst_reg <= 32'h0;
        end else begin
            if (stall_i) begin

            end else if (bubble_i) begin
                pc_o <= 32'h0;
                inst_reg <= 32'h0;
            end else begin
                pc_o <= pc_i;
                inst_reg <= inst_i;
            end
        end
    end
endmodule