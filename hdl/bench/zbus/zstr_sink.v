module zstr_sink #(
  parameter BW  = 8,            // bus width
  parameter LN  = 2,            // line number (pipeline deepth)
  parameter LNL = $clog2(LN)    // line number logarithm (number of bits for counters)
)(
  // system signals
  input  wire           z_clk,  // system clock
  input  wire           z_rst,  // asinchronous reset
  // zstr signals
  input  wire           z_vld,  // transfer valid
  input  wire  [BW-1:0] z_bus,  // grouped bus signals
  output wire           z_ack   // transfer acknowledge
);

reg  [BW-1:0] mem_bus [LN-1:0];  // transfer pipeline: transfer bus data
reg  [BW-1:0] mem_msk [LN-1:0];  // transfer pipeline: transfer bus data mask
reg  [32-1:0] mem_dly [LN-1:0];  // transfer pipeline: transfer acknowledge delay
reg  [LN-1:0] mem_vld;           // valid status of each fifo location

reg [LNL-1:0] wpt, rpt;          // write and read pointers

reg  [32-1:0] dly;               // transfer acknowledge delay counter 

// if there is a transfer in the pipeline use the provided delay
assign z_ack = mem_vld[rpt] ? (mem_dly[rpt] == dly) : 1'b1;

assign z_trn = z_vld & z_ack;

//////////////////////////////////////////////////////////////////////////////
// write into the transfer pipeline                                         //
//////////////////////////////////////////////////////////////////////////////

always @ (posedge z_rst)
if (z_rst) begin
  mem_vld <= {LN{1'b0}};
  wpt     <= 0;
end

// task for adding transfers into the pipeline
task trn (
  input [BW-1:0] bus,
  input [BW-1:0] msk,
  input [32-1:0] dly
);
begin
  mem_bus [wpt] = bus;
  mem_msk [wpt] = msk;
  mem_dly [wpt] = dly;
  mem_vld [wpt] = 1'b1;
  wpt = wpt+1;
end  
endtask

//////////////////////////////////////////////////////////////////////////////
// read from the transfer pipeline                                          //
//////////////////////////////////////////////////////////////////////////////

always @ (posedge z_clk, posedge z_rst)
if (z_rst) begin
  rpt <= 0;
  dly <= 0;
end else begin
  if (z_vld) begin
    if (z_ack) begin
      dly <= 0;
      if (mem_vld[rpt]) begin
        rpt <= (rpt + 1) % LN;
        if (mem_msk[rpt] & (mem_bus[rpt] ^ z_bus))
          $display ("DEBUG: ERROR received %h != %h, t=%0t", z_bus, mem_bus[rpt], $time);
        else
          $display ("DEBUG: SUCESS received %h", z_bus);
        mem_vld[rpt] <= 1'b0;
      end
    end else begin
      dly <= dly + 1;
    end
  end else begin
    dly <= 0;
  end
end

wire [BW-1:0] bus;
wire [BW-1:0] msk;
wire [32-1:0] dly1;
assign bus = mem_bus[rpt];
assign msk = mem_msk[rpt];
assign dly1 = mem_dly[rpt];

endmodule
