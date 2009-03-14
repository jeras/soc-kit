//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AHB bus master model                                                    //
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

module amba_ahb_master #(
  // bus parameters
  parameter aw = `AW,            // address bus width
  parameter dw = `DW,            // data bus width
  parameter rw = `RW,            // response width
  parameter de = `DE,            // available options are 'BIG' and 'LITTLE'
  parameter iv = 1'bx,           // idle value (value of signals when bus is idle)
  // presentation parameters 
  parameter name = "noname"      // instance name used for ERROR reporting
)(
  // AMBA AHB system signals
  input  wire          hclk,     // Bus clock
  input  wire          hresetn,  // Reset (active low)
  // AMBA AHB master signals
  output reg  [aw-1:0] haddr,    // Address bus
  output reg     [1:0] htrans,   // Transfer type
  output reg           hwrite,   // Transfer direction
  output reg     [2:0] hsize,    // Transfer size
  output reg     [2:0] hburst,   // Burst type
  output reg     [3:0] hprot,    // Protection control
  output reg  [dw-1:0] hwdata,   // Write data bus
  // AMBA AHB slave signals
  input  wire [dw-1:0] hrdata,   // Read data bus
  input  wire          hready,   // Transfer done
  input  wire [rw-1:0] hresp,    // Transfer response
  // slave response check
  output wire          error     // unexpected response from slave
);

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

// registered (delayed) values of master output signals
reg [aw-1:0] haddr_r;
reg    [1:0] htrans_r;
reg          hwrite_r;
reg    [2:0] hsiz_r;
reg    [2:0] hburst_r;
reg    [2:0] hprot_r;

// temporary value of expected slave response
reg [dw-1:0] hwdata_t;
reg [dw-1:0] hrdata_t;
reg [rw-1:0] hresp_t;

// slave response expected values
reg  [dw-1:0] hrdata_x;
reg  [rw-1:0] hresp_x;

// transfer responce
wire         trn;                 // transfer completion indicator
reg          chk = 0, chk_r = 0;  // transfer responce check enable

// line organization and width (each line is subdivided into the next columns)
parameter lw = 1 +   aw +     2 +     1 +    3 +     3 +    4 +    dw +    dw +   rw;
// name      chk, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hrdata, hresp

// FIFO signals line vector and tape memory
parameter        fl = 1024;      // FIFO deepth
reg     [lw-1:0] fifo [0:fl-1];  // tape memory
reg     [32-1:0] i_r = 0;        // FIFO read position index
reg     [32-1:0] i_w = 0;        // FIFO write position index
reg     [32-1:0] i_d = 0;        // FIFO load status (index delta)
wire             empty;          // FIFO empty indicator

// line to be loaded when FIFO empty (the AHB bus is IDLE)
reg     [lw-1:0] line0 = {1'b0, {aw{iv}},  `IDLE, {1{iv}}, {3{iv}}, {3{iv}}, {4{iv}}, {dw{iv}}, {dw{1'bx}}, {rw{1'bx}}};
//                name     chk,    haddr, htrans,  hwrite,   hsize,  hburst,   hprot,   hwdata,   hrdata_t,    hresp_t

// current FIFO status (index delta)
always @ *
	i_d = (i_w - i_r) % fl;

assign empty = (i_d == 0);

///////////////////////////////////////////////////////////////////////////////
// master state machine                                                      //
///////////////////////////////////////////////////////////////////////////////

// assign trn = hready & htrans_r[1];
assign trn = hready | (hresp != `OKAY);

// FIFO loader machine
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
end else begin
  if (i_d > 0) begin             // check the FIFO status
    if (trn | ~chk_r)
      i_r <= (i_r + 1) % fl;  // increment FIFO read index
  end
end

// memory wishbone master
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  {chk, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata_t, hrdata_t, hresp_t} <= line0;
//  htrans   <= 0;
  htrans_r <= `IDLE;          // the AHB bus should be IDLE after reset
end else begin                   // registered (delayed) bus signals
  if (trn | ~chk_r) begin                 
    haddr_r  <= haddr;
    htrans_r <= htrans;
    hwrite_r <= hwrite;
    hsiz_r   <= hsize;
    hburst_r <= hburst;
    hprot_r  <= hprot;
    hwdata   <= hwdata_t;
    hrdata_x <= hrdata_t;
    hresp_x  <= hresp_t;  
    {chk, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata_t, hrdata_t, hresp_t} <= (i_d > 0) ? fifo[i_r] : line0;
    chk_r    <= chk;
  end
end

// error due to unexpected AHB slave response
assign error = htrans_r[1] & hready & (~hwrite_r & (hrdata_x !== hrdata) | (hresp_x !== hresp));

///////////////////////////////////////////////////////////////////////////////
// tasks for loading AMBA AHB cycles into the FIFO                           //
///////////////////////////////////////////////////////////////////////////////

//
// This tasks are used to load the FIFO with bus transactions, that will be
// played in the same order as they are written. This tasks can be called from
// this module or from a higher module.
// Currently there are tasks for pauses, single and burst transfers, more
// tasks can be added.
//

// raw FIFO loading
task fifo_load;
  input [lw-1:0] line;  // raw line to be loaded to the FIFO
begin
  if (i_d + 1 < fl) begin
    fifo[i_w] <= line;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl; 
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// filling the space between cycles
task cyc_idle;
  input [32-1:0] len;        // the number of loaded IDLE cycles
  integer        n;
begin
  if (i_d + len < fl) begin
    for (n=0; n<len; n=n+1) begin
      fifo[i_w] = line0;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
  end end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// generating a single transfer
task cyc_single;
  input    [aw-1:0] adr;
  input             we;
  input       [2:0] siz;
  input       [3:0] prt;
  input    [dw-1:0] dat_o;  // output (write) data
  input    [dw-1:0] dat_i;  // expected input (read) data
begin
  if (i_d + 1 < fl) begin
    fifo[i_w] = {1'b1,   adr, `NONSEQ,     we,   siz, `SINGLE,   prt,  dat_o,    dat_i,   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    // name       chk, haddr,  htrans, hwrite, hsize,  hburst, hprot, hwdata, hrdata_t, hresp_t
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// generating a fixed length burst transfer
task cyc_burst;
  input    [aw-1:0] adr;
  input             we;
  input       [2:0] siz;
  input       [2:0] bst;    // burst type
  input       [3:0] prt;
  input [16*dw-1:0] dat_o;  // output (write) data array
  input [16*dw-1:0] dat_i;  // expected input (read) data array
  input    [aw-1:0] len;
  // local variables
  integer           n;
  reg      [aw-1:0] mask;   // address mask for wrapping bursts
  reg      [aw-1:0] incr;   // address increment
  reg      [aw-1:0] badr;   // calculated burst address
  integer           midx;   // pointer into the data array
begin
  if (i_d + 2**(bst[2:1]+1) < fl) begin
    mask = (1 << (siz+bst[2:1]+1)) - 1;
    badr = adr;
    midx = 2**(bst[2:1]+1)-1;
    fifo[i_w] = {1'b1,  badr, `NONSEQ,     we,   siz,    bst,   prt, dat_o[dw*midx+:dw], dat_i[dw*midx+:dw],   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    for (n=1; n<2**(bst[2:1]+1); n=n+1) begin
    incr = (2**siz)*n;
    if (bst[0])  badr =  adr          +         incr;
    else         badr = (adr & ~mask) + ((adr + incr) & mask);
    midx = midx - 1;
    fifo[i_w] = {1'b1,  badr,    `SEQ,     we,   siz,    bst,   prt, dat_o[dw*midx+:dw], dat_i[dw*midx+:dw],   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    // name       chk, haddr,  htrans, hwrite, hsize, hburst, hprot,             hwdata,           hrdata_t, hresp_t
    end
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask


endmodule

