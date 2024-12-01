module controller(
    input wire wbm0_cyc_i,
    input wire wbm0_stb_i,
    input wire wbm0_ack_i,
    input wire wbm1_cyc_i,
    input wire wbm1_stb_i,
    input wire wbm1_ack_i,

    input wire stall_mem_i,
    input wire jump_i,

    input wire [4:0] rf_raddr_a_if_id_i,
    input wire [4:0] rf_raddr_b_if_id_i,
    input wire read_mem_id_ex_i,
    input wire [4:0] rf_waddr_id_ex_i,

    output reg stall_if_id_o,
    output reg bubble_if_id_o,

    output reg stall_id_ex_o,
    output reg bubble_id_ex_o,

    output reg stall_ex_mem_o,
    output reg bubble_ex_mem_o,

    output reg stall_mem_wb_o,
    output reg bubble_mem_wb_o
);
    always_comb begin
        if (
            (wbm0_cyc_i && wbm0_stb_i) || // IF busy
            (wbm1_cyc_i && wbm1_stb_i) // MEM busy
        ) begin // wishbone stall
            stall_if_id_o=1'b1;
            bubble_if_id_o=1'b0;

            stall_id_ex_o=1'b1;
            bubble_id_ex_o=1'b0;


            stall_ex_mem_o=1'b1;
            bubble_ex_mem_o=1'b0;

            stall_mem_wb_o=1'b1;
            bubble_mem_wb_o=1'b0;
        end else if (jump_i) begin // jump
            stall_if_id_o=1'b0;
            bubble_if_id_o=1'b1;

            stall_id_ex_o=1'b0;
            bubble_id_ex_o=1'b1;

            stall_ex_mem_o=1'b0;
            bubble_ex_mem_o=1'b0;

            stall_mem_wb_o=1'b0;
            bubble_mem_wb_o=1'b0;
        end else if (read_mem_id_ex_i && (rf_raddr_a_if_id_i == rf_waddr_id_ex_i || rf_raddr_b_if_id_i == rf_waddr_id_ex_i)) begin // read after write
            stall_if_id_o=1'b1;
            bubble_if_id_o=1'b0;

            stall_id_ex_o=1'b0;
            bubble_id_ex_o=1'b1;

            stall_ex_mem_o=1'b0;
            bubble_ex_mem_o=1'b0;

            stall_mem_wb_o=1'b0;
            bubble_mem_wb_o=1'b0;
        end else begin
            stall_if_id_o=1'b0;
            bubble_if_id_o=1'b0;

            stall_id_ex_o=1'b0;
            bubble_id_ex_o=1'b0;

            stall_ex_mem_o=1'b0;
            bubble_ex_mem_o=1'b0;

            stall_mem_wb_o=1'b0;
            bubble_mem_wb_o=1'b0;
        end
    end


endmodule