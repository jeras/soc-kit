module zbus_source #(
  parameter BW = 1,
  parameter XZ = 1'bx
)(
  // system signals
  input  wire           z_clk,  // system clock
  input  wire           z_rst,  // asinchronous reset
  // zbus signals
  output reg            z_vld,  // transfer valid
  output reg   [BW-1:0] z_bus,  // grouped bus signals
  input  wire           z_ack   // transfer acknowledge
);

always @(posedge z_rst)
if (z_rst) z_vld <= 1'b0;

task trn (
  input [BW-1:0] bus
);
  reg z_trn;
begin
  z_trn = 1'b0;
  z_vld = 1'b1;
  z_bus = bus;
  while (~z_trn) @ (posedge z_clk) z_trn = z_vld & z_ack;
  #1;
  z_vld = 1'b0;
  z_bus = {BW{XZ}};
end endtask

endmodule
