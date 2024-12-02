`include "./common/constants.svh"

module thinpad_top (
    input wire clk_50M,     // 50MHz 时钟输入
    input wire clk_11M0592, // 11.0592MHz 时钟输入（备用，可不用）

    input wire push_btn,  // BTN5 按钮开关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时为 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时为 1
    output wire [15:0] leds,       // 16 位 LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信号
    output wire uart_rdn,        // 读串口信号，低有效
    output wire uart_wrn,        // 写串口信号，低有效
    input  wire uart_dataready,  // 串口数据准备好
    input  wire uart_tbre,       // 发送数据标志
    input  wire uart_tsre,       // 数据发送完毕标志

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共享
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire base_ram_ce_n,  // BaseRAM 片选，低有效
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有效
    output wire base_ram_we_n,  // BaseRAM 写使能，低有效

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire ext_ram_ce_n,  // ExtRAM 片选，低有效
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有效
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有效

    // 直连串口信号
    output wire txd,  // 直连串口发送端
    input  wire rxd,  // 直连串口接收端

    // Flash 存储器信号，参考 JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效，16bit 模式无意义
    inout wire [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,  // Flash 片选信号，低有效
    output wire flash_oe_n,  // Flash 读使能信号，低有效
    output wire flash_we_n,  // Flash 写使能信号，低有效
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash 的 16 位模式时请设为 1

    // USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB 数据线与网络控制器的 dm9k_sd[7:0] 共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素，3 位
    output wire [2:0] video_green,  // 绿色像素，3 位
    output wire [1:0] video_blue,   // 蓝色像素，2 位
    output wire       video_hsync,  // 行同步（水平同步）信号
    output wire       video_vsync,  // 场同步（垂直同步）信号
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐区
);

  /* =========== Demo code begin =========== */

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设置
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设置
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出，"1"表示时钟稳定，
                       // 后级电路复位信号应当由它生成（见下）
  );

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_50M;
  logic sys_rst;
  // 异步复位，同步释放，将 locked 信号转为后级电路的复位 reset_of_clk10M
  always_ff @(posedge sys_clk or negedge locked) begin
    if (~locked) sys_rst <= 1'b1;
    else sys_rst <= 1'b0;
  end

  // 本实验不使用 CPLD 串口，禁用防止总线冲突
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

  // 串口控制器模块
  // NOTE: 如果修改系统时钟频率，也需要修改此处的时钟频率参数
  uart_controller #(
      .CLK_FREQ(50_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs3_cyc_o),
      .wb_stb_i(wbs3_stb_o),
      .wb_ack_o(wbs3_ack_i),
      .wb_adr_i(wbs3_adr_o),
      .wb_dat_i(wbs3_dat_o),
      .wb_dat_o(wbs3_dat_i),
      .wb_sel_i(wbs3_sel_o),
      .wb_we_i (wbs3_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  /* =========== Wishbone Slaves end =========== */

  /* =========== ALU begin =========== */

  // ALU 模块
  logic [31:0] alu_a;
  logic [31:0] alu_b;
  logic [ 2:0] alu_op;
  logic [31:0] alu_y;
  
  alu alu(
    .alu_a(alu_a),
    .alu_b(alu_b),
    .alu_op(alu_op),
    .alu_y(alu_y)
  );

  /* =========== ALU end =========== */

  /* =========== ImmGen begin =========== */

  // ImmGen 模块
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

  // RF 模块
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

  // CSR 模块
  logic [11:0] csr_raddr;
  logic [31:0] csr_rdata;
  logic [31:0] csr_wdata;
  logic [11:0] csr_waddr;
  logic csr_we;

  logic [31:0] satp;

  csr csr(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .csr_raddr(csr_raddr),
    .csr_rdata(csr_rdata),
    .csr_wdata(csr_wdata),
    .csr_waddr(csr_waddr),
    .csr_we(csr_we),
    .satp_o(satp)
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

      .satp_i(satp),

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

      .satp_i(satp),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i(wbs2_we_o),

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

      .fence_i(fence_i),

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

      .fence_i(1'b0),

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

    // Slave interface 0 (to SRAM controller)
    .wbs0_addr    (32'h8000_0000),
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

    // Slave interface 1 (to UART controller)
    .wbs1_addr    (32'h1000_0000),
    .wbs1_addr_msk(32'hF000_0000),

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

  /* =========== Central Processing Unit begin =========== */

  // CPU 模块
  
  cpu cpu(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .fence_o(fence_i),
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
