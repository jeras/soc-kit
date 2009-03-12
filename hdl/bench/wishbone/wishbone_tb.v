//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  WISHBONE bus interface testbench                                        //
//                                                                          //
//  Copyright (C) 2008/2009  Iztok Jeras                                    //
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

`include "wishbone_defines.v"

module wishbone_tb ();

// wishbone bus paremeters
localparam DW = `WB_DW;    // data width
localparam AW = `WB_AW;    // address width
localparam SW =     DW/8;  // byte select width

// master program input and data output files
//localparam M1_P = "hdl/bench/wishbone/wishbone_program.txt";
localparam M1_P = "fifo_program";
localparam M1_D = "hdl/bench/wishbone/wishbone_data.txt";

// system signals
reg clk, rst;

// wishbone signals
wire          m1_cyc   ;  // cycle
wire          m1_stb   ;  // strobe
wire          m1_we    ;  // write enable
wire [AW-1:0] m1_adr   ;  // address
wire [SW-1:0] m1_sel   ;  // byte select
wire    [2:0] m1_cti   ;
wire    [1:0] m1_bte   ;
wire [DW-1:0] m1_dat_o ;  // data output
wire [DW-1:0] m1_dat_i ;  // data input
wire          m1_ack   ;  // acknowledge
wire          m1_err   ;  // error
wire          m1_rty   ;  // retry

//////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////

// initial reset pulse
initial begin
  clk = 1;
  rst = 1;
  rst = #11 0;
end

// clock period
always
  clk = #5 ~clk;

// request for a dumpfile
initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, wishbone_tb);
end

//////////////////////////////////////////////////////////////////////////////
// module instances 
//////////////////////////////////////////////////////////////////////////////

wishbone_master #(
  .FILE_I (M1_P),
  .FILE_O (M1_D),
  .NAME   ("WB master"),
  .AUTO   (1)
) m1 (
  .clk    (clk     ),
  .rst    (rst     ),
  .cyc    (m1_cyc  ),
  .stb    (m1_stb  ),
  .we     (m1_we   ),
  .adr    (m1_adr  ),
  .sel    (m1_sel  ),
  .cti    (m1_cti  ),
  .bte    (m1_bte  ),
  .dat_o  (m1_dat_o),
  .dat_i  (m1_dat_i),
  .ack    (m1_ack  ),
  .err    (m1_err  ),
  .rty    (m1_rty  )
);

wishbone_slave #(
  // access latencies
  .lw        (2),
  .lr        (3),
  .lwb       (0),
  .lrb       (0)
) s1 (
  .clk    (clk     ),
  .rst    (rst     ),
  .cyc    (m1_cyc  ),
  .stb    (m1_stb  ),
  .we     (m1_we   ),
  .adr    (m1_adr  ),
  .sel    (m1_sel  ),
  .bte    (m1_bte  ),
  .cti    (m1_cti  ),
  .dat_i  (m1_dat_o),
  .dat_o  (m1_dat_i),
  .ack    (m1_ack  ),
  .err    (m1_err  ),
  .rty    (m1_rty  )
);


endmodule
