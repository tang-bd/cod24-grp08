`include "./common/constants.svh"

module thinpad_top (
    input wire clk_50M,     // 50MHz ????
    input wire clk_11M0592, // 11.0592MHz ????????????

    input wire push_btn,  // BTN5 ??????????????? 1
    input wire reset_btn, // BTN6 ??????????????? 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4?????????? 1
    input  wire [31:0] dip_sw,     // 32 ?????????ON??? 1
    output wire [15:0] leds,       // 16 ? LED???? 1 ??
    output wire [ 7:0] dpy0,       // ???????????????? 1 ??
    output wire [ 7:0] dpy1,       // ???????????????? 1 ??

    // CPLD ???????
    output wire uart_rdn,        // ?????????
    output wire uart_wrn,        // ?????????
    input  wire uart_dataready,  // ???????
    input  wire uart_tbre,       // ??????
    input  wire uart_tsre,       // ????????

    // BaseRAM ??
    inout wire [31:0] base_ram_data,  // BaseRAM ???? 8 ?? CPLD ???????
    output wire [19:0] base_ram_addr,  // BaseRAM ??
    output wire [3:0] base_ram_be_n,  // BaseRAM ??????????????????????? 0
    output wire base_ram_ce_n,  // BaseRAM ??????
    output wire base_ram_oe_n,  // BaseRAM ???????
    output wire base_ram_we_n,  // BaseRAM ???????

    // ExtRAM ??
    inout wire [31:0] ext_ram_data,  // ExtRAM ??
    output wire [19:0] ext_ram_addr,  // ExtRAM ??
    output wire [3:0] ext_ram_be_n,  // ExtRAM ??????????????????????? 0
    output wire ext_ram_ce_n,  // ExtRAM ??????
    output wire ext_ram_oe_n,  // ExtRAM ???????
    output wire ext_ram_we_n,  // ExtRAM ???????

    // ??????
    output wire txd,  // ???????
    input  wire rxd,  // ???????

    // Flash ???????? JS28F640 ????
    output wire [22:0] flash_a,  // Flash ???a0 ?? 8bit ?????16bit ?????
    inout wire [15:0] flash_d,  // Flash ??
    output wire flash_rp_n,  // Flash ????????
    output wire flash_vpen,  // Flash ?????????????????
    output wire flash_ce_n,  // Flash ????????
    output wire flash_oe_n,  // Flash ?????????
    output wire flash_we_n,  // Flash ?????????
    output wire flash_byte_n, // Flash 8bit ???????????? flash ? 16 ??????? 1

    // USB ???????? SL811 ????
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB ?????????? dm9k_sd[7:0] ??
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // ?????????? DM9000A ????
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // ??????
    output wire [2:0] video_red,    // ?????3 ?
    output wire [2:0] video_green,  // ?????3 ?
    output wire [1:0] video_blue,   // ?????2 ?
    output wire       video_hsync,  // ???????????
    output wire       video_vsync,  // ???????????
    output wire       video_clk,    // ??????
    output wire       video_de      // ???????????????
);

  /* =========== Demo code begin =========== */

  // PLL ????
  // logic locked, clk_10M, clk_20M;
  // pll_example clock_gen (
  //     // Clock in ports
  //     .clk_in1(clk_50M),  // ??????
  //     // Clock out ports
  //     .clk_out1(clk_10M),  // ???? 1???? IP ???????
  //     .clk_out2(clk_20M),  // ???? 2???? IP ???????
  //     // Status and control signals
  //     .reset(reset_btn),  // PLL ????
  //     .locked(locked)  // PLL ???????"1"???????
  //                      // ??????????????????
  // );

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_50M;
  assign sys_rst = reset_btn;
  // ??????????? locked ??????????? reset_of_clk10M
  // always_ff @(posedge sys_clk or negedge locked) begin
  //   if (~locked) sys_rst <= 1'b1;
  //   else sys_rst <= 1'b0;
  // end

  // ?????? CPLD ???????????
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  /* =========== Wishbone Master begin =========== */
  // Wishbone Master => Wishbone MUX (Slave)
  logic        wbm_cyc_o;
  logic        wbm_stb_o;
  logic        wbm_ack_i;
  logic [31:0] wbm_adr_o;
  logic [31:0] wbm_dat_o;
  logic [31:0] wbm_dat_i;
  logic [ 3:0] wbm_sel_o;
  logic        wbm_we_o;

  

  /* =========== Wishbone Master end =========== */

  /* =========== ALU begin =========== */

  // ALU ??
  logic [31:0] alu_a;
  logic [31:0] alu_b;
  logic [ 3:0] alu_op;
  logic [31:0] alu_y;
  
  alu alu(
    .alu_a(alu_a),
    .alu_b(alu_b),
    .alu_op(alu_op),
    .alu_y(alu_y)
  );

  /* =========== ALU end =========== */

  /* =========== ImmGen begin =========== */

  // ImmGen ??
  logic [31:0] imm_gen_inst;
  logic [2:0] imm_gen_type;
  logic [31:0] imm_gen_data;

  imm_gen imm_gen(
    .imm_gen_inst(imm_gen_inst),
    .imm_gen_type(imm_gen_type),
    .imm_gen_data(imm_gen_data)
  );

  /* =========== ImmGen end =========== */

  /* =========== RF begin =========== */

  // RF ??
  logic [4:0] rf_raddr_a;
  logic [4:0] rf_raddr_b;
  logic [31:0] rf_rdata_a;
  logic [31:0] rf_rdata_b;
  logic [4:0] rf_waddr;
  logic [31:0] rf_wdata;
  logic rf_we;

  register_file rf(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .rf_raddr_a(rf_raddr_a),
    .rf_raddr_b(rf_raddr_b),
    .rf_rdata_a(rf_rdata_a),
    .rf_rdata_b(rf_rdata_b),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .rf_we(rf_we)
  );

  /* =========== RF end =========== */

  /* =========== CSR begin =========== */

  // CSR ??
  logic [11:0] csr_raddr;
  logic [31:0] csr_rdata;
  logic [31:0] csr_wdata;
  logic [11:0] csr_waddr;
  logic csr_we;

  logic [1:0] privilege_mode_i, privilege_mode_o;
  logic privilege_mode_we;

  logic [31:0] mstatus_i, mstatus_o;
  logic mstatus_we;
  logic [31:0] mie_i, mie_o;
  logic mie_we;
  logic [31:0] mtvec_i, mtvec_o;
  logic mtvec_we;
  logic [31:0] mscratch_i, mscratch_o;
  logic mscratch_we;
  logic [31:0] mepc_i, mepc_o;
  logic mepc_we;
  logic [31:0] mcause_i, mcause_o;
  logic mcause_we;
  logic [31:0] mip_i, mip_o;
  logic mip_we;

  logic [31:0] satp_o;

  logic [63:0] mtime_i, mtime_o;
  logic [31:0] mtime0_i, mtime1_i;
  logic mtime0_we, mtime1_we;

  logic [63:0] mtimecmp_i, mtimecmp_o;
  logic [31:0] mtimecmp0_i, mtimecmp1_i;
  logic mtimecmp0_we, mtimecmp1_we;

  csr csr(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .csr_raddr(csr_raddr),
    .csr_rdata(csr_rdata),
    .csr_wdata(csr_wdata),
    .csr_waddr(csr_waddr),
    .csr_we(csr_we),

    .privilege_mode_i(privilege_mode_i),
    .privilege_mode_o(privilege_mode_o),
    .privilege_mode_we(privilege_mode_we),

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

    .satp_o(satp_o),

    .mtime_i(mtime_i),
    .mtime_o(mtime_o),
    .mtime0_i(mtime0_i),
    .mtime0_we(mtime0_we),
    .mtime1_i(mtime1_i),
    .mtime1_we(mtime1_we),

    .mtimecmp_i(mtimecmp_i),
    .mtimecmp_o(mtimecmp_o),
    .mtimecmp0_i(mtimecmp0_i),
    .mtimecmp0_we(mtimecmp0_we),
    .mtimecmp1_i(mtimecmp1_i),
    .mtimecmp1_we(mtimecmp1_we)
  );

  /* =========== CSR end =========== */

  /* =========== MMU begin =========== */

  logic wbm0_cyc_i, wbm0_stb_i, wbm0_ack_o;
  logic [31:0] wbm0_adr_i, wbm0_dat_i, wbm0_dat_o;
  logic [3:0] wbm0_sel_i;
  logic wbm0_we_i;

  logic wbm1_cyc_i, wbm1_stb_i, wbm1_ack_o;
  logic [31:0] wbm1_adr_i, wbm1_dat_i, wbm1_dat_o;
  logic [3:0] wbm1_sel_i;
  logic wbm1_we_i;

  logic wbp0_cyc_i, wbp0_stb_i, wbp0_ack_o;
  logic [31:0] wbp0_adr_i, wbp0_dat_i, wbp0_dat_o;
  logic [3:0] wbp0_sel_i;
  logic wbp0_we_i;

  logic wbp1_cyc_i, wbp1_stb_i, wbp1_ack_o;
  logic [31:0] wbp1_adr_i, wbp1_dat_i, wbp1_dat_o;
  logic [3:0] wbp1_sel_i;
  logic wbp1_we_i;

  mmu immu (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .privilege_mode_i(privilege_mode_o),
      .satp_i(satp_o),

      .wb_cyc_i(wbm0_cyc_i),
      .wb_stb_i(wbm0_stb_i),
      .wb_ack_o(wbm0_ack_o),
      .wb_adr_i(wbm0_adr_i),
      .wb_dat_i(wbm0_dat_i),
      .wb_dat_o(wbm0_dat_o),
      .wb_sel_i(wbm0_sel_i),
      .wb_we_i(wbm0_we_i),

      .mem_cyc_o(wbp0_cyc_i),
      .mem_stb_o(wbp0_stb_i),
      .mem_ack_i(wbp0_ack_o),
      .mem_adr_o(wbp0_adr_i),
      .mem_dat_o(wbp0_dat_i),
      .mem_dat_i(wbp0_dat_o),
      .mem_sel_o(wbp0_sel_i),
      .mem_we_o(wbp0_we_i)
  );

  mmu dmmu (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .privilege_mode_i(privilege_mode_o),
      .satp_i(satp_o),

      .wb_cyc_i(wbs3_cyc_o),
      .wb_stb_i(wbs3_stb_o),
      .wb_ack_o(wbs3_ack_i),
      .wb_adr_i(wbs3_adr_o),
      .wb_dat_i(wbs3_dat_o),
      .wb_dat_o(wbs3_dat_i),
      .wb_sel_i(wbs3_sel_o),
      .wb_we_i(wbs3_we_o),

      .mem_cyc_o(wbp1_cyc_i),
      .mem_stb_o(wbp1_stb_i),
      .mem_ack_i(wbp1_ack_o),
      .mem_adr_o(wbp1_adr_i),
      .mem_dat_o(wbp1_dat_i),
      .mem_dat_i(wbp1_dat_o),
      .mem_sel_o(wbp1_sel_i),
      .mem_we_o(wbp1_we_i)
  );

  /* =========== MMU end =========== */

  /* =========== Cache begin =========== */

  logic wbc0_cyc_i, wbc0_stb_i, wbc0_ack_o;
  logic [31:0] wbc0_adr_i, wbc0_dat_i, wbc0_dat_o;
  logic [3:0] wbc0_sel_i;
  logic wbc0_we_i;

  logic wbc1_cyc_i, wbc1_stb_i, wbc1_ack_o;
  logic [31:0] wbc1_adr_i, wbc1_dat_i, wbc1_dat_o;
  logic [3:0] wbc1_sel_i;
  logic wbc1_we_i;

  logic fence_i;

  cache #(
      .DATA_WIDTH(32),
      .ADDR_WIDTH(32),
      .TAG_WIDTH(22),
      .INDEX_WIDTH(8),
      .OFFSET_WIDTH(2)
  ) icache (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .fence_i_i(fence_i),

      .wb_cyc_i(wbp0_cyc_i),
      .wb_stb_i(wbp0_stb_i),
      .wb_ack_o(wbp0_ack_o),
      .wb_adr_i(wbp0_adr_i),
      .wb_dat_i(wbp0_dat_i),
      .wb_dat_o(wbp0_dat_o),
      .wb_sel_i(wbp0_sel_i),
      .wb_we_i(wbp0_we_i),

      .mem_cyc_o(wbc0_cyc_i),
      .mem_stb_o(wbc0_stb_i),
      .mem_ack_i(wbc0_ack_o),
      .mem_adr_o(wbc0_adr_i),
      .mem_dat_o(wbc0_dat_i),
      .mem_dat_i(wbc0_dat_o),
      .mem_sel_o(wbc0_sel_i),
      .mem_we_o(wbc0_we_i)
  );

  cache #(
      .DATA_WIDTH(32),
      .ADDR_WIDTH(32),
      .TAG_WIDTH(22),
      .INDEX_WIDTH(8),
      .OFFSET_WIDTH(2)
  ) dcache (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .fence_i_i(1'b0),

      .wb_cyc_i(wbp1_cyc_i),
      .wb_stb_i(wbp1_stb_i),
      .wb_ack_o(wbp1_ack_o),
      .wb_adr_i(wbp1_adr_i),
      .wb_dat_i(wbp1_dat_i),
      .wb_dat_o(wbp1_dat_o),
      .wb_sel_i(wbp1_sel_i),
      .wb_we_i(wbp1_we_i),

      .mem_cyc_o(wbc1_cyc_i),
      .mem_stb_o(wbc1_stb_i),
      .mem_ack_i(wbc1_ack_o),
      .mem_adr_o(wbc1_adr_i),
      .mem_dat_o(wbc1_dat_i),
      .mem_dat_i(wbc1_dat_o),
      .mem_sel_o(wbc1_sel_i),
      .mem_we_o(wbc1_we_i)
  );

  /* =========== Cache end =========== */

  /* =========== Arbiter begin =========== */

  wb_arbiter_2 arbiter(
        .clk(sys_clk),
        .rst(sys_rst),
        .wbm0_cyc_i(wbc0_cyc_i),
        .wbm0_stb_i(wbc0_stb_i),
        .wbm0_ack_o(wbc0_ack_o),
        .wbm0_adr_i(wbc0_adr_i),
        .wbm0_dat_i(wbc0_dat_i),
        .wbm0_dat_o(wbc0_dat_o),
        .wbm0_sel_i(wbc0_sel_i),
        .wbm0_we_i(wbc0_we_i),
        .wbm0_err_o(),
        .wbm0_rty_o(),
        .wbm1_cyc_i(wbc1_cyc_i),
        .wbm1_stb_i(wbc1_stb_i),
        .wbm1_ack_o(wbc1_ack_o),
        .wbm1_adr_i(wbc1_adr_i),
        .wbm1_dat_i(wbc1_dat_i),
        .wbm1_dat_o(wbc1_dat_o),
        .wbm1_sel_i(wbc1_sel_i),
        .wbm1_we_i(wbc1_we_i),
        .wbm1_err_o(),
        .wbm1_rty_o(),
        .wbs_cyc_o(wbm_cyc_o),
        .wbs_stb_o(wbm_stb_o),
        .wbs_ack_i(wbm_ack_i),
        .wbs_adr_o(wbm_adr_o),
        .wbs_dat_o(wbm_dat_o),
        .wbs_dat_i(wbm_dat_i),
        .wbs_sel_o(wbm_sel_o),
        .wbs_we_o(wbm_we_o)
    );

  /* =========== Arbiter end =========== */

  /* =========== Wishbone MUX begin =========== */
  // Wishbone MUX (Masters) => bus slaves
  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  logic wbs3_cyc_o;
  logic wbs3_stb_o;
  logic wbs3_ack_i;
  logic [31:0] wbs3_adr_o;
  logic [31:0] wbs3_dat_o;
  logic [31:0] wbs3_dat_i;
  logic [3:0] wbs3_sel_o;
  logic wbs3_we_o;

  wb_mux uart_mux (
    .clk(sys_clk),
    .rst(sys_rst),

    // Master interface (to Lab5 master)
    .wbm_adr_i(wbm1_adr_i),
    .wbm_dat_i(wbm1_dat_i),
    .wbm_dat_o(wbm1_dat_o),
    .wbm_we_i (wbm1_we_i),
    .wbm_sel_i(wbm1_sel_i),
    .wbm_stb_i(wbm1_stb_i),
    .wbm_ack_o(wbm1_ack_o),
    .wbm_err_o(),
    .wbm_rty_o(),
    .wbm_cyc_i(wbm1_cyc_i),

    // Slave interface 0 (to UART controller)
    .wbs0_addr    (32'h1000_0000),
    .wbs0_addr_msk(32'hF000_0000),

    .wbs0_adr_o(wbs2_adr_o),
    .wbs0_dat_i(wbs2_dat_i),
    .wbs0_dat_o(wbs2_dat_o),
    .wbs0_we_o (wbs2_we_o),
    .wbs0_sel_o(wbs2_sel_o),
    .wbs0_stb_o(wbs2_stb_o),
    .wbs0_ack_i(wbs2_ack_i),
    .wbs0_err_i('0),
    .wbs0_rty_i('0),
    .wbs0_cyc_o(wbs2_cyc_o),

    // Slave interface 1 (to SRAM controller)
    .wbs1_addr    (32'h0000_0000),
    .wbs1_addr_msk(32'h0000_0000),

    .wbs1_adr_o(wbs3_adr_o),
    .wbs1_dat_i(wbs3_dat_i),
    .wbs1_dat_o(wbs3_dat_o),
    .wbs1_we_o (wbs3_we_o),
    .wbs1_sel_o(wbs3_sel_o),
    .wbs1_stb_o(wbs3_stb_o),
    .wbs1_ack_i(wbs3_ack_i),
    .wbs1_err_i('0),
    .wbs1_rty_i('0),
    .wbs1_cyc_o(wbs3_cyc_o)
  );

  wb_mux sram_mux (
    .clk(sys_clk),
    .rst(sys_rst),

    // Master interface (to Lab5 master)
    .wbm_adr_i(wbm_adr_o),
    .wbm_dat_i(wbm_dat_o),
    .wbm_dat_o(wbm_dat_i),
    .wbm_we_i (wbm_we_o),
    .wbm_sel_i(wbm_sel_o),
    .wbm_stb_i(wbm_stb_o),
    .wbm_ack_o(wbm_ack_i),
    .wbm_err_o(),
    .wbm_rty_o(),
    .wbm_cyc_i(wbm_cyc_o),

    // Slave interface 0 (to BaseRAM controller)
    // Address range: 0x8000_0000 ~ 0x803F_FFFF
    .wbs0_addr    (32'h8000_0000),
    .wbs0_addr_msk(32'hFFC0_0000),

    .wbs0_adr_o(wbs0_adr_o),
    .wbs0_dat_i(wbs0_dat_i),
    .wbs0_dat_o(wbs0_dat_o),
    .wbs0_we_o (wbs0_we_o),
    .wbs0_sel_o(wbs0_sel_o),
    .wbs0_stb_o(wbs0_stb_o),
    .wbs0_ack_i(wbs0_ack_i),
    .wbs0_err_i('0),
    .wbs0_rty_i('0),
    .wbs0_cyc_o(wbs0_cyc_o),

    // Slave interface 1 (to ExtRAM controller)
    // Address range: 0x8040_0000 ~ 0x807F_FFFF
    .wbs1_addr    (32'h8040_0000),
    .wbs1_addr_msk(32'hFFC0_0000),

    .wbs1_adr_o(wbs1_adr_o),
    .wbs1_dat_i(wbs1_dat_i),
    .wbs1_dat_o(wbs1_dat_o),
    .wbs1_we_o (wbs1_we_o),
    .wbs1_sel_o(wbs1_sel_o),
    .wbs1_stb_o(wbs1_stb_o),
    .wbs1_ack_i(wbs1_ack_i),
    .wbs1_err_i('0),
    .wbs1_rty_i('0),
    .wbs1_cyc_o(wbs1_cyc_o)
  );

  /* =========== Wishbone MUX end =========== */

  /* =========== Wishbone Slaves begin =========== */

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  // ???????
  // NOTE: ?????????????????????????
  uart_controller #(
      .CLK_FREQ(50_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  /* =========== Wishbone Slaves end =========== */

  /* =========== Central Processing Unit begin =========== */

  // CPU ??
  
  cpu cpu(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .privilege_mode_o(privilege_mode_i),
    .privilege_mode_we(privilege_mode_we),
    .fence_i_o(fence_i),
    .wbm0_cyc_o(wbm0_cyc_i),
    .wbm0_stb_o(wbm0_stb_i),
    .wbm0_ack_i(wbm0_ack_o),
    .wbm0_adr_o(wbm0_adr_i),
    .wbm0_dat_o(wbm0_dat_i),
    .wbm0_dat_i(wbm0_dat_o),
    .wbm0_sel_o(wbm0_sel_i),
    .wbm0_we_o(wbm0_we_i),
    .wbm1_cyc_o(wbm1_cyc_i),
    .wbm1_stb_o(wbm1_stb_i),
    .wbm1_ack_i(wbm1_ack_o),
    .wbm1_adr_o(wbm1_adr_i),
    .wbm1_dat_o(wbm1_dat_i),
    .wbm1_dat_i(wbm1_dat_o),
    .wbm1_sel_o(wbm1_sel_i),
    .wbm1_we_o(wbm1_we_i),
    .rf_raddr_a_o(rf_raddr_a),
    .rf_raddr_b_o(rf_raddr_b),
    .rf_rdata_a_i(rf_rdata_a),
    .rf_rdata_b_i(rf_rdata_b),
    .rf_waddr_o(rf_waddr),
    .rf_wdata_o(rf_wdata),
    .rf_we_o(rf_we),
    .csr_raddr_o(csr_raddr),
    .csr_rdata_i(csr_rdata),
    .csr_waddr_o(csr_waddr),
    .csr_wdata_o(csr_wdata),
    .csr_we_o(csr_we),
    .mstatus_i(mstatus_o),
    .mstatus_o(mstatus_i),
    .mstatus_we(mstatus_we),
    .mie_i(mie_o),
    .mie_o(mie_i),
    .mie_we(mie_we),
    .mtvec_i(mtvec_o),
    .mtvec_o(mtvec_i),
    .mtvec_we(mtvec_we),
    .mscratch_i(mscratch_o),
    .mscratch_o(mscratch_i),
    .mscratch_we(mscratch_we),
    .mepc_i(mepc_o),
    .mepc_o(mepc_i),
    .mepc_we(mepc_we),
    .mcause_i(mcause_o),
    .mcause_o(mcause_i),
    .mcause_we(mcause_we),
    .mip_i(mip_o),
    .mip_o(mip_i),
    .mip_we(mip_we),
    .mtime_i(mtime_o),
    .mtime_o(mtime_i),
    .mtime0_o(mtime0_i),
    .mtime0_we(mtime0_we),
    .mtime1_o(mtime1_i),
    .mtime1_we(mtime1_we),
    .mtimecmp_i(mtimecmp_o),
    .mtimecmp_o(mtimecmp_i),
    .mtimecmp0_o(mtimecmp0_i),
    .mtimecmp0_we(mtimecmp0_we),
    .mtimecmp1_o(mtimecmp1_i),
    .mtimecmp1_we(mtimecmp1_we),
    .alu_a_o(alu_a),
    .alu_b_o(alu_b),
    .alu_op_o(alu_op),
    .alu_y_i(alu_y),
    .imm_gen_inst_o(imm_gen_inst),
    .imm_gen_type_o(imm_gen_type),
    .imm_gen_data_i(imm_gen_data)
  );

  /* =========== Central Processing Unit end =========== */

endmodule
