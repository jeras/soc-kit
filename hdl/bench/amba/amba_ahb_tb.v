//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AMBA AHB testbench                                                      //
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

`timescale  1ns / 1ps
`include "amba_ahb_defines.v"

module amba_ahb_tb ();

// wishbone paramaters
parameter AW = `AW;     // address bus width
parameter DW = `DW;     // data bus width
parameter DE = `DE;     // endianness
parameter RW = `RW;     // response width

parameter MN = 1;       // number of bus masters
parameter SN = 3;       // number of bus slaves

// AMBA AHB system signals
reg           hclk;     // Bus clock
reg           hresetn;  // Reset (active low)

/*
      //MASTER No 1
wire [aw-1:0] haddr0;    // Address bus
wire    [1:0] htrans0;   // Transfer type
wire          hwrite0;   // Transfer direction
wire    [2:0] hsize0;    // Transfer size
wire    [2:0] hburst0;   // Burst type
wire    [3:0] hprot0;    // Protection control
wire [dw-1:0] hwdata0;   // Write data bus
wire [dw-1:0] hrdata0;
wire          hresp0;    // 
   //MASTER No 2
wire [aw-1:0] haddr1;    // Address bus
wire    [1:0] htrans1;   // Transfer type
wire          hwrite1;   // Transfer direction
wire    [2:0] hsize1;    // Transfer size
wire    [2:0] hburst1;   // Burst type
wire    [3:0] hprot1;    // Protection control
wire [dw-1:0] hwdata1;   // Write data bus
wire [dw-1:0] hrdata1;
wire          hresp1;    // 
*/

// AMBA AHB master/arbiter to decoder/slave
wire [AW-1:0] haddr;    // Address bus
wire    [1:0] htrans;   // Transfer type
wire          hwrite;   // Transfer direction
wire    [2:0] hsize;    // Transfer size
wire    [2:0] hburst;   // Burst type
wire    [3:0] hprot;    // Protection control
wire [DW-1:0] hwdata;   // Write data bus
// AMBA AHB slave signals
wire [DW-1:0] hrdata;   // Read data bus
wire          hready;   // Transfer done
wire [RW-1:0] hresp;    // Transfer response

/*
// AMBA AHB decoder signals
wire [dw-1:0] hrdata_s [0:sn-1];   // Read data bus
wire          hready_s [0:sn-1];   // Transfer done
wire [rw-1:0] hresp_s  [0:sn-1];    // Transfer response
wire [sn-1:0] hsel;     // Slave select
// AMBA AHB arbiter signals
// slave data check
wire          error;    //
*/

// temporary signals for bursts
// the max burst length is 1kB
reg [1024*8-1:0] data_t, data_x;

wire          master_status;

///////////////////////////////////////////////////////////////////////////////
// system clock, reset and .vcd dumpfile                                     //
///////////////////////////////////////////////////////////////////////////////

//assign master_status = ahb_master_0.empty
//                     & ahb_master_1.empty;
//assign master_status = ahb_master.empty;

initial begin
//  wait (master_status) #1 ahb_program_arbiter_test;
//  wait (master_status) #1 ahb_program_master_slave_test;
//  wait (master_status) #1 ahb_program_master_error_test;
  #1 wait (master_status) #100 $finish;
end


// initial reset pulse
initial begin
  hclk    = 1;
  hresetn = 0;
  hresetn = #11 1;
end

// clock period
always
  hclk = #5 ~hclk;

// request for a dumpfile
initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, amba_ahb_tb);
end

///////////////////////////////////////////////////////////////////////////////
// bus masters                                                               //
///////////////////////////////////////////////////////////////////////////////

/*
amba_ahb_master #(
  .aw        (aw),
  .dw        (dw),
  .de        (de),
  .name      ("master 0")
) ahb_master_0 (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB master signals
  .haddr     (haddr0),
  .htrans    (htrans0),
  .hwrite    (hwrite0),
  .hsize     (hsize0),
  .hburst    (hburst0),
  .hprot     (hprot0),
  .hwdata    (hwdata0),
  // AMBA AHB slave signals
  .hrdata    (hrdata0),
  .hready    (hready0),
  .hresp     (hresp0),
  // error (unexpected received cycle values or cycle timeout)
  .error     (error)
);

amba_ahb_master #(
  .aw        (aw),
  .dw        (dw),
  .de        (de),
  .name      ("master 1")
) ahb_master_1 (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB master signals
  .haddr     (haddr1),
  .htrans    (htrans1),
  .hwrite    (hwrite1),
  .hsize     (hsize1),
  .hburst    (hburst1),
  .hprot     (hprot1),
  .hwdata    (hwdata1),
  // AMBA AHB slave signals
  .hrdata    (hrdata1),
  .hready    (hready1),
  .hresp     (hresp1),
  // error (unexpected received cycle values or cycle timeout)
  .error     (error)
);
*/

amba_ahb_master #(
  .AW        (AW),
  .DW        (DW),
  .DE        (DE),
  .NAME      ("master")
) ahb_master (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata),
  .hready    (hready),
  .hresp     (hresp),
  // error (unexpected received cycle values or cycle timeout)
  .error     (error)
);

///////////////////////////////////////////////////////////////////////////////
// arbiter                                                                   //
///////////////////////////////////////////////////////////////////////////////

/*
amba_ahb_arbiter arbiter(
			 hclk, 
			 hresetn,
			 //master0
			 {haddr1,  haddr0}, 
			 {htrans1, htrans0},
			 {hwrite1, hwrite0},
			 {hsize1,  hsize0}, 
			 {hburst1, hburst0},
			 {hprot1,  hprot0}, 
			 {hwdata1, hwdata0},
			 {hrdata1, hrdata0},
			 {hready1, hready0},
			 {hresp1,  hresp0}, 
			 
			 //slave
			 haddr,  
			 htrans,
			 hwrite,
			 hsize,
			 hburst,
			 hprot,
			 hwdata,
			 hrdata,			 
			 hready,
			 hresp
);
*/

///////////////////////////////////////////////////////////////////////////////
// bus decoder and dummy slave                                               //
///////////////////////////////////////////////////////////////////////////////

/*
amba_ahb_decoder #(
  // bus width and endianness parameters
  .aw        (aw),
  .dw        (dw),
  // number of bus slaves
  .sn        (sn),
  // address decoder (slave sn-1,...,1,0)
  .sa        ({32'h00000400, 32'h00000200, 32'h00000000}),
  .sm        ({32'hf0000400, 32'hf0000600, 32'hf0000600})
) ahb_decoder (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  // AMBA AHB slave signals
  .hrdata    (hrdata),
  .hready    (hready),
  .hresp     (hresp),
  // AMBA AHB decoder input signals (slave sn-1,...,1,0)
  .hrdata_s  ({hrdata_s[2], hrdata_s[1], hrdata_s[0]}),
  .hready_s  ({hready_s[2], hready_s[1], hready_s[0]}),
  .hresp_s   ({hresp_s [2], hresp_s [1], hresp_s [0]}),
  // AMBA AHB decoder output signals (slave sn-1,...,1,0)
  .hsel      (hsel)
);
*/

///////////////////////////////////////////////////////////////////////////////
// bus slaves                                                                //
///////////////////////////////////////////////////////////////////////////////

amba_ahb_slave #(
  // bus width and endianness parameters
  .AW        (AW),
  .DW        (DW),
  .DE        (DE),
  // access latencies
  .LW_NS     (2),
  .LW_S      (0),
  .LR_NS     (1),
  .LR_S      (0)
) ahb_slave (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB decoder signals
  .hsel      (1'b1),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata),
  .hready    (hready),
  .hresp     (hresp),
  // control signals
  .error     (1'b0)
);

/*
amba_ahb_slave #(
  // bus width and endianness parameters
  .aw        (aw),
  .dw        (dw),
  .de        (de),
  // access latencies
  .lw_ns     (2),
  .lw_s      (0),
  .lr_ns     (1),
  .lr_s      (0)
) ahb_slave_0 (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB decoder signals
  .hsel      (hsel[0]),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata_s[0]),
  .hready    (hready_s[0]),
  .hresp     (hresp_s[0]),
  // control signals
  .error     (1'b0)
);

amba_ahb_slave #(
  // bus width and endianness parameters
  .aw        (aw),
  .dw        (dw),
  .de        (de),
  // access latencies
  .lw_ns     (2),
  .lw_s      (0),
  .lr_ns     (1),
  .lr_s      (0)
) ahb_slave_1 (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB decoder signals
  .hsel      (hsel[1]),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata_s[1]),
  .hready    (hready_s[1]),
  .hresp     (hresp_s[1]),
  // control signals
  .error     (1'b1)
);

amba_ahb_slave #(
  // bus width and endianness parameters
  .aw        (aw),
  .dw        (dw),
  .de        (de),
  // access latencies
  .lw_ns     (2),
  .lw_s      (0),
  .lr_ns     (1),
  .lr_s      (0)
) ahb_slave_2 (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB decoder signals
  .hsel      (hsel[2]),
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata_s[2]),
  .hready    (hready_s[2]),
  .hresp     (hresp_s[2]),
  // control signals
  .error     (1'b0)
);
*/

///////////////////////////////////////////////////////////////////////////////
// bus monitor                                                               //
///////////////////////////////////////////////////////////////////////////////

amba_ahb_monitor #(
  // bus width and endianness parameters
  .AW        (AW),
  .DW        (DW),
  .DE        (DE)
) ahb_monitor (
  // AMBA AHB system signals
  .hclk      (hclk),
  .hresetn   (hresetn),
  // AMBA AHB decoder signal
  .hsel      (1'b1),          // all cycles are checked
  // AMBA AHB master signals
  .haddr     (haddr),
  .htrans    (htrans),
  .hwrite    (hwrite),
  .hsize     (hsize),
  .hburst    (hburst),
  .hprot     (hprot),
  .hwdata    (hwdata),
  // AMBA AHB slave signals
  .hrdata    (hrdata),
  .hready    (hready),
  .hresp     (hresp)
);


endmodule

