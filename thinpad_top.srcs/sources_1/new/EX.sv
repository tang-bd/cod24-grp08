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
    input wire csr_we_ex_mem_i,

    input reg [1:0] privilege_mode_i,
    output reg [1:0] privilege_mode_o,
    output reg privilege_mode_we,

    output reg [11:0] csr_raddr_o,
    input wire [31:0] csr_rdata_i,
    output reg [11:0] csr_waddr_o,
    output reg [31:0] csr_wdata_o,
    output reg csr_we_o,

    input wire [63:0] mtime_i,
    input wire [63:0] mtimecmp_i,

    input wire [31:0] mstatus_i,
    output reg [31:0] mstatus_o,
    output reg mstatus_we,

    input wire [31:0] mie_i,
    output reg [31:0] mie_o,
    output reg mie_we,

    input wire [31:0] mtvec_i,
    output reg [31:0] mtvec_o,
    output reg mtvec_we,

    input wire [31:0] mscratch_i,
    output reg [31:0] mscratch_o,
    output reg mscratch_we,

    input wire [31:0] mepc_i,
    output reg [31:0] mepc_o,
    output reg mepc_we,

    input wire [31:0] mcause_i,
    output reg [31:0] mcause_o,
    output reg mcause_we,

    input wire [31:0] mip_i,
    output reg [31:0] mip_o,
    output reg mip_we,

    output reg jump_o,
    output reg [31:0] jump_addr_o,
    output reg [3:0] alu_op_o,
    output reg [31:0] alu_a_o,
    output reg [31:0] alu_b_o,
    output reg [31:0] rf_rdata_b_o
);
    logic [31:0] rf_rdata_a;
    logic [31:0] csr_rdata_reg;

    always_comb begin
        // We prioritize EX_MEM forwarding over MEM_WB forwarding
        if ((rf_we_mem_i || csr_we_ex_mem_i) && rf_waddr_ex_mem_i != 0 && rf_waddr_ex_mem_i == rf_raddr_a_i) begin
            rf_rdata_a = alu_y_ex_mem_i; // EX_MEM forwarding
        end else if (rf_we_i && rf_waddr_i != 0 && rf_waddr_i == rf_raddr_a_i) begin
            rf_rdata_a = rf_wdata_i; // MEM_WB forwarding
        end else begin
            rf_rdata_a = rf_rdata_a_i; // No forwarding
        end
        if ((rf_we_mem_i || csr_we_ex_mem_i) && rf_waddr_ex_mem_i != 0 && rf_waddr_ex_mem_i == rf_raddr_b_i) begin
            rf_rdata_b_o = alu_y_ex_mem_i; // EX_MEM forwarding
        end else if (rf_we_i && rf_waddr_i != 0 && rf_waddr_i == rf_raddr_b_i) begin
            rf_rdata_b_o = rf_wdata_i; // MEM_WB forwarding
        end else begin
            rf_rdata_b_o = rf_rdata_b_i;
        end

        csr_raddr_o = 0;
        csr_waddr_o = 0;
        csr_wdata_o = 0;

        privilege_mode_o = 0;
        privilege_mode_we = 0;
        mstatus_o = 0;
        mstatus_we = 0;
        mie_o = 0;
        mie_we = 0;
        mtvec_o = 0;
        mtvec_we = 0;
        mscratch_o = 0;
        mscratch_we = 0;
        mepc_o = 0;
        mepc_we = 0;
        mcause_o = 0;
        mcause_we = 0;
        mip_o = 0;
        mip_we = 0;

        if (mtime_i > mtimecmp_i && mie_i == (1 << 7) && privilege_mode_i == 2'b00) begin
            jump_o = 1;
            jump_addr_o = mtvec_i;
            alu_op_o = ALU_ADD;
            alu_a_o = 0;
            alu_b_o = 0;

            privilege_mode_o = 2'b11;
            privilege_mode_we = 1;
            mepc_o = pc_i;
            mepc_we = 1;
            mcause_o = `EX_INT_FLAG;
            mcause_we = 1;
        end else begin
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
                        SBSET: alu_op_o = ALU_SBSET;
                        default: alu_op_o = ALU_ADD;
                    endcase
                    alu_a_o = rf_rdata_a;
                    alu_b_o = rf_rdata_b_o;
                end
                I_TYPE: begin
                    case (inst_op_i)
                        ADDI: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        ANDI: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_AND;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        ORI: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_OR;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        SLLI: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_SLL;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        SRLI: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_SRL;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        LB: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        LW: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = imm_gen_data_i;
                        end
                        JALR: begin
                            jump_o = 1;
                            jump_addr_o = rf_rdata_a + imm_gen_data_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = pc_i;
                            alu_b_o = imm_gen_data_i;
                        end
                        PCNT: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_PCNT;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = 0;
                        end
                        CTZ: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_CTZ;
                            alu_a_o = rf_rdata_a;
                            alu_b_o = 0;
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
                        end
                        CSRRS: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = csr_rdata_reg;
                            alu_b_o = 0;

                            csr_raddr_o = imm_gen_data_i;
                            csr_waddr_o = imm_gen_data_i;
                            csr_wdata_o = csr_rdata_reg | rf_rdata_a;
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
                        end
                        ECALL: begin
                            jump_o = 1;
                            jump_addr_o = mtvec_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = 0;
                            alu_b_o = 0;

                            
                            privilege_mode_o = 2'b11;
                            privilege_mode_we = 1;
                            mepc_o = pc_i;
                            mepc_we = 1;
                            mcause_o = `EX_ECALL_U;
                            mcause_we = 1;
                        end
                        EBREAK: begin
                            jump_o = 1;
                            jump_addr_o = mtvec_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = 0;
                            alu_b_o = 0;

                            privilege_mode_o = 2'b11;
                            privilege_mode_we = 1;
                            mepc_o = pc_i;
                            mepc_we = 1;
                            mcause_o = `EX_BREAK;
                            mcause_we = 1;
                        end
                        MRET: begin
                            jump_o = 1;
                            jump_addr_o = mepc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = 0;
                            alu_b_o = 0;

                            privilege_mode_o = mstatus_i[12:11];
                            privilege_mode_we = 1;
                        end
                        default: begin
                            jump_o = 0;
                            jump_addr_o = pc_i;
                            alu_op_o = ALU_ADD;
                            alu_a_o = 0;
                            alu_b_o = 0;
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
                end
                J_TYPE: begin
                    jump_o = 1;
                    jump_addr_o = pc_i + imm_gen_data_i;
                    alu_op_o = ALU_ADD;
                    alu_a_o = pc_i;
                    alu_b_o = imm_gen_data_i;
                end
                default: begin
                    jump_o = 0;
                    jump_addr_o = pc_i;
                    alu_op_o = ALU_ADD;
                    alu_a_o = 0;
                    alu_b_o = 0;
                end
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            csr_rdata_reg <= 0;
            csr_we_o <= 0;
        end else begin
            if (stall_i) begin
                case (inst_op_i)
                    CSRRW: begin
                        csr_rdata_reg <= csr_rdata_i;
                        csr_we_o <= 1;
                    end
                    CSRRS: begin
                        csr_rdata_reg <= csr_rdata_i;
                        csr_we_o <= 1;
                    end
                    CSRRC: begin
                        csr_rdata_reg <= csr_rdata_i;
                        csr_we_o <= 1;
                    end
                endcase
            end else begin
                csr_rdata_reg <= 0;
                csr_we_o <= 0;
            end
        end
    end

endmodule