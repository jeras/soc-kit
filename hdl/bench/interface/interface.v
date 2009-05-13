//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  general purpuse verilog <-> software interface                          //
//                                                                          //
//  Copyright (C) 2009  Iztok Jeras                                         //
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

`timescale  1ns / 1ps

module interface #(
  // bus parameters
  parameter NO  = 8,       // number of output signals
  parameter NI  = 8,       // number of input  signals
  // software interface parameters
  parameter FNO = "",      // file name for output signals (read  file)
  parameter FNI = "",      // file name for input  signals (write file)
  parameter DT  = "hex",   // data type ("hex" (default), "bin", "raw")
  // presentation
  parameter NAME = "noname"
)(
  input  wire          clk,  // clock
  input  wire          rst,  // clock
  output reg  [NO-1:0] d_o,  // output signals
  input  wire [NI-1:0] d_i   // input  signals
);

///////////////////////////////////////////////////////////////////////////////
// initialization                                                            //
///////////////////////////////////////////////////////////////////////////////

initial begin
  $interface_init();
  $interface_o;
  $interface_i;
  #7;
  d_o = 8'h55;
  #7;
  d_o = d_i;
// if (AUTO)  start (FNO, FNI);
end

always @ (posedge rst, posedge clk)
if (rst)  $interface_rst;
else      $interface_clk;


endmodule

