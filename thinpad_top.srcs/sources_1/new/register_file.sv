`default_nettype none

module register_file(
  input  wire        clk_i, 
  input  wire [4:0]  rf_raddr_a,
  output reg [31:0] rf_rdata_a,
  input  wire [4:0]  rf_raddr_b,
  output reg [31:0] rf_rdata_b,
  input  wire [4:0]  rf_waddr,
  input  wire [31:0] rf_wdata,
  input  wire rf_we
);

  reg [31:0] rf [31:0];
    
  always @(posedge clk_i) begin
    if (rf_we && rf_waddr != 0) begin
      rf[rf_waddr] <= rf_wdata;
    end
  end
    
  always_comb begin
    if (rf_raddr_a == 0) begin
      rf_rdata_a = 32'h0000_0000;
    end else begin
      rf_rdata_a = rf[rf_raddr_a];
    end
    if (rf_raddr_b == 0) begin
      rf_rdata_b = 32'h0000_0000;
    end else begin
      rf_rdata_b = rf[rf_raddr_b];
    end
  end

endmodule
