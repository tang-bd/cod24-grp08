`include "./common/constants.svh"
module cpu (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    input wire [1:0] privilege_mode_i,
    output reg [1:0] privilege_mode_o,
    output reg privilege_mode_we,

    // wishbone
    output reg fence_i_o,
    output reg wbm0_cyc_o,
    output reg wbm0_stb_o,
    input wire wbm0_ack_i,
    output reg [31:0] wbm0_adr_o,
    output reg [31:0] wbm0_dat_o,
    input wire [31:0] wbm0_dat_i,
    output reg [3:0] wbm0_sel_o,
    output reg wbm0_we_o,

    output reg wbm1_cyc_o,
    output reg wbm1_stb_o,
    input wire wbm1_ack_i,
    output reg [31:0] wbm1_adr_o,
    output reg [31:0] wbm1_dat_o,
    input wire [31:0] wbm1_dat_i,
    output reg [3:0] wbm1_sel_o,
    output reg wbm1_we_o,

    // rf
    output reg [4:0] rf_raddr_a_o,
    output reg [4:0] rf_raddr_b_o,
    input wire [31:0] rf_rdata_a_i,
    input wire [31:0] rf_rdata_b_i,
    output reg [4:0] rf_waddr_o,
    output reg [31:0] rf_wdata_o,
    output reg rf_we_o,

    // csr
    output reg [11:0] csr_raddr_o,
    input wire [31:0] csr_rdata_i,
    output reg [11:0] csr_waddr_o,
    output reg [31:0] csr_wdata_o,
    output reg csr_we_o,
    input wire [31:0] mstatus_i,
    output reg [31:0] mstatus_o,
    output wire mstatus_we,
    input wire [31:0] mie_i,
    output reg [31:0] mie_o,
    output wire mie_we,
    input wire [31:0] mtvec_i,
    output reg [31:0] mtvec_o,
    output wire mtvec_we,
    input wire [31:0] mscratch_i,
    output reg [31:0] mscratch_o,
    output wire mscratch_we,
    input wire [31:0] mepc_i,
    output reg [31:0] mepc_o,
    output wire mepc_we,
    input wire [31:0] mcause_i,
    output reg [31:0] mcause_o,
    output wire mcause_we,
    input wire [31:0] mip_i,
    output reg [31:0] mip_o,
    output wire mip_we,
    input wire [63:0] mtime_i,
    output reg [63:0] mtime_o,
    output reg [31:0] mtime0_o,
    output wire mtime0_we,
    output reg [31:0] mtime1_o,
    output wire mtime1_we,
    input wire [63:0] mtimecmp_i,
    output reg [63:0] mtimecmp_o,
    output reg [31:0] mtimecmp0_o,
    output wire mtimecmp0_we,
    output reg [31:0] mtimecmp1_o,
    output wire mtimecmp1_we,

    // alu
    output reg [31:0] alu_a_o,
    output reg [31:0] alu_b_o,
    output reg [3:0] alu_op_o,
    input wire [31:0] alu_y_i,
    
    // imm_gen
    output reg [31:0] imm_gen_inst_o,
    output reg [2:0] imm_gen_type_o,
    input wire [31:0] imm_gen_data_i
);
    logic [31:0] jump_addr;
    logic jump;

    logic stall_if_id, bubble_if_id;

    logic [31:0] pc_if_id, inst_if_id;
    logic [4:0] rf_raddr_a_if_id, rf_raddr_b_if_id;

    IF_ID IF_ID(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall_if_id),
        .bubble_i(bubble_if_id),
        .jump_addr_i(jump_addr),

        .pc_o(pc_if_id),
        .inst_o(inst_if_id),
        .rf_raddr_a_o(rf_raddr_a_if_id),
        .rf_raddr_b_o(rf_raddr_b_if_id),

        .wb_cyc_o(wbm0_cyc_o),
        .wb_stb_o(wbm0_stb_o),
        .wb_ack_i(wbm0_ack_i),
        .wb_adr_o(wbm0_adr_o),
        .wb_dat_o(wbm0_dat_o),
        .wb_dat_i(wbm0_dat_i),
        .wb_sel_o(wbm0_sel_o),
        .wb_we_o(wbm0_we_o)
    );

    logic stall_id_ex, bubble_id_ex;
    logic [31:0] pc_id_ex;
    logic [4:0] rf_waddr_id_ex;
    logic [4:0] inst_op_id_ex;
    logic [2:0] inst_type_id_ex;
    logic read_mem_id_ex;

    ID_EX ID_EX(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall_id_ex),
        .bubble_i(bubble_id_ex),

        .pc_i(pc_if_id),
        .inst_i(inst_if_id),

        .pc_o(pc_id_ex),
        .inst_op_o(inst_op_id_ex),
        .inst_type_o(inst_type_id_ex),
        .rf_raddr_a_o(rf_raddr_a_o),
        .rf_raddr_b_o(rf_raddr_b_o),
        .rf_waddr_o(rf_waddr_id_ex),
        .imm_gen_inst_o(imm_gen_inst_o),
        .imm_gen_type_o(imm_gen_type_o),
        .read_mem_o(read_mem_id_ex)
    );

    logic [31:0] rf_wdata_mem;
    logic rf_we_mem;

    logic stall_ex_mem, bubble_ex_mem;
    logic [31:0] pc_ex_mem, alu_y_ex_mem, rf_rdata_b_mem, rf_rdata_b_ex_mem;
    logic [4:0] rf_waddr_ex_mem;
    logic [4:0] inst_op_ex_mem;
    logic [2:0] inst_type_ex_mem;
    logic csr_we_ex_mem;

    EX EX(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall_ex_mem),
        .bubble_i(bubble_ex_mem),

        .pc_i(pc_id_ex),
        .rf_raddr_a_i(rf_raddr_a_o),
        .rf_rdata_a_i(rf_rdata_a_i),
        .rf_raddr_b_i(rf_raddr_b_o),
        .rf_rdata_b_i(rf_rdata_b_i),
        .inst_op_i(inst_op_id_ex),
        .inst_type_i(inst_type_id_ex),
        .imm_gen_data_i(imm_gen_data_i),

        .rf_waddr_ex_mem_i(rf_waddr_ex_mem),
        .alu_y_ex_mem_i(alu_y_ex_mem),
        .rf_we_mem_i(rf_we_mem),
        .csr_we_ex_mem_i(csr_we_ex_mem),

        .rf_waddr_i(rf_waddr_o),
        .rf_wdata_i(rf_wdata_o),
        .rf_we_i(rf_we_o),

        .privilege_mode_i(privilege_mode_i),
        .privilege_mode_o(privilege_mode_o),
        .privilege_mode_we(privilege_mode_we),

        .csr_raddr_o(csr_raddr_o),
        .csr_rdata_i(csr_rdata_i),
        .csr_waddr_o(csr_waddr_o),
        .csr_wdata_o(csr_wdata_o),
        .csr_we_o(csr_we_o),

        .mtime_i(mtime_i),
        .mtimecmp_i(mtimecmp_i),

        .mstatus_i(mstatus_i),
        .mstatus_o(mstatus_o),
        .mstatus_we(mstatus_we),

        .mie_i(mie_i),
        .mie_o(mie_o),
        .mie_we(mie_we),

        .mtvec_i(mtvec_i),
        .mtvec_o(mtvec_o),
        .mtvec_we(mtvec_we),

        .mscratch_i(mscratch_i),
        .mscratch_o(mscratch_o),
        .mscratch_we(mscratch_we),

        .mepc_i(mepc_i),
        .mepc_o(mepc_o),
        .mepc_we(mepc_we),

        .mcause_i(mcause_i),
        .mcause_o(mcause_o),
        .mcause_we(mcause_we),

        .mip_i(mip_i),
        .mip_o(mip_o),
        .mip_we(mip_we),

        .jump_o(jump),
        .jump_addr_o(jump_addr),
        .alu_op_o(alu_op_o),
        .alu_a_o(alu_a_o),
        .alu_b_o(alu_b_o),
        .rf_rdata_b_o(rf_rdata_b_mem)
    );

    EX_MEM EX_MEM(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall_ex_mem),
        .bubble_i(bubble_ex_mem),

        .pc_i(pc_id_ex),
        .alu_y_i(alu_y_i),
        .rf_rdata_b_i(rf_rdata_b_mem),
        .rf_waddr_i(rf_waddr_id_ex),
        .inst_op_i(inst_op_id_ex),
        .inst_type_i(inst_type_id_ex),

        .pc_o(pc_ex_mem),
        .alu_y_o(alu_y_ex_mem),
        .rf_rdata_b_o(rf_rdata_b_ex_mem),
        .rf_waddr_o(rf_waddr_ex_mem),
        .inst_op_o(inst_op_ex_mem),
        .inst_type_o(inst_type_ex_mem),
        .csr_we_o(csr_we_ex_mem)
    );

    MEM MEM(
        .clk_i(clk_i),
        .rst_i(rst_i),

        .stall_i(stall_ex_mem),

        .inst_op_i(inst_op_ex_mem),
        .inst_type_i(inst_type_ex_mem),
        .alu_y_i(alu_y_ex_mem),
        .rf_rdata_b_i(rf_rdata_b_ex_mem),

        .rf_wdata_o(rf_wdata_mem),
        .rf_we_o(rf_we_mem),

        .mtime_i(mtime_i),
        .mtime_o(mtime_o),
        .mtime0_o(mtime0_o),
        .mtime0_we(mtime0_we),
        .mtime1_o(mtime1_o),
        .mtime1_we(mtime1_we),

        .mtimecmp_i(mtimecmp_i),
        .mtimecmp_o(mtimecmp_o),
        .mtimecmp0_o(mtimecmp0_o),
        .mtimecmp0_we(mtimecmp0_we),
        .mtimecmp1_o(mtimecmp1_o),
        .mtimecmp1_we(mtimecmp1_we),

        .fence_i_o(fence_i_o),
        .wb_cyc_o(wbm1_cyc_o),
        .wb_stb_o(wbm1_stb_o),
        .wb_ack_i(wbm1_ack_i),
        .wb_adr_o(wbm1_adr_o),
        .wb_dat_o(wbm1_dat_o),
        .wb_dat_i(wbm1_dat_i),
        .wb_sel_o(wbm1_sel_o),
        .wb_we_o(wbm1_we_o)
    );

    logic stall_mem_wb, bubble_mem_wb;

    MEM_WB MEM_WB(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stall_i(stall_ex_mem),
        .bubble_i(bubble_ex_mem),

        .pc_i(pc_ex_mem),
        .inst_op_i(inst_op_ex_mem),
        .inst_type_i(inst_type_ex_mem),
        .alu_y_i(alu_y_ex_mem),
        .rf_waddr_i(rf_waddr_ex_mem),
        .rf_wdata_i(rf_wdata_mem),
        
        .rf_waddr_o(rf_waddr_o),
        .rf_wdata_o(rf_wdata_o),
        .rf_we_o(rf_we_o)
    );

    controller controller(
        .wbm0_cyc_i(wbm0_cyc_o),
        .wbm0_stb_i(wbm0_stb_o),
        .wbm0_ack_i(wbm0_ack_i),
        .wbm1_cyc_i(wbm1_cyc_o),
        .wbm1_stb_i(wbm1_stb_o),
        .wbm1_ack_i(wbm1_ack_i),
        .jump_i(jump),
        .rf_raddr_a_if_id_i(rf_raddr_a_if_id),
        .rf_raddr_b_if_id_i(rf_raddr_b_if_id),
        .read_mem_id_ex_i(read_mem_id_ex),
        .rf_waddr_id_ex_i(rf_waddr_id_ex),
        .stall_if_id_o(stall_if_id),
        .bubble_if_id_o(bubble_if_id),
        .stall_id_ex_o(stall_id_ex),
        .bubble_id_ex_o(bubble_id_ex),
        .stall_ex_mem_o(stall_ex_mem),
        .bubble_ex_mem_o(bubble_ex_mem),
        .stall_mem_wb_o(stall_mem_wb),
        .bubble_mem_wb_o(bubble_mem_wb)
    );
endmodule