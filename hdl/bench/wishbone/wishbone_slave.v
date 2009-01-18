//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  WISHBONE bus interface testbench                                        //
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
  parameter SW = `WB_DW/8,       // byte select bus width
  parameter DE = `WB_DE,         // data endianness ('BIG' or 'LITTLE')
  parameter IV = 1'bx,           // idle value (value of signals when bus is idle)
  // memory parameters
//  parameter integer MS = 1024,  // memory size (in Bytes)
//  parameter [AW-1:0] AM = 1023,  // address mask
  parameter MS = 1024,  // memory size (in Bytes)
  parameter AM = 1023,  // address mask
  // write and read latencies for sequential and nonsequential accesses
  parameter CW  = 8,    // time counter width
//  parameter [CW-1:0] lw  = 0,    // write latency for first transfer
//  parameter [CW-1:0] lr  = 0,    // read  latency for first transfer
//  parameter [CW-1:0] lwb = 0,    // write latency for burst transfers
//  parameter [CW-1:0] lrb = 0     // read  latency for burst transfers
  parameter  lw  = 0,    // write latency for first transfer
  parameter  lr  = 0,    // read  latency for first transfer
  parameter  lwb = 0,    // write latency for burst transfers
  parameter  lrb = 0     // read  latency for burst transfers
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
wor           error_req;

assign error_req = 1'b0;
assign error_req = error;          // default error value

// cycle and burst length couners
integer cnt_t;    // time counter

// slave memory
reg     [7:0] mem [0:MS-1];

// transfer response
wire          trn;      // transfer completion indicator
wire          rdy;      // ready for new cycle

// byte select
genvar        i;

//////////////////////////////////////////////////////////////////////////////
// slave response timing                                                    //
//////////////////////////////////////////////////////////////////////////////

assign trn = cyc & stb & (ack | err | rty);
assign rdy = ~cyc | trn & ((cti == 3'b000) | (cti == 3'b111));


// cycle and burst length couners
// generating the acknowledge signal with the proper timing
always @(posedge rst, posedge clk)
if (rst)        cnt_t <= 0;
else begin
  if (cyc & stb) begin
    if (trn) begin
      if (rdy)  cnt_t <= (we) ? lw  : lr;
      else      cnt_t <= (we) ? lwb : lrb;
    end else
                cnt_t <= cnt_t - 1;
  end
end

// acknowledge response
assign ack = (cyc) ? (cnt_t == 0) : IV;
// error response
assign err = (cyc) ? 1'b0         : IV;  // TODO
// retry response
assign rty = (cyc) ? 1'b0         : IV;  // TODO

//////////////////////////////////////////////////////////////////////////////
// memory and data bus implementation                                       //
//////////////////////////////////////////////////////////////////////////////

generate
for (i=0; i<SW; i=i+1) begin : data_paths
  if (DE == "LITTLE") begin
    // write to memory
    always @(posedge clk)
      if (trn & we & sel[i])  mem [adr+i] <= dat_i [8*i+:8];
    // read from memory
    assign dat_o [8*i+:8] = (trn & ~we & sel[i]) ? mem [adr*SW+i] : {8{IV}};
  end
  if (DE == "BIG") begin
    // write to memory
    always @(posedge clk)
      if (trn & we & sel[i])  mem [adr+SW-1-i] <= dat_i [8*i+:8];
    // read from memory
    assign dat_o [8*i+:8] = (trn & ~we & sel[i]) ? mem [adr+SW-1-i] : {8{IV}};
  end
end
endgenerate


endmodule

