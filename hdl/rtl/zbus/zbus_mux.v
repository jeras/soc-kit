module zbus_mux #(
  parameter BW  = 8,                // bus width
  parameter BN  = 2,                // number of busses
  parameter BNL = $clog2(BN),
  parameter REG = 0                 // registerd outputs for better performance
)(
  // system signals
  input  wire              clk,     // system clock
  input  wire              rst,     // asinchronous reset
  // input ports
  input  wire     [BN-1:0] zi_vld,  // transfer valid
  input  wire     [BN-1:0] zi_lck,  // arbiter lock
  input  wire  [BW*BN-1:0] zi_bus,  // grouped bus signals
  output wire     [BN-1:0] zi_ack,  // transfer acknowledge
  // output port
  output wor               zo_vld,  // transfer valid
  output wor               zo_lck,  // arbiter lock
  output wor      [BW-1:0] zo_bus,  // grouped bus signals
  input  wire              zo_ack,  // transfer acknowledge
  // contol signals
  input  wire [BNL*BN-1:0] priority
);

genvar i;

// ports sorted by priority
wire [BN-1:0] priority_request;     // list of transfer requests
wire [BN-1:0] priority_grant;       // list of transfer grants

// unsorted ports
wire [BN-1:0] port_active;
reg  [BN-1:0] port_active_r;
wire [BN-1:0] port_select;

reg           hold;

// sort valid signals into a list by priority
generate for (i=0; i<BN; i=i+1)
assign priority_request [i] = zi_vld [priority [i*BNL+:BNL]];
endgenerate

// only the port with the highest priority should be active
assign priority_grant [0] = priority_request [0];
generate for (i=1; i<BN; i=i+1)
assign priority_grant [i] = priority_request [i] & ~|priority_request [i:0];
endgenerate

// rearrange the port list into the original order
generate for (i=0; i<BN; i=i+1) 
assign port_active [i] = priority_grant [priority [i*BNL+:BNL]];
endgenerate

// registered port active
always @ (posedge clk, posedge rst)
if (rst) port_active_r <= {BN{1'b0}};
else     port_active_r <= port_active;

// the current master holds the bus till the transfer is acknowledged
// it can also keep the bus with a lock request
always @ (posedge clk, posedge rst)
if (rst) hold <= 1'b0;
else     hold <= zo_vld & (~zo_ack | zo_lck);

assign port_select = hold ? port_active_r : port_active;

// output port multiplexer
generate for (i=0; i<BN; i=i+1) begin : loop_mux
assign zo_vld = port_select [i] ?     1'b0   : zi_vld [i       ];
assign zo_lck = port_select [i] ?     1'b0   : zi_lck [i       ];
assign zo_bus = port_select [i] ? {BW{1'b0}} : zi_bus [i*BW+:BW];
end endgenerate

// input ports acknowledge
assign zi_ack = port_select & {BN{zo_ack}};

endmodule
