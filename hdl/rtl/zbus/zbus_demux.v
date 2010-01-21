module zbus_demux #(
  parameter BW  = 8,                // bus width
  parameter BN  = 2,                // number of busses
  parameter DI  = 1'bx              // data idle value
)(
  // system signals
  input  wire              clk,     // system clock
  input  wire              rst,     // asinchronous reset
  // input ports
  input  wire              zi_vld,  // transfer valid
  input  wire     [BW-1:0] zi_bus,  // grouped bus signals
  output wor               zi_ack,  // transfer acknowledge
  // output port
  output wire     [BN-1:0] zo_vld,  // transfer valid
  output wire  [BW*BN-1:0] zo_bus,  // grouped bus signals
  input  wire     [BN-1:0] zo_ack,  // transfer acknowledge
  // contol signals
  input  wire     [BN-1:0] enable
);

genvar i;

// output ports de-multiplexer
generate for (i=0; i<BN; i=i+1) begin : loop_mux
assign zo_vld [i       ] = enable [i] ?     1'b0 : zi_vld;
assign zo_bus [i*BW+:BW] = enable [i] ? {BW{DI}} : zi_bus;
end endgenerate

// input port enable
assign zi_ack = |(enable & zo_ack);

endmodule
