module zbus_sink #(
  parameter BW = 0,
  parameter XZ = 1'bx
)(
  // system signals
  input  wire           z_clk,  // system clock
  input  wire           z_rst,  // asinchronous reset
  // zbus signals
  input  wire           z_vld,  // transfer valid
  input  wire  [BW-1:0] z_bus,  // grouped bus signals
  output wire           z_ack   // transfer acknowledge
);

assign z_ack = 1'b1;

assign z_trn = z_vld & z_ack;

always @ (posedge z_clk, posedge z_rst)
if (rst) begin
end else if (trn) begin
end


endmodule
