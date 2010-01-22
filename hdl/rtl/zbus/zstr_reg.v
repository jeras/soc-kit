module zstr_reg #(
  parameter BW  = 0,            // bus width
  parameter RI  = 1,            // registered outputs on the input side
  parameter RO  = 1             // registered outputs on the output side
)(
  input  wire          z_clk,   // system clock
  input  wire          z_rst,   // asinchronous reset
  // input port
  input  wire          zi_vld,  // transfer valid
  input  wire [BW-1:0] zi_bus,  // grouped bus signals
  output wire          zi_ack,  // transfer acknowledge
  // output port
  output wire          zo_vld,  // transfer valid
  output wire [BW-1:0] zo_bus,  // grouped bus signals
  input  wire          zo_ack   // transfer acknowledge
);

// local middle signals
reg           li_ack;

// local middle signals
wire          lm_vld;
wire [BW-1:0] lm_bus;
wire          lm_ack;

// local output signals
reg           lo_vld;
reg  [BW-1:0] lo_bus;

//////////////////////////////////////////////////////////////////////////////
// registered input side
//////////////////////////////////////////////////////////////////////////////

assign lm_vld = zi_vld;
assign lm_bus = zi_bus;

assign zi_ack = lm_ack;

//////////////////////////////////////////////////////////////////////////////
// registered output side
//////////////////////////////////////////////////////////////////////////////

assign lm_ack = zo_ack | ~zo_vld;

always @ (posedge z_clk, posedge z_rst)
if (z_rst)       lo_vld <= 1'b0;
else if (lm_ack) lo_vld <= lm_vld;

always @ (posedge z_clk)
if (lm_vld & lm_ack) lo_bus <= lm_bus;

assign zo_vld = lo_vld;
assign zo_bus = lo_bus;

endmodule
