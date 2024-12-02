`include "./common/constants.svh"
module EX(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,

    input wire [31:0] pc_i,
    input wire [4:0] rf_raddr_a_i,
    input wire [31:0] rf_rdata_a_i,
    input wire [4:0] rf_raddr_b_i,
    input wire [31:0] rf_rdata_b_i,
    input wire [4:0] inst_op_i,
    input wire [2:0] inst_type_i,
    input wire [31:0] imm_gen_data_i,

    // EX_MEM forwarding
    input wire [4:0] rf_waddr_ex_mem_i,
    input wire [31:0] alu_y_ex_mem_i,
    input wire rf_we_mem_i,

    // MEM_WB forwarding
    input wire [4:0] rf_waddr_i,
    input wire [31:0] rf_wdata_i,
    input wire rf_we_i,

    output reg [11:0] csr_raddr_o,
    input wire [31:0] csr_rdata_i,
    output reg [11:0] csr_waddr_o,
    output reg [31:0] csr_wdata_o,
    output reg csr_we_o,

    output reg jump_o,
    output reg [31:0] jump_addr_o,
    output reg [2:0] alu_op_o,
    output reg [31:0] alu_a_o,
    output reg [31:0] alu_b_o,
    output reg [31:0] rf_rdata_b_o
);
    logic [31:0] rf_rdata_a;
    logic [31:0] csr_rdata_reg;

    always_comb begin
        // We prioritize EX_MEM forwarding over MEM_WB forwarding
        if (rf_we_mem_i && rf_waddr_ex_mem_i != 0 && rf_waddr_ex_mem_i == rf_raddr_a_i) begin
            rf_rdata_a = alu_y_ex_mem_i; // EX_MEM forwarding
        end else if (rf_we_i && rf_waddr_i != 0 && rf_waddr_i == rf_raddr_a_i) begin
            rf_rdata_a = rf_wdata_i; // MEM_WB forwarding
        end else begin
            rf_rdata_a = rf_rdata_a_i; // No forwarding
        end
        if (rf_we_mem_i && rf_waddr_ex_mem_i != 0 && rf_waddr_ex_mem_i == rf_raddr_b_i) begin
            rf_rdata_b_o = alu_y_ex_mem_i; // EX_MEM forwarding
        end else if (rf_we_i && rf_waddr_i != 0 && rf_waddr_i == rf_raddr_b_i) begin
            rf_rdata_b_o = rf_wdata_i; // MEM_WB forwarding
        end else begin
            rf_rdata_b_o = rf_rdata_b_i;
        end

        case (inst_type_i)
            R_TYPE: begin
                jump_o = 0;
                jump_addr_o = pc_i;
                case (inst_op_i)
                    ADD: alu_op_o = ALU_ADD;
                    SLTU: alu_op_o = ALU_SLTU;
                    AND: alu_op_o = ALU_AND;
                    OR: alu_op_o = ALU_OR;
                    XOR: alu_op_o = ALU_XOR;
                    default: alu_op_o = ALU_ADD;
                endcase
                alu_a_o = rf_rdata_a;
                alu_b_o = rf_rdata_b_o;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
            I_TYPE: begin
                case (inst_op_i)
                    ADDI: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    ANDI: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_AND;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    ORI: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_OR;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    SLLI: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_SLL;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    SRLI: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_SRL;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    LB: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    LW: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = rf_rdata_a;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    JALR: begin
                        jump_o = 1;
                        jump_addr_o = rf_rdata_a + imm_gen_data_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = pc_i;
                        alu_b_o = imm_gen_data_i;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                    CSRRW: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = csr_rdata_reg;
                        alu_b_o = 0;

                        csr_raddr_o = imm_gen_data_i;
                        csr_waddr_o = imm_gen_data_i;
                        csr_wdata_o = rf_rdata_a;
                        csr_we_o = 1;
                    end
                    CSRRW: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = csr_rdata_reg;
                        alu_b_o = 0;

                        csr_raddr_o = imm_gen_data_i;
                        csr_waddr_o = imm_gen_data_i;
                        csr_wdata_o = csr_rdata_reg & rf_rdata_a;
                        csr_we_o = 1;
                    end
                    CSRRC: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = csr_rdata_reg;
                        alu_b_o = 0;

                        csr_raddr_o = imm_gen_data_i;
                        csr_waddr_o = imm_gen_data_i;
                        csr_wdata_o = csr_rdata_reg & ~rf_rdata_a;
                        csr_we_o = 1;
                    end
                    default: begin
                        jump_o = 0;
                        jump_addr_o = pc_i;
                        alu_op_o = ALU_ADD;
                        alu_a_o = 0;
                        alu_b_o = 0;

                        csr_raddr_o = 0;
                        csr_waddr_o = 0;
                        csr_wdata_o = 0;
                        csr_we_o = 0;
                    end
                endcase
            end
            S_TYPE: begin
                jump_o = 0;
                jump_addr_o = pc_i;
                case (inst_op_i)
                    SB: alu_op_o = ALU_ADD;
                    SW: alu_op_o = ALU_ADD;
                    default: alu_op_o = ALU_ADD;
                endcase
                alu_a_o = rf_rdata_a;
                alu_b_o = imm_gen_data_i;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
            B_TYPE: begin
                case (inst_op_i)
                    BEQ: jump_o = rf_rdata_a == rf_rdata_b_o;
                    BNE: jump_o = rf_rdata_a != rf_rdata_b_o;
                    default: jump_o = 0;
                endcase
                jump_addr_o = pc_i + imm_gen_data_i;
                alu_op_o = ALU_ADD;
                alu_a_o = rf_rdata_a;
                alu_b_o = rf_rdata_b_o;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
            U_TYPE: begin
                jump_o = 0;
                jump_addr_o = pc_i;
                alu_op_o = ALU_ADD;
                case (inst_op_i)
                    LUI: alu_a_o = 0;
                    AUIPC: alu_a_o = pc_i;
                    default: alu_a_o = 0;
                endcase
                alu_b_o = imm_gen_data_i;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
            J_TYPE: begin
                jump_o = 1;
                jump_addr_o = pc_i + imm_gen_data_i;
                alu_op_o = ALU_ADD;
                alu_a_o = pc_i;
                alu_b_o = imm_gen_data_i;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
            default: begin
                jump_o = 0;
                jump_addr_o = pc_i;
                alu_op_o = ALU_ADD;
                alu_a_o = 0;
                alu_b_o = 0;

                csr_raddr_o = 0;
                csr_waddr_o = 0;
                csr_wdata_o = 0;
                csr_we_o = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            csr_rdata_reg <= 0;
        end else begin
            if (stall_i) begin

            end else if (bubble_i) begin
                csr_rdata_reg <= 0;
            end else begin
                case (inst_op_i)
                CSRRW: begin
                    csr_rdata_reg <= csr_rdata_i;
                end
                endcase
            end
        end
    end

endmodule