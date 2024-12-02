module cache #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter TAG_WIDTH = 22,
    parameter INDEX_WIDTH = 8, // 256 sets
    parameter OFFSET_WIDTH = 2,
    parameter SET_SIZE = 4
)(
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    input wire fence_i,

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
    wire [TAG_WIDTH - 1:0] addr_tag = wb_adr_i[OFFSET_WIDTH + INDEX_WIDTH + TAG_WIDTH - 1:OFFSET_WIDTH + INDEX_WIDTH];
    wire [INDEX_WIDTH - 1:0] addr_index = wb_adr_i[OFFSET_WIDTH + INDEX_WIDTH - 1:OFFSET_WIDTH];
    wire [OFFSET_WIDTH - 1:0] addr_offset = wb_adr_i[OFFSET_WIDTH - 1:0];
    
    // Valid bits (using registers as they're small)
    reg [SET_SIZE - 1:0] valid_array [(1 << INDEX_WIDTH) - 1:0];
    reg [$clog2(SET_SIZE) - 1:0] lru_array [(1 << INDEX_WIDTH) - 1:0];
    
    // Tag and Data BRAM instances
    logic [TAG_WIDTH-1:0] tag_read [SET_SIZE - 1:0];
    logic [DATA_WIDTH-1:0] data_write;
    logic [DATA_WIDTH-1:0] data_read [SET_SIZE - 1:0];
    logic [SET_SIZE - 1:0] tag_we;
    logic [SET_SIZE - 1:0] data_we;
    
    bram_tag_gen bram_tag [SET_SIZE - 1:0] (
        .clka(clk_i),
        .addra(addr_index),
        .wea(tag_we),
        .dina(addr_tag),
        .douta(tag_read)
    );

    bram_data_gen bram_data [SET_SIZE - 1:0] (
        .clka(clk_i),
        .addra(addr_index),
        .wea(data_we),
        .dina(data_write),
        .douta(data_read)
    );
    
    // Cache hit logic
    logic [SET_SIZE - 1:0] cache_hit;
    
    // State machine
    typedef enum logic [1:0] {
        IDLE = 0,
        READ_CACHE = 1,
        READ_MEM = 2,
        WRITE_MEM = 3
    } state_t;
    state_t state;

    always_comb begin
        cache_hit = 4'b0;
        wb_dat_o = mem_dat_i;
        mem_dat_o = wb_dat_i;
        for (int i = 0; i < SET_SIZE; i = i + 1) begin
            cache_hit[i] = (tag_read[i] == addr_tag) && valid_array[addr_index][i];
            if (cache_hit[i]) begin
                wb_dat_o = data_read[i];
            end
        end

        data_write = 32'h0;
        for (int i = 0; i < SET_SIZE; i = i + 1) begin
            tag_we[i] = 1'b0;
            data_we[i] = 1'b0;
        end

        case (state)
            IDLE: begin
                wb_ack_o = 1'b0;
                if (wb_cyc_i && wb_stb_i && wb_we_i) begin
                    mem_cyc_o = wb_cyc_i;
                    mem_stb_o = wb_stb_i;
                    mem_adr_o = wb_adr_i;
                    mem_sel_o = 4'b1111;
                    mem_we_o = wb_we_i;
                end else begin
                    mem_cyc_o = 1'b0;
                    mem_stb_o = 1'b0;
                    mem_we_o = 1'b0;
                    mem_adr_o = wb_adr_i;
                    mem_sel_o = wb_sel_i;
                    mem_we_o = wb_we_i;
                end
            end
            READ_CACHE: begin
                if (cache_hit != 4'b0) begin
                    wb_ack_o = 1'b1;

                    mem_cyc_o = 1'b0;
                    mem_stb_o = 1'b0;
                    mem_we_o = 1'b0;
                    mem_adr_o = wb_adr_i;
                    mem_sel_o = wb_sel_i;
                    mem_we_o = wb_we_i;
                end else begin
                    wb_ack_o = 1'b0;

                    mem_cyc_o = wb_cyc_i;
                    mem_stb_o = wb_stb_i;
                    mem_adr_o = wb_adr_i;
                    mem_sel_o = 4'b1111;
                    mem_we_o = wb_we_i;
                end
            end
            READ_MEM: begin
                wb_ack_o = mem_ack_i;

                mem_cyc_o = wb_cyc_i;
                mem_stb_o = wb_stb_i;
                mem_adr_o = wb_adr_i;
                mem_sel_o = 4'b1111;
                mem_we_o = wb_we_i;

                if (mem_ack_i) begin
                    data_write = mem_dat_i;
                    for (int i = 0; i < SET_SIZE; i = i + 1) begin
                        if (i == lru_array[addr_index]) begin
                            tag_we[i] = 1'b1;
                            data_we[i] = 1'b1;
                        end else begin
                            tag_we[i] = 1'b0;
                            data_we[i] = 1'b0;
                        end
                    end
                end
            end
            WRITE_MEM: begin
                wb_ack_o = mem_ack_i;
                wb_dat_o = mem_dat_i;

                mem_cyc_o = wb_cyc_i;
                mem_stb_o = wb_stb_i;
                mem_adr_o = wb_adr_i;
                mem_sel_o = 4'b1111;
                mem_we_o = wb_we_i;

                if (mem_ack_i) begin
                    data_write = wb_dat_i;
                    for (int i = 0; i < SET_SIZE; i = i + 1) begin
                        if (cache_hit != 4'b0) begin
                            if (cache_hit[i]) begin
                                tag_we[i] = 1'b1;
                                data_we[i] = 1'b1;
                            end else begin
                                tag_we[i] = 1'b0;
                                data_we[i] = 1'b0;
                            end
                        end else begin
                            if (i == lru_array[addr_index]) begin
                                tag_we[i] = 1'b1;
                                data_we[i] = 1'b1;
                            end else begin
                                tag_we[i] = 1'b0;
                                data_we[i] = 1'b0;
                            end
                        end
                    end
                end
            end
        endcase
    end
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state <= IDLE;
            for (int i = 0; i < (1 << INDEX_WIDTH); i = i + 1) begin
                for (int j = 0; j < SET_SIZE; j = j + 1) begin
                    valid_array[i][j] <= 1'b0;
                end
                lru_array[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    if (wb_stb_i && wb_cyc_i) begin
                        if (wb_we_i) begin
                            state <= WRITE_MEM;
                        end else begin
                            state <= READ_CACHE;
                        end
                    end else if (fence_i) begin
                        for (int i = 0; i < (1 << INDEX_WIDTH); i = i + 1) begin
                            for (int j = 0; j < SET_SIZE; j = j + 1) begin
                                valid_array[i][j] <= 1'b0;
                            end
                            lru_array[i] <= 0;
                        end
                        state <= IDLE;
                    end
                end
                READ_CACHE: begin
                    if (cache_hit != 4'b0) begin
                        state <= IDLE;
                    end else begin
                        state <= READ_MEM;
                    end
                end
                READ_MEM: begin
                    if (mem_ack_i) begin
                        valid_array[addr_index][lru_array[addr_index]] <= 1'b1;
                        lru_array[addr_index] <= (lru_array[addr_index] + 1) % SET_SIZE;
                        state <= IDLE;
                    end
                end
                WRITE_MEM: begin
                    if (mem_ack_i) begin
                        valid_array[addr_index][lru_array[addr_index]] <= 1'b1;
                        lru_array[addr_index] <= (lru_array[addr_index] + 1) % SET_SIZE;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
