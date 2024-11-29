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

typedef enum logic [2:0] {
    ALU_ADD = 3'b000,
    ALU_SLL = 3'b001,
    ALU_SLT = 3'b010,
    ALU_SLTU = 3'b011,
    ALU_XOR = 3'b100,
    ALU_SRL = 3'b101,
    ALU_OR = 3'b110,
    ALU_AND = 3'b111
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
    UNKNOWN_INST_OP = 19
} inst_op_t;

`endif