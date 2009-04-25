//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  Minimalistic SPI (3 wire) interface with Zbus interface                 //
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

module spi_tb ();

//////////////////////////////////////////////////////////////////////////////
// local parameters and signals                                             //
//////////////////////////////////////////////////////////////////////////////

localparam DW = 32;
localparam AW = 32;
localparam SW = DW/8;
localparam SSW = 8;

localparam ZOW = DW+AW+SW+1;
localparam ZIW = DW;

// system signals
reg clk, rst;

// zbus input interface
wire           zms_req;     // transfer request
wire [ZOW-1:0] zms_bus;     // transfer payload
wire           zms_ack;     // transfer acknowledge
// translated zbus input interface bus
wire  [DW-1:0] zms_dat;     // data
wire  [AW-1:0] zms_adr;     // address
wire  [SW-1:0] zms_sel;     // byte select
wire           zms_wen;     // write enable (0-read or 1-wite)
// zbus output interface
wire           zsm_req;     // transfer request
wire [ZIW-1:0] zsm_bus;     // data
wire           zsm_ack;     // transfer acknowledge

// SPI signals
wire [SSW-1:0] ss_n;
wire           sclk;
wire           miso;
wire           mosi;
// SPI mosi tristate buffer signals
wire           mosi_i;
wire           mosi_o;
wire           mosi_e;

//////////////////////////////////////////////////////////////////////////////
// testbench                                                                //
//////////////////////////////////////////////////////////////////////////////

always
  #4 clk <= ~clk;

initial begin
  clk = 1'b1;
  rst = 1'b1;
  repeat (8) @ (posedge clk);
  #1;
  rst = 1'b0;
  // start a zbus cycle

end

// request for a dumpfile
initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, spi_tb);
  #100000;
  $finish;
end

//////////////////////////////////////////////////////////////////////////////
// zbus master instance                                                     //
//////////////////////////////////////////////////////////////////////////////

zbus #(
  .ZOW     (DW+AW+SW+1),
  .ZIW     (DW)
) zbus (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // output interface
  .zo_req  (zms_req),  // transfer request
  .zo_bus  (zms_bus),  // payload
  .zo_ack  (zms_ack),  // transfer acknowledge (bus ready)
  // input interface
  .zi_req  (zsm_req),  // transfer request
  .zi_bus  (zsm_bus),  // payload
  .zi_ack  (zsm_ack)   // transfer acknowledge (bus ready)
);

assign zms_dat = zms_bus [31: 0];
assign zms_adr = zms_bus [63:32];
assign zms_sel = zms_bus [67:64];
assign zms_wen = zms_bus [   68];

//////////////////////////////////////////////////////////////////////////////
// spi controller instance                                                  //
//////////////////////////////////////////////////////////////////////////////

spi_zbus #(
  // system bus parameters
  .DW   (32),        // data bus width
  .SW   (DW/8),      // select signal width or bus width in bytes
  .AW   (32),        // address bus width
  // SPI slave select paramaters
  .SSW  (8),         // slave select register width
  // SPI interface configuration parameters
  .CFG_dir    ( 1),  // shift direction (0 - LSB first, 1 - MSB first)
  .CFG_cpol   ( 0),  // clock polarity
  .CFG_cpha   ( 0),  // clock phase
  .CFG_3wr    ( 0),  // duplex type (0 - SPI full duplex, 1 - 3WIRE half duplex (MOSI is shared))
  // SPI shift register parameters
  .PAR_sh_rw  (32),  // shift register width (default width is eqal to wishbone bus width)
  .PAR_sh_cw  ( 5),  // shift counter width (logarithm of shift register width)
  // SPI transfer type parameters
  .PAR_tu_rw  ( 8),  // shift transfer unit register width (default granularity is byte)
  .PAR_tu_cw  ( 3),  // shift transfer unit counter width (counts the bits of a transfer unit)
  // SPI clock divider parameters
  .PAR_cd_en  ( 1),  // clock divider enable (0 - use full system clock, 1 - use divider)
  .PAR_cd_ri  ( 1),  // clock divider register inplement (otherwise the default clock division factor is used)
  .PAR_cd_rw  ( 8),  // clock divider register width
  .PAR_cd_ft  ( 1)   // default clock division factor
) spi_zbus (
  // system signals (used by the CPU bus interface)
  .clk       (clk),
  .rst       (rst),
  // zbus input interface
  .zi_req    (zms_req),     // transfer request
  .zi_wen    (zms_wen),     // write enable (0-read or 1-wite)
  .zi_adr    (zms_adr),     // address
  .zi_sel    (zms_sel),     // byte select
  .zi_dat    (zms_dat),     // data
  .zi_ack    (zms_ack),     // transfer acknowledge
  // zbus output interface
  .zo_req    (zsm_req),     // transfer request
  .zo_dat    (zsm_bus),     // data
  .zo_ack    (zsm_ack),     // transfer acknowledge
  // additional processor interface signals
  .irq       (),
  // SPI signals
  .spi_ss_n   (ss_n),   // active low slave select signal
  .spi_sclk   (sclk),   // serial clock
  .spi_miso   (miso),   // serial master input slave output
  .spi_mosi_i (mosi_i), // serial master output slave input or threewire bidirectional (input)
  .spi_mosi_o (mosi_o), // serial master output slave input or threewire bidirectional (output)
  .spi_mosi_e (mosi_e)  // serial master output slave input or threewire bidirectional (output enable)
);

//////////////////////////////////////////////////////////////////////////////
// spi tristate buffers                                                     //
//////////////////////////////////////////////////////////////////////////////

assign mosi_i = mosi;
assign mosi   = mosi_e ? mosi_o : 1'bz;



endmodule
