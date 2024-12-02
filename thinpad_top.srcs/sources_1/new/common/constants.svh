`ifndef CONSTANTS_SVH
`define CONSTANTS_SVH

typedef enum logic [2:0] {
    R_TYPE = 0,
    I_TYPE = 1,
    S_TYPE = 2,
    B_TYPE = 3,
    U_TYPE = 4,
    J_TYPE = 5,
    UNKNOWN_INST_TYPE = 6
} inst_type_t;

typedef enum logic [3:0] {
    ALU_ADD = 4'b0000,
    ALU_SLL = 4'b0001,
    ALU_SLT = 4'b0010,
    ALU_SLTU = 4'b0011,
    ALU_XOR = 4'b0100,
    ALU_SRL = 4'b0101,
    ALU_OR = 4'b0110,
    ALU_AND = 4'b0111,
    ALU_PCNT = 4'b1000,
    ALU_CTZ = 4'b1001,
    ALU_SBSET = 4'b1010
} alu_op_t;

typedef enum logic [4:0] {
    ADD = 0,
    ADDI = 1,
    AND = 2,
    ANDI = 3,
    AUIPC = 4,
    BEQ = 5,
    BNE = 6,
    JAL = 7,
    JALR = 8,
    LB = 9,
    LUI = 10,
    LW = 11,
    OR = 12,
    ORI = 13,
    SB = 14,
    SLLI = 15,
    SRLI = 16,
    SW = 17,
    XOR = 18,
    FENCE_I = 19,
    CSRRW = 20,
    CSRRS = 21,
    CSRRC = 22,
    EBREAK = 23,
    ECALL = 24,
    MRET = 25,
    SLTU = 26,
    PCNT = 27,
    CTZ = 28,
    SBSET = 29,
    SFENCE_VMA = 30,
    UNKNOWN_INST_OP = 31
} inst_op_t;

`endif