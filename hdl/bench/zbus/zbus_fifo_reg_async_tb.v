module zbus_tb ();

localparam BW = 8; 

integer i;

// system signals
reg            zi_clk, zo_clk;
reg            zi_rst, zo_rst;
// zbus signals
wire           zi_vld, zo_vld;
wire  [BW-1:0] zi_bus, zo_bus;
wire           zi_ack, zo_ack;

wire           zi_trn, zo_trn;

// request for a dumpfile
initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, zbus_tb);
  for (i=0; i<4; i=i+1)
  $dumpvars(0, zbus_fifo_async.mem[i]);
end

// generate two asinchronous clocks
initial zi_clk = 1'b1;
always #5 zi_clk = ~zi_clk;

initial zo_clk = 1'b1;
always #7 zo_clk = ~zo_clk;

initial begin
  zi_rst = 1'b1;
  repeat (2) @ (posedge zi_clk);
  zi_rst = 1'b0;
  repeat (2) @ (posedge zi_clk);
  for (i=0; i<19; i=i+1)  zbus_source.trn (i);
  repeat (4) @ (posedge zo_clk);
  $finish();
end

initial begin
  zo_rst = 1'b1;
  repeat (2) @ (posedge zo_clk);
  zo_rst = 1'b0;
end

zbus_source #(
  .BW  (BW)
) zbus_source (
  // system signals
  .z_clk  (zi_clk),
  .z_rst  (zi_rst),
  // zbus
  .z_vld  (zi_vld),
  .z_bus  (zi_bus),
  .z_ack  (zi_ack)
);

zbus_fifo_async #(
  .BW  (BW),
  .LN  (4)
) zbus_fifo_async (
  // system signals
  .zi_clk  (zi_clk),
  .zi_rst  (zi_rst),
  .zi_vld  (zi_vld),
  .zi_bus  (zi_bus),
  .zi_ack  (zi_ack),
  // system signals
  .zo_clk  (zo_clk),
  .zo_rst  (zo_rst),
  .zo_vld  (zo_vld),
  .zo_bus  (zo_bus),
  .zo_ack  (zo_ack)
);

assign zo_ack = 1'b1;

assign zo_trn = zo_vld & zo_ack;

integer o;

always @ (posedge zo_clk, posedge zo_rst)
if (zo_rst) o <= 0;
else        o <= o + zo_trn;

always @ (posedge zo_clk)
if (zo_trn) begin
  if (zo_bus == o)  $display ("SUCESS: transfer %d", o);
  else              $display ("ERROR : transfer %d", o);
end

endmodule


module zbus_source #(
  parameter BW = 0,
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
