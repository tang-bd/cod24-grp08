module mmu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter VPN1_WIDTH = 10,
    parameter VPN0_WIDTH = 10,
    parameter PPN_WIDTH = 20,
    parameter OFFSET_WIDTH = 12,
    parameter PAGE_SIZE = 1 << OFFSET_WIDTH,
    parameter PTE_SIZE = 4
)(
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // satp register
    input wire [1:0] privilege_mode_i,
    input wire [DATA_WIDTH - 1:0] satp_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH - 1:0] wb_adr_i,
    input wire [DATA_WIDTH - 1:0] wb_dat_i,
    output reg [DATA_WIDTH - 1:0] wb_dat_o,
    input wire [DATA_WIDTH / 8 - 1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg mem_cyc_o,
    output reg mem_stb_o,
    input wire mem_ack_i,
    output reg [ADDR_WIDTH - 1:0] mem_adr_o,
    output reg [DATA_WIDTH - 1:0] mem_dat_o,
    input wire [DATA_WIDTH - 1:0] mem_dat_i,
    output reg [DATA_WIDTH / 8 - 1:0] mem_sel_o,
    output reg mem_we_o
);  
    // Address breakdown
    wire [VPN1_WIDTH - 1:0] addr_vpn [1:0];
    assign addr_vpn[1] = wb_adr_i[VPN1_WIDTH + VPN0_WIDTH + OFFSET_WIDTH - 1:VPN0_WIDTH + OFFSET_WIDTH];
    assign addr_vpn[0] = wb_adr_i[VPN0_WIDTH + OFFSET_WIDTH - 1:OFFSET_WIDTH];
    wire [OFFSET_WIDTH - 1:0] addr_offset = wb_adr_i[OFFSET_WIDTH - 1:0];

    logic [DATA_WIDTH - 1:0] privilege_mode_reg;

    // satp breakdown
    logic [DATA_WIDTH - 1:0] satp_reg;
    wire satp_mode = satp_reg[ADDR_WIDTH - 1];
    wire [PPN_WIDTH - 1:0] satp_ppn = satp_reg[PPN_WIDTH - 1:0];

    logic [DATA_WIDTH - 1:0] pte_data;
    wire [PPN_WIDTH - 1:0] pte_ppn = pte_data[DATA_WIDTH - 3:DATA_WIDTH - PPN_WIDTH - 2];
    logic [1:0] pte_index;

    logic [PPN_WIDTH - 1:0] ppn [1:0];
    assign ppn[1] = satp_ppn;
    assign ppn[0] = pte_ppn;

    typedef enum logic [1:0] {
        IDLE = 0,
        READ_PTE = 1,
        CHECK_PTE = 2,
        TRANSLATE = 3
    } state_t;
    state_t state;

    always_comb begin
        wb_dat_o <= mem_dat_i;

        case (state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (!satp_mode || privilege_mode_reg == 2'b11) begin // No translation needed
                        wb_ack_o = mem_ack_i;

                        mem_cyc_o = wb_cyc_i;
                        mem_stb_o = wb_stb_i;
                        mem_adr_o = wb_adr_i;
                        mem_dat_o = wb_dat_i;
                        mem_sel_o = wb_sel_i;
                        mem_we_o = wb_we_i;
                    end else begin // TLB miss
                        wb_ack_o = 1'b0;

                        mem_cyc_o = 1'b1;
                        mem_stb_o = 1'b1;
                        mem_adr_o = ppn[pte_index] * PAGE_SIZE + addr_vpn[pte_index] * PTE_SIZE;
                        mem_dat_o = 1'b0;
                        mem_sel_o = 4'b1111;
                        mem_we_o = 1'b0;
                    end
                end else begin
                    wb_ack_o = 1'b0;

                    mem_cyc_o = 1'b0;
                    mem_stb_o = 1'b0;
                    mem_adr_o = 32'h0;
                    mem_dat_o = 1'b0;
                    mem_sel_o = 4'b1111;
                    mem_we_o = 1'b0;
                end
            end
            READ_PTE: begin
                wb_ack_o = 1'b0;

                mem_cyc_o = 1'b1;
                mem_stb_o = 1'b1;
                mem_adr_o = ppn[pte_index] * PAGE_SIZE + addr_vpn[pte_index] * PTE_SIZE;
                mem_dat_o = 1'b0;
                mem_sel_o = 4'b1111;
                mem_we_o = 1'b0;
            end
            CHECK_PTE: begin
                wb_ack_o = 1'b0;

                mem_cyc_o = 1'b0;
                mem_stb_o = 1'b0;
                mem_adr_o = 32'h0;
                mem_dat_o = 1'b0;
                mem_sel_o = 4'b1111;
                mem_we_o = 1'b0;
            end
            TRANSLATE: begin
                wb_ack_o = mem_ack_i;

                mem_cyc_o = wb_cyc_i;
                mem_stb_o = wb_stb_i;
                mem_adr_o = (!satp_mode || privilege_mode_reg == 2'b11) ? wb_adr_i : pte_ppn * PAGE_SIZE + addr_offset;
                mem_dat_o = wb_dat_i;
                mem_sel_o = wb_sel_i;
                mem_we_o = wb_we_i;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pte_data <= 0;
            pte_index <= 1;
            privilege_mode_reg <= 0;
            satp_reg <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (wb_cyc_i && wb_stb_i) begin
                        if (!satp_mode || privilege_mode_i == 2'b11) begin
                            state <= TRANSLATE;
                        end else begin
                            state <= READ_PTE;
                        end
                    end else begin
                        privilege_mode_reg <= privilege_mode_i;
                        satp_reg <= satp_i;
                    end
                end
                READ_PTE: begin
                    if (mem_ack_i) begin
                        pte_data <= mem_dat_i;
                        state <= CHECK_PTE;
                    end
                end
                CHECK_PTE: begin
                    if (pte_data[1] == 1'b1 || pte_data[3] == 1'b1) begin // r == 1 || x == 1
                        state <= TRANSLATE;
                    end else begin // v == 1 && r == 0 && w == 0 && x == 0 && pte_index != 0
                        pte_index <= pte_index - 1;
                        state <= READ_PTE;
                    end
                end
                TRANSLATE: begin
                    if (mem_ack_i) begin
                        pte_index <= 1;
                        privilege_mode_reg <= privilege_mode_i;
                        satp_reg <= satp_i;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule