`default_nettype none

module register_file(
  input  wire        clk_i,
  input wire        rst_i, 
  input  wire [4:0]  rf_raddr_a,
  output reg [31:0] rf_rdata_a,
  input  wire [4:0]  rf_raddr_b,
  output reg [31:0] rf_rdata_b,
  input  wire [4:0]  rf_waddr,
  input  wire [31:0] rf_wdata,
  input  wire rf_we
);

  reg [31:0] rf [30:0];
    
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int i = 0; i < 31; i++) begin
        rf[i] <= 32'h0000_0000;
      end
    end else begin
      if (rf_we && rf_waddr != 0) begin
        rf[rf_waddr - 1] <= rf_wdata;
      end
    end
  end
    
  always_comb begin
    if (rf_raddr_a == 0) begin
      rf_rdata_a = 32'h0000_0000;
    end else begin
      rf_rdata_a = rf[rf_raddr_a - 1];
    end
    if (rf_raddr_b == 0) begin
      rf_rdata_b = 32'h0000_0000;
    end else begin
      rf_rdata_b = rf[rf_raddr_b - 1];
    end
  end

endmodule
