`include "./common/constants.svh"
module IF(
    input wire clk_i,
    input wire rst_i,
    input wire stall_i,
    input wire bubble_i,
    input wire [31:0] jump_addr_i,

    output reg [31:0] pc_o,
    output reg [31:0] inst_o,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [3:0] wb_sel_o,
    output reg wb_we_o
);
    logic [31:0] pc_reg;

    typedef enum logic {
        IDLE = 0,
        READ = 1
    } state_t;
    state_t state;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pc_reg <= 32'h80000000;
            pc_o <= 32'h0;
            inst_o <= 32'h0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (stall_i) begin

                    end else if (bubble_i) begin
                        wb_cyc_o <= 1;
                        wb_stb_o <= 1;
                        wb_adr_o <= jump_addr_i;
                        wb_dat_o <= 32'h0;
                        wb_sel_o <= 4'b1111;
                        wb_we_o <= 0;

                        pc_reg <= jump_addr_i;
                        state <= READ;
                    end else begin
                        wb_cyc_o <= 1;
                        wb_stb_o <= 1;
                        wb_adr_o <= pc_reg;
                        wb_dat_o <= 32'h0;
                        wb_sel_o <= 4'b1111;
                        wb_we_o <= 0;
                        state <= READ;
                    end
                end
                READ: begin
                    if (wb_ack_i) begin
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        pc_o <= pc_reg;
                        inst_o <= wb_dat_i;
                        pc_reg <= pc_reg + 4;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule