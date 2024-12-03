module mmu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter VPN1_WIDTH = 10,
    parameter VPN0_WIDTH = 10,
    parameter PPN_WIDTH = 20,
    parameter OFFSET_WIDTH = 12,
    parameter TLB_TAG_WIDTH = 22,
    parameter TLB_INDEX_WIDTH = 8,
    parameter TLB_OFFSET_WIDTH = 2,
    parameter TLB_SET_SIZE = 1,
    parameter PAGE_SIZE = 2 ** OFFSET_WIDTH,
    parameter PTE_SIZE = 4
)(
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // satp register
    input wire [DATA_WIDTH - 1:0] satp_i,
    input wire sfence_vma_i,

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

    wire [TLB_TAG_WIDTH - 1:0] addr_tlb_tag = wb_adr_i[TLB_TAG_WIDTH + TLB_OFFSET_WIDTH + TLB_INDEX_WIDTH - 1:TLB_OFFSET_WIDTH + TLB_INDEX_WIDTH];
    wire [TLB_INDEX_WIDTH - 1:0] addr_tlb_index = wb_adr_i[TLB_INDEX_WIDTH + TLB_OFFSET_WIDTH - 1:TLB_OFFSET_WIDTH];
    wire [TLB_OFFSET_WIDTH - 1:0] addr_tlb_offset = wb_adr_i[TLB_OFFSET_WIDTH - 1:0];

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

    logic [TLB_SET_SIZE - 1:0] tlb_valid [(1 << TLB_INDEX_WIDTH) - 1:0];
    logic [$clog2(TLB_SET_SIZE) - 1:0] tlb_lru [(1 << TLB_INDEX_WIDTH) - 1:0];

    logic [TLB_TAG_WIDTH - 1:0] tlb_tag [(1 << TLB_INDEX_WIDTH) - 1:0][TLB_SET_SIZE - 1:0];
    logic [DATA_WIDTH - 1:0] tlb_data [(1 << TLB_INDEX_WIDTH) - 1:0][TLB_SET_SIZE - 1:0];

    logic [TLB_SET_SIZE - 1:0] tlb_hit;
    logic [DATA_WIDTH - 1:0] tlb_pte;
    wire [PPN_WIDTH - 1:0] tlb_ppn = tlb_pte[DATA_WIDTH - 3:DATA_WIDTH - PPN_WIDTH - 2];

    typedef enum logic [1:0] {
        IDLE = 0,
        READ_PTE = 1,
        CHECK_PTE = 2,
        TRANSLATE = 3
    } state_t;
    state_t state;

    always_comb begin
        tlb_hit = 4'b0;
        wb_dat_o = mem_dat_i;
        for (int i = 0; i < TLB_SET_SIZE; i = i + 1) begin
            tlb_hit[i] = (tlb_tag[addr_tlb_index][i] == addr_tlb_tag) && tlb_valid[addr_tlb_index][i];
            if (tlb_hit[i]) begin
                tlb_pte = tlb_data[addr_tlb_index][i];
            end
        end

        case (state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (!satp_mode || wb_adr_i > 32'h8020_0000) begin // No translation needed
                        wb_ack_o = mem_ack_i;

                        mem_cyc_o = wb_cyc_i;
                        mem_stb_o = wb_stb_i;
                        mem_adr_o = wb_adr_i;
                        mem_dat_o = wb_dat_i;
                        mem_sel_o = wb_sel_i;
                        mem_we_o = wb_we_i;
                    end else if (tlb_hit != 4'b0) begin // TLB hit TODO: Check page fault
                        wb_ack_o = mem_ack_i;

                        mem_cyc_o = wb_cyc_i;
                        mem_stb_o = wb_stb_i;
                        mem_adr_o = tlb_ppn * PAGE_SIZE + addr_offset;
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
                mem_adr_o = (satp_mode && wb_adr_i < 32'h8020_0000) ? pte_ppn * PAGE_SIZE + addr_offset : wb_adr_i;
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
            satp_reg <= 0;
            for (int i = 0; i < 1 << TLB_INDEX_WIDTH; i = i + 1) begin
                tlb_valid[i] <= 0;
                tlb_lru[i] <= 0;
                for (int j = 0; j < TLB_SET_SIZE; j = j + 1) begin
                    tlb_tag[i][j] <= 0;
                    tlb_data[i][j] <= 0;
                end
            end
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (wb_cyc_i && wb_stb_i) begin
                        if (!satp_mode || wb_adr_i > 32'h8020_0000) begin
                            state <= TRANSLATE;
                        end else if (tlb_hit != 4'b0) begin
                            if (wb_we_i && !tlb_pte[2]) begin
                                // TODO: page fault
                                state <= TRANSLATE;
                            end else begin
                                state <= TRANSLATE;
                            end
                        end else begin
                            state <= READ_PTE;
                        end
                    end else if (sfence_vma_i) begin
                        for (int i = 0; i < 1 << TLB_INDEX_WIDTH; i = i + 1) begin
                            tlb_valid[i] <= 0;
                            tlb_lru[i] <= 0;
                            for (int j = 0; j < TLB_SET_SIZE; j = j + 1) begin
                                tlb_tag[i][j] <= 0;
                                tlb_data[i][j] <= 0;
                            end
                        end
                    end else begin
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
                    if (pte_data[0] == 1'b0 || pte_data[2:1] == 2'b10) begin // v == 0 || (r == 0 && w == 1)
                        // TODO: page fault
                    end else if (pte_data[1] == 1'b1 || pte_data[3] == 1'b1) begin // r == 1 || x == 1
                        if (wb_we_i && !pte_data[2]) begin // we == 1 && w == 0
                            // TODO: page fault
                            tlb_valid[addr_tlb_index][tlb_lru[addr_tlb_index]] <= 1'b1;
                            tlb_lru[addr_tlb_index] <= (tlb_lru[addr_tlb_index] + 1) % TLB_SET_SIZE;
                            tlb_tag[addr_tlb_index][tlb_lru[addr_tlb_index]] <= addr_tlb_tag;
                            tlb_data[addr_tlb_index][tlb_lru[addr_tlb_index]] <= pte_data;
                            state <= TRANSLATE;
                        end else begin
                            tlb_valid[addr_tlb_index][tlb_lru[addr_tlb_index]] <= 1'b1;
                            tlb_lru[addr_tlb_index] <= (tlb_lru[addr_tlb_index] + 1) % TLB_SET_SIZE;
                            tlb_tag[addr_tlb_index][tlb_lru[addr_tlb_index]] <= addr_tlb_tag;
                            tlb_data[addr_tlb_index][tlb_lru[addr_tlb_index]] <= pte_data;
                            state <= TRANSLATE;
                        end
                    end else if (pte_index == 0) begin // r == 0 && x == 0
                        // TO-DO: page fault
                    end else begin // v == 1 && r == 0 && w == 0 && x == 0 && pte_index != 0
                        pte_index <= pte_index - 1;
                        state <= READ_PTE;
                    end
                end
                TRANSLATE: begin
                    if (mem_ack_i) begin
                        pte_index <= 1;
                        satp_reg <= satp_i;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule