//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AMBA AHB bus slave model (simple memory model)                          //
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

module amba_ahb_slave #(
  // bus paramaters
  parameter integer aw = `AW,    // address bus width
  parameter integer dw = `DW,    // data bus width
  parameter integer de = `DE,    // endianess
  parameter integer rw = `RW,    // response width
  // memory parameters
  parameter integer  ms = 1024,  // memory size (in Bytes)
  parameter [aw-1:0] am = 1023,  // address mask
  // write and read latencies for sequential and nonsequential accesses
  parameter cw = 8;              // time counter width
  parameter [cw-1:0] lw_ns = 0,  // write latency for nonsequential transfers
  parameter [cw-1:0] lw_s  = 0,  // write latency for sequential transfers
  parameter [cw-1:0] lr_ns = 0,  // read latency for nonsequential transfers
  parameter [cw-1:0] lr_s  = 0   // read latency for sequential transfers
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
  output wire [dw-1:0] hrdata,   // Read data bus
  output reg           hready,   // Transfer done
  output reg  [rw-1:0] hresp,    // Transfer response
  // slave control signal
  input  wor           error     // request an error response
);

localparam sw = dw/8;  // byte select width (data bus width in Bytes)

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

// slave control signal
wor           error_req;

assign error_req = 1'b0;
assign error_req = error;          // default error value

// cycle and burst length couners
wire [cw-1:0] delay;    // expected delay for observed cycle
wire [cw-1:0] cnt_t;    // time counter reload input
reg  [cw-1:0] cnt_t_r;  // time counter register

// registered AHB input signals
reg           hsel_r;
reg  [aw-1:0] haddr_r;
reg     [1:0] htrans_r;
reg           hwrite_r;
reg     [2:0] hsize_r;
reg     [2:0] hburst_r;
reg     [2:0] hprot_r;

// slave memory
reg     [7:0] mem [0:ms-1];

genvar i;

wire    [7:0] bytes;
wire [dw-1:0] wdata;    // write data buse used for endian byte swap
wire [dw-1:0] rdata;    // read data buse used for endian byte swap
wire          trn;      // read or write transfer
wire          trn_reg;  // transfer request
wire          trn_ack;  // transfer acknowledge

//////////////////////////////////////////////////////////////////////////////
// pipelining input signals                                                 //
//////////////////////////////////////////////////////////////////////////////

always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  htrans_r <= #1 `H_IDLE;
end else if (hready) begin
  hsel_r   <= #1 hsel;
  haddr_r  <= #1 haddr;
  htrans_r <= #1 htrans;
  hwrite_r <= #1 hwrite;
  hsize_r  <= #1 hsize;
  hburst_r <= #1 hburst;
  hprot_r  <= #1 hprot;
end

//////////////////////////////////////////////////////////////////////////////
// slave response timing                                                    //
//////////////////////////////////////////////////////////////////////////////

// cycle and burst length couners
// generating the response signals with the proper timing
always @(negedge hresetn, posedge hclk)
if (~hresetn) begin
  cnt_t_r <= #1 0;
  hready  <= #1 1'b1;
  hresp   <= #1 `H_OKAY;
end else begin
  // apply a new value to the counter register
  cnt_t_r <= #1 cnt_t;
  // error response: wait periods + two ERROR periods
  if (error) begin
    if (hready) begin
      if ((htrans == `H_IDLE) | (htrans == `H_BUSY)) begin
        hresp   <= #1 `H_OKAY;
        hready  <= #1 1'b1;
      end
      if ((htrans == `H_NONSEQ) | (htrans == `H_SEQ)) begin
        hresp   <= #1 (cnt_t == 0) ? `H_ERROR : `H_OKAY;
        hready  <= #1 1'b0;
      end
    end else begin
      if ((htrans_r == `H_NONSEQ) | (htrans_r == `H_SEQ)) begin
        if (hresp == `H_OKAY) begin
          hresp   <= #1 (cnt_t == 0) ? `H_ERROR : `H_OKAY;
        end else begin
          hready  <= #1 1'b1;
        end
      end
    end
  // okay response: wait periods + one OKAY period
  end else begin
    hresp   <= #1 `H_OKAY;
    hready  <= #1 (cnt_t == 0);
  end
end

assign delay = htrans[0] ? (hwrite ? lw_s  : lr_s )
                         : (hwrite ? lw_ns : lr_ns);

assign cnt_t = hready ? (htrans[1] & hsel ? delay
                                          : 0)
                      : cnt_t_r - 1;

//////////////////////////////////////////////////////////////////////////////
// memory and data bus implementation                                       //
//////////////////////////////////////////////////////////////////////////////

assign trn_req = ((htrans_r == `H_NONSEQ) | (htrans_r == `H_SEQ)) & hsel_r;
assign trn_ack = hready;
assign trn     = trn_req & trn_ack;

assign bytes = 1 << hsize_r;

// endian byte swap
generate
  for (i=0; i<sw; i=i+1) begin
    if (de == "BIG") begin
      assign  wdata [dw-1-8*i-:8] = hwdata [8*i+:8];
      assign hrdata [dw-1-8*i-:8] =  rdata [8*i+:8];
    end else if (de == "LITTLE") begin
      assign  wdata [     8*i+:8] = hwdata [8*i+:8];
      assign hrdata [     8*i-:8] =  rdata [8*i+:8];
    end
  end
endgenerate

// write to memory
generate
  for (i=0; i<sw; i=i+1) begin
    always @(posedge hclk) begin
      if (trn & (hresp == `H_OKAY) & hwrite_r) begin
        if (((haddr_r&am)%sw <= i) & (i < ((haddr_r&am)%sw + bytes)))  mem [(haddr_r&am)/sw*sw+i] <= #1 wdata [8*i+:8];
      end
    end
  end
endgenerate

// read from memory
generate
  for (i=0; i<sw; i=i+1) begin
    assign rdata [8*i+:8] = ((trn & (hresp == `H_OKAY) & ~hwrite_r) & ((haddr_r&am)%sw <= i) & (i < ((haddr_r&am)%sw + bytes))) ? mem [(haddr_r&am)/sw*sw+i] : 8'hxx;
  end
endgenerate


endmodule

