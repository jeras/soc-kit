module zbus_fifo_reg_async_tb ();

localparam BW = 8;
localparam LN = 4;

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
  $dumpvars(0, zbus_fifo_reg_async_tb);
  for (i=0; i<LN; i=i+1)
  $dumpvars(0, zbus_fifo_reg_async.mem[i]);
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
  for (i=0; i<19; i=i+1) begin
    zbus_source.trn (i);
    zbus_sink.trn   (i, {BW{1'b1}}, 0);
  end
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

zbus_fifo_reg_async #(
  .BW  (BW),
  .LN  (LN)
) zbus_fifo_reg_async (
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

zbus_sink #(
  .BW  (BW),
  .LN  (LN)
) zbus_sink (
  // system signals
  .z_clk  (zo_clk),
  .z_rst  (zo_rst),
  // zbus
  .z_vld  (zo_vld),
  .z_bus  (zo_bus),
  .z_ack  (zo_ack)
);

endmodule
