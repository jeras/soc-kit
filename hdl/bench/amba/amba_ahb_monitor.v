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
  parameter AW = `AW,    // address bus width
  parameter DW = `DW,    // data bus width
  parameter DE = `DE,    // endianess
  parameter RW = `RW,    // response signal width
  // instance name to be used in messages
  parameter NAME = "AHB monitor",
  // memory parameters
  parameter MS = 1024,   // memory size (in Bytes)
  // verbosity level
  parameter V_TRN = 1,
  parameter V_ERR = 1
)(
  // AMBA AHB system signals
  input  wire          hclk,     // Bus clock
  input  wire          hresetn,  // Reset (active low)
  // AMBA AHB decoder signal
  input  wire          hsel,     // Slave select
  // AMBA AHB master signals
  input  wire [AW-1:0] haddr,    // Address bus
  input  wire    [1:0] htrans,   // Transfer type
  input  wire          hwrite,   // Transfer direction
  input  wire    [2:0] hsize,    // Transfer size
  input  wire    [2:0] hburst,   // Burst type
  input  wire    [3:0] hprot,    // Protection control
  input  wire [DW-1:0] hwdata,   // Write data bus
  // AMBA AHB slave signals
  input  wire [DW-1:0] hrdata,   // Read data bus
  input  wire          hready,   // Transfer done
  input  wire [RW-1:0] hresp     // Transfer response
);

localparam bw = DW/8;  // data bus width in Bytes

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

integer debug_cnt = 0;  // debug message counter
integer error_cnt = 0;  // error message counter

initial
  $timeformat (-9, 1, "ns", 10);

// cycle timeout couner
integer timeout_cnt;

// registered AHB input signals
// _p - delayed for one clock Period
// _r - value Registered from transfer request to acknowledge
// _b - value stored from Burst start to end
reg           hresetn_r, hresetn_p;   
reg           hsel_r,    hsel_p;   
reg  [AW-1:0] haddr_r,   haddr_p,   haddr_b;
reg     [1:0] htrans_r,  htrans_p;
reg           hwrite_r,  hwrite_p;
reg     [2:0] hsize_r,   hsize_p;
reg     [2:0] hburst_r,  hburst_p;
reg     [3:0] hprot_r,   hprot_p;
reg  [DW-1:0] hwdata_r,  hwdata_p;
reg  [DW-1:0] hrdata_r,  hrdata_p;
reg           hready_r,  hready_p;
reg  [RW-1:0] hresp_r,   hresp_p;

// slave memory
reg     [7:0] mem [0:MS-1];

genvar i;

wire    [7:0] bytes;
wire [DW-1:0] wdata;    // write data buse used for endian byte swap
wire [DW-1:0] rdata;    // read data buse used for endian byte swap
wire          trn;      // read or write transfer
wire          trn_reg;  // transfer request
wire          trn_ack;  // transfer acknowledge

// burst control signals
wire [AW-1:0] burst_msk;  // burst address mask for wrapped bursts
reg  [32-1:0] burst_cnt;  // counter of burst beats
wire [32-1:0] burst_len;  // expected number of burst beats

//////////////////////////////////////////////////////////////////////////////
// registered input signals                                                 //
//////////////////////////////////////////////////////////////////////////////

// signals delayed for a single clock period
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  hresetn_p <= 1'b0;
  htrans_p  <= `H_IDLE;
  hready_p  <= 1'b0;
  hresp_p   <= `H_OKAY;
end else begin
  hresetn_p <= 1'b1;
  hsel_p    <= hsel;
  haddr_p   <= haddr;
  htrans_p  <= htrans;
  hwrite_p  <= hwrite;
  hsize_p   <= hsize;
  hburst_p  <= hburst;
  hprot_p   <= hprot;
  hwdata_p  <= hwdata;
  hrdata_p  <= hrdata;
  hready_p  <= hready;
  hresp_p   <= hresp;
end

// signals registered for the time of an AHB transfer cycle
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  hresetn_r <= 1'b0;
  htrans_r  <= `H_IDLE;
  hready_r  <= 1'b0;
  hresp_r   <= `H_OKAY;
end else if (hready) begin
  hresetn_r <= 1'b1;
  hsel_r    <= hsel;
  haddr_r   <= haddr;
  htrans_r  <= htrans;
  hwrite_r  <= hwrite;
  hsize_r   <= hsize;
  hburst_r  <= hburst;
  hprot_r   <= hprot;
  hwdata_r  <= hwdata;
  hrdata_r  <= hrdata;
  hready_r  <= hready;
  hresp_r   <= hresp;
end

//////////////////////////////////////////////////////////////////////////////
// measure response times                                                   //
//////////////////////////////////////////////////////////////////////////////

// cycle and burst length couners
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  timeout_cnt <= 0;
end else begin
  if (hready | (htrans_r != `H_IDLE))
  timeout_cnt <= timeout_cnt + 1;
end

//////////////////////////////////////////////////////////////////////////////
// memory and data bus implementation                                       //
//////////////////////////////////////////////////////////////////////////////

assign trn_req = ((htrans_r == `H_NONSEQ) | (htrans_r == `H_SEQ));
assign trn_ack = (hready);
assign trn     = trn_req & trn_ack;

assign bytes = 2**hsize_r;

// write to memory
generate
  for (i=0; i<bw; i=i+1) begin
    always @(posedge hclk) begin
      if (trn & hwrite_r & (hresp == `H_OKAY)) begin
        if ((haddr_r%bw <= i) & (i < (haddr_r%bw + bytes)))  mem [haddr_r/bw*bw+i] <= hwdata [8*i+:8];
      end
    end
  end
endgenerate

// read from memory
generate
  for (i=0; i<bw; i=i+1) begin
    assign rdata [8*i+:8] = ((trn & ~hwrite_r & (hresp == `H_OKAY)) & (haddr_r%bw <= i) & (i < (haddr_r%bw + bytes))) ? mem [haddr_r/bw*bw+i] : 8'hxx;
  end
endgenerate

//////////////////////////////////////////////////////////////////////////////
// reporting transfer cycles                                                //
//////////////////////////////////////////////////////////////////////////////

generate if (V_TRN) begin

initial begin
  $timeformat (-9, 1, "ns", 10);
  $display ("DEBUG: t=%t : %s: ", $time, NAME, "  --------------------------------------------------------------------------------------------------- ");
  $display ("DEBUG: t=%t : %s: ", $time, NAME, " | HADDR    | HTRANS | HBURST | HWRITE | HSIZE   | HPROT[0]     | HWDATA   | HRDATA   | HRESP || bst |");
  $display ("DEBUG: t=%t : %s: ", $time, NAME, "  --------------------------------------------------------------------------------------------------- ");
end

always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  $display ("DEBUG: t=%t : %s: ", $time, NAME, "HRESETN was asserted.");
end else if (trn & hsel_r) begin
  $display ("DEBUG: t=%t : %s: ", $time, NAME, " | ",
    "%h | ",
      haddr_r,
    "%s | ",
      (htrans_r == `H_IDLE    ) ? "IDLE  " :
      (htrans_r == `H_BUSY    ) ? "BUSY  " :
      (htrans_r == `H_NONSEQ  ) ? "NONSEQ" :
      (htrans_r == `H_SEQ     ) ? "SEQ   " :
                                  "******" ,
    "%s | ",
      (hburst_r == `H_SINGLE  ) ? "SINGLE" :
      (hburst_r == `H_INCR    ) ? "INCR  " :
      (hburst_r == `H_WRAP4   ) ? "WRAP4 " :
      (hburst_r == `H_INCR4   ) ? "INCR4 " :
      (hburst_r == `H_WRAP8   ) ? "WRAP8 " :
      (hburst_r == `H_INCR8   ) ? "INCR8 " :
      (hburst_r == `H_WRAP16  ) ? "WRAP16" :
      (hburst_r == `H_INCR16  ) ? "INCR16" :
                                  "******" ,
    "%s  | ",
      (hwrite_r == `H_READ    ) ? "READ " :
      (hwrite_r == `H_WRITE   ) ? "WRITE" :
                                  "*****" ,
    "%s | ",
      (hsize_r  == H_SIZE_8   ) ? "   8bit" :
      (hsize_r  == H_SIZE_16  ) ? "  16bit" :
      (hsize_r  == H_SIZE_32  ) ? "  32bit" :
      (hsize_r  == H_SIZE_64  ) ? "  64bit" :
      (hsize_r  == H_SIZE_128 ) ? " 128bit" :
      (hsize_r  == H_SIZE_256 ) ? " 256bit" :
      (hsize_r  == H_SIZE_512 ) ? " 512bit" :
      (hsize_r  == H_SIZE_1024) ? "1024bit" :
                                  "*******" ,
    "%s | ",
      (hprot_r[0] == 1'b0) ? "Opcode fetch" :
      (hprot_r[0] == 1'b1) ? "Data access " :
                             "************" ,
       "%s | ",
      (hprot_r[1] == 1'b0) ? "" :
      (hprot_r[1] == 1'b1) ? "" :
                             "************" ,
   "%s | ",
      (hprot_r[2] == 1'b0) ? "" :
      (hprot_r[2] == 1'b1) ? "" :
                             "************" ,
   "%s | ",
      (hprot_r[3] == 1'b0) ? "" :
      (hprot_r[3] == 1'b1) ? "" :
                             "************" ,
   "%h | %h | ",
       hwdata, hrdata,
    "%s | ",
      (hresp == `H_OKAY       ) ? "OKAY " :
      (hresp == `H_ERROR      ) ? "ERROR" :
      (hresp == `H_RETRY      ) ? "RETRY" :
      (hresp == `H_SPLIT      ) ? "SPLIT" :
                                  "*****" ,
    "%4d |", burst_cnt
  );
  debug_cnt <= debug_cnt + 1;
end

end endgenerate

//////////////////////////////////////////////////////////////////////////////
// reporting errors and warnings                                            //
//////////////////////////////////////////////////////////////////////////////

// Master errors

// address or control signal changes during a cycle
// (after the request, before a termination)
always @(posedge hclk)
if (hresetn_p & ((htrans_p == `H_NONSEQ) | (htrans_p == `H_SEQ)) & ~hready_p & (hresp == `H_IDLE)) begin
  // address signal changes
  if (hsel_p   !== hsel)
    $display ("ERROR: t=%t : %s: HSEL   changed during a wait state.", $time, NAME);
  if (haddr_p  !== haddr)
    $display ("ERROR: t=%t : %s: HADDR  changed during a wait state.", $time, NAME);
  // control signal changes
  if (htrans_p !== htrans) begin
    if (htrans != `BUSY)
    $display ("ERROR: t=%t : %s: HTRANS changed during a wait state.", $time, NAME);
  end
  if (hwrite_p !== hwrite)
    $display ("ERROR: t=%t : %s: HWRITE changed during a wait state.", $time, NAME);
  if (hsize_p  !== hsize)
    $display ("ERROR: t=%t : %s: HSIZE  changed during a wait state.", $time, NAME);
  if (hburst_p !== hburst)
    $display ("ERROR: t=%t : %s: HBURST changed during a wait state.", $time, NAME);
  if (hprot_p  !== hprot)
    $display ("ERROR: t=%t : %s: HPROT  changed during a wait state.", $time, NAME);
  // data signal changes during a write cycle
  if ( (hwdata_p !== hwdata) & hwrite_r )
    $display ("ERROR: t=%t : %s: HWDATA changed during a wait state.", $time, NAME);
end

// burst length and address check
always @(posedge hclk)
if (hready_p & hresetn_p & hsel_r) begin
  if (hburst_p != `H_SINGLE) begin
    if (burst_cnt <  burst_len-1) begin
      if (hburst != hburst_p)
        $display ("ERROR: t=%t : %s: HBURST changed during a burst sequence.", $time, NAME);
    end
    if (burst_cnt <  burst_len-1) begin
      if (~((htrans == `H_SEQ) | (htrans == `H_BUSY)))
        $display ("ERROR: t=%t : %s: HBURST early burst termination.", $time, NAME);
    end
    if (burst_cnt == burst_len-1) begin
      if (~((htrans == `H_NONSEQ) | (htrans == `H_IDLE)))
        $display ("ERROR: t=%t : %s: HBURST missed burst termination.", $time, NAME);
    end
    if (htrans == `H_SEQ) begin
      if (haddr_r[AW-1:10] != haddr[AW-1:10])
        $display ("ERROR: t=%t : %s: HADDR burst crossed the 1kB boundary.", $time, NAME);
    end
  end
end

// registered first address of a burst
always @(negedge hresetn, posedge hclk)
if (~hresetn)
  burst_cnt <= 0;
else if (hready) begin
  if (htrans == `H_NONSEQ) begin
    haddr_b   <= haddr;
    burst_cnt <= 0;
  end else if (hburst_r != `H_SINGLE)
    burst_cnt <= burst_cnt+1;
end

// for an incrementing burst of undefined length the burst length is limited to 1KB
assign trans_siz = 1 << hsize;
assign burst_typ = hburst_r[0];
assign burst_len = (hburst_r == `H_SINGLE) ? 1 : (hburst_r == `H_INCR) ? 1 << (10-hsize) : 1 << (hburst_r[2:1]+1);
assign burst_msk = (1 << (hsize_r+hburst_r[2:1]+1)) - 1;
assign burst_adr = (burst_typ) ?                            haddr_b + burst_cnt * trans_siz
                               : (haddr_b & ~burst_msk) + ((haddr_b + burst_cnt * trans_siz) & burst_msk);

endmodule

