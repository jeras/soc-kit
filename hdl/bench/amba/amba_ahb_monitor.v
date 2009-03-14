//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AMBA AHB bus monitor                                                    //
//                                                                          //
//  Copyright (C) 2008  Iztok Jeras                                         //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  This RTL is free hardware: you can redistribute it and/or modify        //
//  it under the terms of the GNU Lesser General Public License             //
//  as published by the Free Software Foundation, either                    //
//  version 3 of the License, or (at your option) any later version.        //
//                                                                          //
//  This RTL is distributed in the hope that it will be useful,             //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.   //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

`include "amba_ahb_defines.v"

module amba_ahb_monitor #(
  // bus paramaters
  parameter aw = `AW,    // address bus width
  parameter dw = `DW,    // data bus width
  parameter de = `DE,    // endianess
  parameter rw = `RW,    // response signal width
  // instance name to be used in messages
  parameter name = "AHB monitor",
  // memory parameters
  parameter ms = 1024,   // memory size (in Bytes)
  // internal parameter
  parameter cw = 32,     // cycle and burst length couner widths
  // verbosity level
  parameter v_trn = 1,
  parameter v_err = 1
)(
  // AMBA AHB system signals
  input  wire          hclk,     // Bus clock
  input  wire          hresetn,  // Reset (active low)
  // AMBA AHB decoder signal
  input  wire          hsel,     // Slave select
  // AMBA AHB master signals
  input  wire [aw-1:0] haddr,    // Address bus
  input  wire    [1:0] htrans,   // Transfer type
  input  wire          hwrite,   // Transfer direction
  input  wire    [2:0] hsize,    // Transfer size
  input  wire    [2:0] hburst,   // Burst type
  input  wire    [3:0] hprot,    // Protection control
  input  wire [dw-1:0] hwdata,   // Write data bus
  // AMBA AHB slave signals
  input  wire [dw-1:0] hrdata,   // Read data bus
  input  wire          hready,   // Transfer done
  input  wire [rw-1:0] hresp,    // Transfer response
);

localparam bw = dw/8;  // data bus width in Bytes

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

integer debug_cnt = 0;  // debug message counter
integer error_cnt = 0;  // error message counter

initial
  $timeformat (-9, 1, "ns", 10);

// cycle timeout couner
reg  [cw-1:0] timeout_cnt;

// registered AHB input signals
// _p - delayed for one clock Period
// _r - value Registered from transfer request to acknowledge
// _b - value stored from Burst start to end
reg           hresetn_r, hresetn_p;   
reg           hsel_r,    hsel_p;   
reg  [aw-1:0] haddr_r,   haddr_p,   haddr_b;
reg     [1:0] htrans_r,  htrans_p;
reg           hwrite_r,  hwrite_p;
reg     [2:0] hsize_r,   hsize_p;
reg     [2:0] hburst_r,  hburst_p;
reg     [3:0] hprot_r,   hprot_p;
reg  [dw-1:0] hwdata_r,  hwdata_p;
reg  [dw-1:0] hrdata_r,  hrdata_p;
reg           hready_r,  hready_p;
reg  [rw-1:0] hresp_r,   hresp_p;

// slave memory
reg     [7:0] mem [0:ms-1];

genvar i;

wire    [7:0] bytes;
wire [dw-1:0] wdata;    // write data buse used for endian byte swap
wire [dw-1:0] rdata;    // read data buse used for endian byte swap
wire          trn;      // read or write transfer
wire          trn_reg;  // transfer request
wire          trn_ack;  // transfer acknowledge

// burst control signals
wire [aw-1:0] burst_msk;  // burst address mask for wrapped bursts
reg  [32-1:0] burst_cnt;  // counter of burst beats
wire [32-1:0] burst_len;  // expected number of burst beats

//////////////////////////////////////////////////////////////////////////////
// registered input signals                                                 //
//////////////////////////////////////////////////////////////////////////////

// signals delayed for a single clock period
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  hresetn_p <= #1 1'b0;
  htrans_p  <= #1 `IDLE;
  hready_p  <= #1 1'b0;
  hresp_p   <= #1 `OKAY;
end else begin
  hresetn_p <= #1 1'b1;
  hsel_p    <= #1 hsel;
  haddr_p   <= #1 haddr;
  htrans_p  <= #1 htrans;
  hwrite_p  <= #1 hwrite;
  hsize_p   <= #1 hsize;
  hburst_p  <= #1 hburst;
  hprot_p   <= #1 hprot;
  hwdata_p  <= #1 hwdata;
  hrdata_p  <= #1 hrdata;
  hready_p  <= #1 hready;
  hresp_p   <= #1 hresp;
end

// signals registered for the time of an AHB transfer cycle
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  hresetn_r <= #1 1'b0;
  htrans_r  <= #1 `IDLE;
  hready_r  <= #1 1'b0;
  hresp_r   <= #1 `OKAY;
end else if (hready) begin
  hresetn_r <= #1 1'b1;
  hsel_r    <= #1 hsel;
  haddr_r   <= #1 haddr;
  htrans_r  <= #1 htrans;
  hwrite_r  <= #1 hwrite;
  hsize_r   <= #1 hsize;
  hburst_r  <= #1 hburst;
  hprot_r   <= #1 hprot;
  hwdata_r  <= #1 hwdata;
  hrdata_r  <= #1 hrdata;
  hready_r  <= #1 hready;
  hresp_r   <= #1 hresp;
end

//////////////////////////////////////////////////////////////////////////////
// measure response times                                                   //
//////////////////////////////////////////////////////////////////////////////

// cycle and burst length couners
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  timeout_cnt <= #1 0;
end else begin
  if (hready | (htrans_r != `IDLE))
  timeout_cnt <= #1 timeout_cnt + 1;
end

//////////////////////////////////////////////////////////////////////////////
// memory and data bus implementation                                       //
//////////////////////////////////////////////////////////////////////////////

assign trn_req = ((htrans_r == `NONSEQ) | (htrans_r == `SEQ));
assign trn_ack = (hready);
assign trn     = trn_req & trn_ack;

assign bytes = 2**hsize_r;

// write to memory
generate
  for (i=0; i<bw; i=i+1) begin
    always @(posedge hclk) begin
      if (trn & hwrite_r & (hresp == `OKAY)) begin
        if ((haddr_r%bw <= i) & (i < (haddr_r%bw + bytes)))  mem [haddr_r/bw*bw+i] <= #1 hwdata [8*i+:8];
      end
    end
  end
endgenerate

// read from memory
generate
  for (i=0; i<bw; i=i+1) begin
    assign rdata [8*i+:8] = ((trn & ~hwrite_r & (hresp == `OKAY)) & (haddr_r%bw <= i) & (i < (haddr_r%bw + bytes))) ? mem [haddr_r/bw*bw+i] : 8'hxx;
  end
endgenerate

//////////////////////////////////////////////////////////////////////////////
// reporting transfer cycles                                                //
//////////////////////////////////////////////////////////////////////////////

generate if (v_trn) begin

initial begin
  $timeformat (-9, 1, "ns", 10);
  $display ("DEBUG: t=%t : %s: ", $time, name, "  --------------------------------------------------------------------------------------------------- ");
  $display ("DEBUG: t=%t : %s: ", $time, name, " | HADDR    | HTRANS | HBURST | HWRITE | HSIZE   | HPROT[0]     | HWDATA   | HRDATA   | HRESP || bst |");
  $display ("DEBUG: t=%t : %s: ", $time, name, "  --------------------------------------------------------------------------------------------------- ");
end

always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  $display ("DEBUG: t=%t : %s: ", $time, name, "HRESETN was asserted.");
end else if (trn & hsel_r) begin
  $display ("DEBUG: t=%t : %s: ", $time, name, " | ",
    "%h | ",
      haddr_r,
    "%s | ",
      (htrans_r == `IDLE  ) ? "IDLE  " :
      (htrans_r == `BUSY  ) ? "BUSY  " :
      (htrans_r == `NONSEQ) ? "NONSEQ" :
      (htrans_r == `SEQ   ) ? "SEQ   " :
                              "******" ,
    "%s | ",
      (hburst_r == `SINGLE) ? "SINGLE" :
      (hburst_r == `INCR  ) ? "INCR  " :
      (hburst_r == `WRAP4 ) ? "WRAP4 " :
      (hburst_r == `INCR4 ) ? "INCR4 " :
      (hburst_r == `WRAP8 ) ? "WRAP8 " :
      (hburst_r == `INCR8 ) ? "INCR8 " :
      (hburst_r == `WRAP16) ? "WRAP16" :
      (hburst_r == `INCR16) ? "INCR16" :
                              "******" ,
    "%s  | ",
      (hwrite_r == `READ )  ? "READ " :
      (hwrite_r == `WRITE)  ? "WRITE" :
                              "*****" ,
    "%s | ",
      (hsize_r == 3'b000)   ? "   8bit" :
      (hsize_r == 3'b001)   ? "  16bit" :
      (hsize_r == 3'b010)   ? "  32bit" :
      (hsize_r == 3'b011)   ? "  64bit" :
      (hsize_r == 3'b100)   ? " 128bit" :
      (hsize_r == 3'b101)   ? " 256bit" :
      (hsize_r == 3'b110)   ? " 512bit" :
      (hsize_r == 3'b111)   ? "1024bit" :
                              "*******" ,
    "%s | ",
      (hprot_r[0] == 1'b0)  ? "Opcode fetch" :
      (hprot_r[0] == 1'b1)  ? "Data access " :
                              "************" ,
    "%h | %h | ",
       hwdata, hrdata,
    "%s | ",
      (hresp == `OKAY )     ? "OKAY " :
      (hresp == `ERROR)     ? "ERROR" :
      (hresp == `RETRY)     ? "RETRY" :
      (hresp == `SPLIT)     ? "SPLIT" :
                              "*****" ,
    "%4d |", burst_cnt
  );
  debug_cnt <= #1 debug_cnt + 1;
end

end endgenerate

//////////////////////////////////////////////////////////////////////////////
// reporting errors and warnings                                            //
//////////////////////////////////////////////////////////////////////////////

// Master errors

// address or control signal changes during a cycle
// (after the request, before a termination)
always @(posedge hclk)
if (hresetn_p & ((htrans_p == `NONSEQ) | (htrans_p == `SEQ)) & ~hready_p & (hresp == `IDLE)) begin
  // address signal changes
  if (hsel_p   !== hsel)
    $display ("ERROR: t=%t : %s: HSEL   changed during a wait state.", $time, name);
  if (haddr_p  !== haddr)
    $display ("ERROR: t=%t : %s: HADDR  changed during a wait state.", $time, name);
  // control signal changes
  if (htrans_p !== htrans) begin
    if (htrans != `BUSY)
    $display ("ERROR: t=%t : %s: HTRANS changed during a wait state.", $time, name);
  end
  if (hwrite_p !== hwrite)
    $display ("ERROR: t=%t : %s: HWRITE changed during a wait state.", $time, name);
  if (hsize_p  !== hsize)
    $display ("ERROR: t=%t : %s: HSIZE  changed during a wait state.", $time, name);
  if (hburst_p !== hburst)
    $display ("ERROR: t=%t : %s: HBURST changed during a wait state.", $time, name);
  if (hprot_p  !== hprot)
    $display ("ERROR: t=%t : %s: HPROT  changed during a wait state.", $time, name);
  // data signal changes during a write cycle
  if ( (hwdata_p !== hwdata) & hwrite_r )
    $display ("ERROR: t=%t : %s: HWDATA changed during a wait state.", $time, name);
end

// burst length and address check
always @(posedge hclk)
if (hready_p & hresetn_p & hsel_r) begin
  if (hburst_p != `SINGLE) begin
    if (burst_cnt <  burst_len-1) begin
      if (hburst != hburst_p)
        $display ("ERROR: t=%t : %s: HBURST changed during a burst sequence.", $time, name);
    end
    if (burst_cnt <  burst_len-1) begin
      if (~((htrans == `SEQ) | (htrans == `BUSY)))
        $display ("ERROR: t=%t : %s: HBURST early burst termination.", $time, name);
    end
    if (burst_cnt == burst_len-1) begin
      if (~((htrans == `NONSEQ) | (htrans == `IDLE)))
        $display ("ERROR: t=%t : %s: HBURST missed burst termination.", $time, name);
    end
    if (htrans == `SEQ) begin
      if (haddr_r[aw-1:10] != haddr[aw-1:10])
        $display ("ERROR: t=%t : %s: HADDR burst crossed the 1kB boundary.", $time, name);
    end
  end
end

// registered first address of a burst
always @(negedge hresetn, posedge hclk)
if (~hresetn)
  burst_cnt <= #1 0;
else if (hready) begin
  if (htrans == `NONSEQ) begin
    haddr_b   <= #1 haddr;
    burst_cnt <= #1 0;
  end else if (hburst_r != `SINGLE)
    burst_cnt <= #1 burst_cnt+1;
end

// for an incrementing burst of undefined length the burst length is limited to 1KB
assign trans_siz = 1 << hsize;
assign burst_typ = hburst_r[0];
assign burst_len = (hburst_r == `SINGLE) ? 1 : (hburst_r == `INCR) ? 1 << (10-hsize) : 1 << (hburst_r[2:1]+1);
assign burst_msk = (1 << (hsize_r+hburst_r[2:1]+1)) - 1;
assign burst_adr = (burst_typ) ?                            haddr_b + burst_cnt * trans_siz
                               : (haddr_b & ~burst_msk) + ((haddr_b + burst_cnt * trans_siz) & burst_msk);

endmodule

