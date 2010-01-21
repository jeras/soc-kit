module zbus_fifo_reg_async #(
  parameter BW  = 0,             // bus width
  parameter LN  = 2,             // number of locations (FIFO deepth)
  parameter LNL = $clog2(LN),
  parameter CNL = $clog2(LN+1),
  parameter CN  = 1<CNL
)(
  // input (write) port
  input  wire           zi_clk,  // system clock
  input  wire           zi_rst,  // asinchronous reset
  input  wire           zi_vld,  // transfer valid
  input  wire  [BW-1:0] zi_bus,  // grouped bus signals
  output wire [CNL-1:0] zi_num,  // number of available (empty) locations
  output wire           zi_ack,  // transfer acknowledge
  // output (read) port
  input  wire           zo_clk,  // system clock
  input  wire           zo_rst,  // asinchronous reset
  output wire           zo_vld,  // transfer valid
  output wire  [BW-1:0] zo_bus,  // grouped bus signals
  output wire [CNL-1:0] zo_num,  // number of available (loaded) locations
  input  wire           zo_ack   // transfer acknowledge
);

genvar i;

reg  [BW-1:0] mem [LN-1:0];      // fifo memory

reg [LNL-1:0] wpb;               // write binary pointer
reg [LNL-1:0] rpb;               // read  binary pointer

reg [CNL-1:0] wcg, wcs;          // write gray counter (synced)
reg [CNL-1:0] rcg, rcs;          // read  gray counter (synced)

function automatic [CNL-1:0] clp (input [CNL-1:0] num, input integer max);
  clp = (num < max) ? num : 0;
endfunction

function automatic [CNL-1:0] b2g (input [CNL-1:0] num);
  b2g = (num < CN) ? num : 0;
endfunction

function automatic [CNL-1:0] g2b (input [CNL-1:0] num);
  g2b = (num < CN) ? num : 0;
endfunction

//////////////////////////////////////////////////////////////////////////////
// write port clock kode
//////////////////////////////////////////////////////////////////////////////

assign zi_ack = |zi_num;
assign zi_num = clp(LN + rcs - wcg, LN+1);

wire [3:0] test;
assign test = LN + rcs - wcg;

assign zi_trn = zi_vld & zi_ack;

always @ (posedge zi_clk, posedge zi_rst)
if (zi_rst) wpb <= {LNL{1'b0}};
else        wpb <= clp(wpb + zi_trn, LN);

always @ (posedge zi_clk, posedge zi_rst)
if (zi_rst) wcg <= {CNL{1'b0}};
else        wcg <= wcg + zi_trn;

always @ (posedge zi_clk, posedge zi_rst)
if (zi_rst) rcs <= {CNL{1'b0}};
else        rcs <= rcg;

always @ (posedge zi_clk)
if (zi_trn) mem [wpb] <= zi_bus;

//////////////////////////////////////////////////////////////////////////////
// write port clock kode
//////////////////////////////////////////////////////////////////////////////

assign zo_vld = wcs != rcg;
assign zo_num = clp(wcs - rcg, CN);

assign zo_trn = zo_vld & zo_ack;

always @ (posedge zo_clk, posedge zo_rst)
if (zi_rst) rpb <= {LNL{1'b0}};
else        rpb <= clp(rpb + zo_trn, LN);

always @ (posedge zo_clk, posedge zo_rst)
if (zi_rst) rcg <= {CNL{1'b0}};
else        rcg <= rcg + zo_trn;

always @ (posedge zo_clk, posedge zo_rst)
if (zi_rst) wcs <= {CNL{1'b0}};
else        wcs <= wcg;

assign zo_bus = mem [rpb];


endmodule
