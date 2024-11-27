`default_nettype none
module ALU_32(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op,
    output reg [31:0] y
);
    typedef enum logic [4:0] {
        ___,
        _ADD,
        _SUB,
        _AND,
        _OR,
        _XOR,
        _NOT,
        _SLL,
        _SRL,
        _SRA,
        _ROL
    } op_code;
    always_comb begin
        case(op)
            _ADD: y = a + b;
            _SUB: y = a - b;
            _AND: y = a & b;
            _OR: y = a | b;
            _XOR: y = a ^ b;
            _NOT: y = ~a;
            _SLL: y = a << b%32;
            _SRL: y = a >> b%32;
            _SRA: y = ($signed(a)) >>> b%32;
            _ROL: y = a << b%32 | a >> (32 - b%32);
            default: y = 32'b0;
        endcase
    end
endmodule
