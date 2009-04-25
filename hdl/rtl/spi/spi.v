//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  Minimalistic SPI (3 wire) interface with WISHBONE bus interface         //
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


/*\
 *  spi shift register and logic implementation
\*/

module spi #(
  // shift register and shift counter parameters
  parameter DW  = 32,  // data wddth (shift register width)
  parameter DWL =  5,  // data width logarithm (shift counter width)
  parameter UW  =  8,  // shift unit data width
  parameter UW  =  3,  // shift unit data width logarithm
  // slave select signal parameter
  parameter SSW =  8   // slave select register width
  // SPI clock divider parameters
  parameter PAR_cd_en =  1;  // clock divider enable (0 - use full system clock, 1 - use divider)
  parameter PAR_cd_rw =  8;  // clock divider register width
)(
  // system signals (used by the wishbone interface)
  input  wire           clk,
  input  wire           rst,
  // SPI interface configuration signals
  input  wire           dir,   // shift direction (0 - LSB first, 1 - MSB first)
  input  wire           cpol,  // clock polarity
  input  wire           cpha,  // clock phase
  input  wire           dpx,   // duplex type (0 - SPI full duplex, 1 - 3WIRE half duplex (MOSI is shared))
  // 
  // SPI signals
  output wire [SSW-1:0] ss_n,   // active low slave select signal
  output wire           sclk,   // serial clock
  input  wire           miso,   // serial master input slave output
  inout  wire           mosi    // serial master output slave input (or threewire bidirectional)
);

/*\
 *  local signals
\*/

// clock divider signals
reg  [PAR_cd_rw-1:0] cnt_clk;  // clock divider counter
reg  reg_clk;                  // register storing the SCLK clock value (additional division by two)
wire sclk_posedge, sclk_negedge;

// spi shifter signals
reg  [PAR_sh_rw-1:0] reg_s;    // spi data shift register
reg  reg_i, reg_o;             // spi input-sampling to output-change phase shift registers
wire ser_i, ser_o;             // shifter serial input and output multiplexed signals

// spi shift transfer control registers
reg  [PAR_sh_cw-1:0] cnt_bit;  // counter of shifted bits
wire                 run;      // transfer running status

/*\
 *  clock divider 
\*/

// clock counter
always @(posedge clk, posedge rst)
if (rst)            cnt_clk <= #1 0;
else if (ctl_run) begin
  if (cnt_clk == 0) cnt_clk <= #1 reg_div;
  else              cnt_clk <= #1 cnt_clk - 1;
end

// clock output register (divider by 2)
always @(posedge clk)
if (~ctl_run)          reg_clk <= #1 cfg_cpol;
else if (cnt_clk == 0) reg_clk <= #1 ~reg_clk;

// spi clock positive and negative edge
// used to synchronise input, output and shift registers
assign sclk_posedge = (cnt_clk == 0) & ~reg_clk;
assign sclk_negedge = (cnt_clk == 0) &  reg_clk;

// spi clock output pin
assign sclk = reg_clk;

/*\
 *  spi slave select
\*/

// slave select active low output pins
assign ss_n = ~ss;

/*\
 *  control registers (transfer counter and serial output enable)
\*/

// bit counter
always @(posedge clk, posedge rst)
if (rst)                cnt_bit <= #1 0;
else begin
  if
  else if (ctl_cnt != 0)  cnt_bit <= #1 cnt_bit + 1;
end

// spi transfer run status
assign ctl_run = (ctl_cnt != 0);

/*\
 *  spi shift register
\*/

// shift register implementation
always @(posedge clk)
if (ssr_we) ssr <= #1 ssr_dat;
end else if (ctl_run) begin
  if (dir)  ssr <= #1 {ssr [DW-2:0], ser_i};
  else      ssr <= #1 {ser_i, ssr [DW-1:1]};
end

/*\
 *  serial interface
\*/

// output register
always @(posedge clk)
if ( (~cpol & sclk_negedge)
   | ( cpol & sclk_posedge) )  reg_o <= #1 ser_o;

// input register
always @(posedge clk)
if ( (~cpol & sclk_negedge)
   | ( cpol & sclk_posedge) )  reg_i <= #1 ser_i;

// the serial output from the shift register depends on the direction of shifting
assign ser_o   = (dir) ? reg_s [shift_rw-1] : reg_s [0];
assign ser_i   = (~cpha) ? reg_i : ((~dplx) ? miso : mosi);
assign mosi    = (~cpha) ? ser_o : reg_o;


endmodule
