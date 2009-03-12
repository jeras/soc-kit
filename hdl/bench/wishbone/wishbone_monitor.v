//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  WISHBONE bus interface slave model                                      //
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

`include "wishbone_defines.v"

module wishbone_slave #(
  // bus parameters
  parameter AW = `WB_AW,         // address bus width
  parameter DW = `WB_DW,         // data bus width
  parameter SW =     DW/8,       // byte select bus width
  parameter DE = `WB_DE,         // data endianness ("be"-big or "le"-little)
  parameter IV = 1'bx,           // idle value (value of signals when bus is idle)
  // memory parameters
//  parameter integer MS = 1024,  // memory size (in Bytes)
//  parameter [AW-1:0] AM = 1023,  // address mask
  parameter MS = 1024,  // memory size (in Bytes)
  parameter AM = 1023,  // address mask
  // write and read latencies for sequential and nonsequential accesses
  parameter lw  = 0,    // write latency for first transfer
  parameter lr  = 0,    // read  latency for first transfer
  parameter lwb = 0,    // write latency for burst transfers
  parameter lrb = 0     // read  latency for burst transfers
)(
  // Wishbone system signals
  input  wire          clk,      // system clock
  input  wire          rst,      // system reset
  // Wishbone inputs from master 
  input  wire          cyc,      // cycle
  input  wire          stb,      // data strobe
  input  wire          we,       // write enable
  input  wire [AW-1:0] adr,      // address
  input  wire [SW-1:0] sel,      // byte select
  // Wishbone burst control inputs
  input  wire    [2:0] cti,      // cycle type identifier
  input  wire    [1:0] bte,      // burst type extension
  // Wishbone data inputs and outputs
  input  wire [DW-1:0] dat_i,    // data input
  output wire [DW-1:0] dat_o,    // data output
  // Wishbone slave response outputs
  output wire          ack,      // acknowledge
  output wire          err,      // error
  output wire          rty,      // retry
  // error and retry options
  input  wire          error,
  input  wire          retry
);

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

// slave control signal
wor    error_req;

assign error_req = 1'b0;
assign error_req = error;          // default error value

// slave memory
reg  [7:0] mem [0:MS-1];

// transfer response
wire       trn;      // transfer completion indicator
wire       rdy;      // ready for new cycle
wire       stop;     // time for cycle acknowledge
reg        first;    // indicator of first transfer in burst cycle
integer    cnt;      // cycle length counter

// byte select
genvar        i;

//////////////////////////////////////////////////////////////////////////////
// slave response timing                                                    //
//////////////////////////////////////////////////////////////////////////////

assign trn = cyc & stb & (ack | err | rty);
assign rdy = ~cyc | trn & ((cti == 3'b000) | (cti == 3'b111));

// signaling the first cycle in a burst
always @(posedge rst, posedge clk)
if (rst)         first <= 1;
else begin
  if (rdy)       first <= 1;
  else if (trn)  first <= 0;
end

// cycle length counter
always @(posedge rst, posedge clk)
if (rst)      cnt <= 0;
else begin
  if (rdy)    cnt <= 0;
  else if (cyc & stb) begin
    if (trn)  cnt <= 0;
    else      cnt <= cnt + 1;
  end
end


endmodule

