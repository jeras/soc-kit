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

// wishbone bus parameter definitions
`define WB_32BIT
`define WB_DW   32  // data bus width
`define WB_AW   32  // address bus width
`define WB_SW    4  // select signal width

// register positioning
`define WB_AI 4     // how register addresses are incremented

// SPI bus parameter definitions
`define SPI_SSW  8  // number of slave select signals

/*\
 *  spi shift register and logic implementation
\*/

module spi_controller (
  // system signals (used by the wishbone interface)
  input  wire                 clk,
  input  wire                 rst,
  // wishbone signals
  input  wire                 wb_cyc,     // cycle
  input  wire                 wb_stb,     // strobe
  input  wire                 wb_we,      // write enable
  input  wire  [`WB_AW-1:0]   wb_adr,     // address
  input  wire  [`WB_SW-1:0]   wb_sel,     // byte select
  input  wire  [`WB_DW-1:0]   wb_dat_i,   // data input
  output wire  [`WB_DW-1:0]   wb_dat_o,   // data output
  output wire                 wb_ack,     // acknowledge
  output wire                 wb_err,     // error
  output wire                 wb_rty,     // retry
  // additional processor interface signals
  output wire                 irq,
  // SPI signals
  output wire [`SPI_SSW-1:0]  spi_ss_n,   // active low slave select signal
  output wire                 spi_sclk,   // serial clock
  input  wire                 spi_miso,   // serial master input slave output
  inout  wire                 spi_mosi    // serial master output slave input (or threewire bidirectional)
);

/*\
 *  definitions are copied into parameters,
 *  offering two parametrization options
\*/

// SPI interface configuration parameters
parameter CFG_dir   =  1;  // shift direction (0 - LSB first, 1 - MSB first)
parameter CFG_cpol  =  0;  // clock polarity
parameter CFG_cpha  =  0;  // clock phase
parameter CFG_3wr   =  0;  // duplex type (0 - SPI full duplex, 1 - 3WIRE half duplex (MOSI is shared))

// SPI slave select paramaters
parameter PAR_ss_rw =  `SPI_SSW;  // slave select register width

// SPI shift register parameters
parameter PAR_sh_rw = 32;  // shift register width (default width is eqal to wishbone bus width)
parameter PAR_sh_cw =  5;  // shift counter width (logarithm of shift register width)

// SPI transfer type parameters
parameter PAR_tu_rw =  8;  // shift transfer unit register width (default granularity is byte)
parameter PAR_tu_cw =  3;  // shift transfer unit counter width (counts the bits of a transfer unit)

// SPI transfer control counter register width (defoult up to 4 byte transfers)
parameter PAR_tc_rw = PAR_sh_cw - PAR_tu_cw;

// SPI clock divider parameters
parameter PAR_cd_en =  1;  // clock divider enable (0 - use full system clock, 1 - use divider)
parameter PAR_cd_ri =  1;  // clock divider register inplement (otherwise the default clock division factor is used)
parameter PAR_cd_rw =  8;  // clock divider register width
parameter PAR_cd_ft =  1;  // default clock division factor

/*\
 *  local signals
\*/

// clock divider signals
reg  [PAR_cd_rw-1:0] cnt_clk;  // clock divider counter
reg  [PAR_cd_rw-1:0] reg_div;  // register holding the requested clock division ratio
reg  reg_clk;                  // register storing the SCLK clock value (additional division by two)
wire reg_clk_posedge, reg_clk_negedge;

// spi shifter signals
reg  [PAR_sh_rw-1:0] reg_s;    // spi data shift register
reg  reg_i, reg_o;             // spi input-sampling to output-change phase shift registers
wire ser_i, ser_o;             // shifter serial input and output multiplexed signals

// spi slave select signals
reg  [PAR_ss_rw-1:0] reg_ss;   // active high slave select register

// spi configuration registers (shift direction, clock polarity and phase, 3 wire option)
reg  cfg_dir, cfg_cpol, cfg_cpha, cfg_3wr;

// spi shift transfer control registers
reg  [PAR_sh_cw-1:0] cnt_bit;  // counter of shifted bits
reg  [PAR_tu_cw-1:0] ctl_cnt;  // counter of transfered data units (bytes by defoult)
wire ctl_run;                  // transfer running status

reg  ctl_oe;                   // output enable for the mosi signal

/*\
 *  generalized bus signals
\*/

wire              bus_trn;  // bus transfer
wire              bus_we;   // bus write enable
wire        [2:0] bus_adr;  // bus address
wire [`WB_SW-1:0] bus_sel;  // bus byte select
wire [`WB_DW-1:0] bus_dat_i, bus_dat_o;  // data bus

// register select signals
wire              bus_sel_div;  // clock divider factor
wire              bus_sel_ss;   // slave select (active high)
wire              bus_sel_cfg;  // configuration register
wire              bus_sel_ctl;  // control register
wire              bus_sel_dat;  // data register

// input and output data signals
wire        [7:0] bus_dat_i_div, bus_dat_o_div;
wire        [7:0] bus_dat_i_ss,  bus_dat_o_ss;
wire        [7:0] bus_dat_i_cfg, bus_dat_o_cfg;
wire        [7:0] bus_dat_i_ctl, bus_dat_o_ctl;
wire [`WB_DW-1:0] bus_dat_i_dat, bus_dat_o_dat;

/*\
 *  bus access implementation (generalisation of wishbone bus signals)
\*/

// bus transfer
assign bus_trn = wb_cyc & wb_stb & wb_ack;

// bus write enable
assign bus_we  = wb_we;

// bus address and select
assign bus_adr = wb_adr [2:0];
assign bus_sel = wb_sel;

// data bus
assign bus_dat_i =  wb_dat_i;
assign  wb_dat_o = bus_dat_o;

// wishbone acknowledge, error and retry
assign wb_ack = 1'b1;
assign wb_err = 1'b0;
assign wb_rty = 1'b0;

// acknowledge can be generated from cycle and strobe
// if the bus implementation requires it
//assign wb_ack = wb_cyc & wb_stb;

// address decoder
assign bus_sel_dat = (wb_adr == 4);
`ifdef WB_32BIT
assign bus_sel_div = (bus_adr == 0) ? bus_sel [3] : 1'b0;
assign bus_sel_ss  = (bus_adr == 0) ? bus_sel [2] : 1'b0;
assign bus_sel_cfg = (bus_adr == 0) ? bus_sel [1] : 1'b0;
assign bus_sel_ctl = (bus_adr == 0) ? bus_sel [0] : 1'b0;
`elsif WB_16BIT
assign bus_sel_div = (bus_adr == 2) ? bus_sel [1] : 1'b0;
assign bus_sel_ss  = (bus_adr == 2) ? bus_sel [0] : 1'b0;
assign bus_sel_cfg = (bus_adr == 0) ? bus_sel [1] : 1'b0;
assign bus_sel_ctl = (bus_adr == 0) ? bus_sel [0] : 1'b0;
`elsif WB_8BIT
assign bus_sel_div = (bus_adr == 3);
assign bus_sel_ss  = (bus_adr == 2);
assign bus_sel_cfg = (bus_adr == 1);
assign bus_sel_ctl = (bus_adr == 0);
`else
$display ("ERROR () Data bus width is not properly defined!");
`endif

// input data asignment
assign bus_dat_i_dat = bus_dat_i;
`ifdef WB_32BIT
assign {bus_dat_i_div, bus_dat_i_ss, bus_dat_i_cfg, bus_dat_i_ctl} = bus_dat_i;
`elsif WB_16BIT
assign {bus_dat_i_div, bus_dat_i_ss } = bus_dat_i;
assign {bus_dat_i_cfg, bus_dat_i_ctl} = bus_dat_i;
`elsif WB_8BIT
assign  bus_dat_i_div = bus_dat_i;
assign  bus_dat_i_ss  = bus_dat_i;
assign  bus_dat_i_cfg = bus_dat_i;
assign  bus_dat_i_ctl = bus_dat_i;
`endif

// output data multiplexer
`ifdef WB_32BIT
assign bus_dat_o = (bus_adr[2]   == 0) ? {bus_dat_o_div, bus_dat_o_ss, bus_dat_o_cfg, bus_dat_o_ctl} :
                                          bus_dat_o_dat;
`elsif WB_16BIT
assign bus_dat_o = (bus_adr[2:1] == 2) ? {bus_dat_o_div, bus_dat_o_ss } :
                   (bus_adr[2:1] == 0) ? {bus_dat_o_cfg, bus_dat_o_ctl} :
                                          bus_dat_o_dat;
`elsif WB_8BIT
assign bus_dat_o = (bus_adr[2:0] == 3) ?  bus_dat_o_div :
                   (bus_adr[2:0] == 2) ?  bus_dat_o_ss  :
                   (bus_adr[2:0] == 1) ?  bus_dat_o_cfg :
                   (bus_adr[2:0] == 0) ?  bus_dat_o_ctl :
                                          bus_dat_o_dat;
`endif

/*\
 *  clock divider 
\*/

// clock division factor number register
always @(posedge clk, posedge rst)
if (rst)
  reg_div <= #1 PAR_cd_ft;
else if (bus_trn & bus_we & bus_sel_div)
  reg_div <= bus_dat_i_div;

// bus read value of the clock divider factor register
assign bus_dat_o_div = reg_div;

// clock counter
always @(posedge clk, posedge rst)
if (rst)
  cnt_clk <= #1 'd0;
else if (ctl_run) begin
  if (cnt_clk == 'd0)
    cnt_clk <= #1 reg_div;
  else
    cnt_clk <= #1 cnt_clk - 1;
end

// clock output register (divider by 2)
always @(posedge clk)
if (~ctl_run)
  reg_clk <= #1 cfg_cpol;
else if (cnt_clk == 0)
  reg_clk <= #1 ~reg_clk;

// spi clock positive and negative edge
// used to synchronise input, output and shift registers
assign reg_clk_posedge = (cnt_clk == 0) & ~reg_clk;
assign reg_clk_negedge = (cnt_clk == 0) &  reg_clk;

// spi clock output pin
assign spi_sclk = reg_clk;

/*\
 *  spi slave select
\*/

always @(posedge clk, posedge rst)
if (rst)
  reg_ss <= #1 'b0;
else if (bus_trn & bus_we & bus_sel_ss)
  reg_ss <= #1 bus_dat_i_ss;

// bus read value of the slave select register
assign bus_dat_o_ss = reg_ss;

// slave select active low output pins
assign spi_ss_n = ~reg_ss;

/*\
 *  configuration registers
\*/

always @(posedge clk, posedge rst)
if (rst) begin
  cfg_dir  <= #1 CFG_dir;
  cfg_cpol <= #1 CFG_cpol;
  cfg_cpha <= #1 CFG_cpha;
  cfg_3wr  <= #1 CFG_3wr;
end else if (bus_trn & bus_we & bus_sel_cfg) begin
  cfg_dir  <= #1 bus_dat_i_cfg [3   ];
  cfg_cpol <= #1 bus_dat_i_cfg [ 2  ];
  cfg_cpha <= #1 bus_dat_i_cfg [  1 ];
  cfg_3wr  <= #1 bus_dat_i_cfg [   0];
end

// bus read value of the configuration register
assign bus_dat_o_cfg = {4'b0, cfg_dir, cfg_cpol, cfg_cpha, cfg_3w};

/*\
 *  control registers (transfer counter and serial output enable)
\*/

// bit counter
always @(posedge clk, posedge rst)
if (rst)
  cnt_bit <= #1 0;
else if (ctl_cnt != 0)
  cnt_bit <= #1 cnt_bit + 1;

// transfer control counter
always @(posedge clk, posedge rst)
if (rst)
  ctl_cnt <= #1 0;
else begin
  // write from the CPU bus has priority
  if (bus_trn & bus_we & bus_sel_ctl)
    ctl_cnt <= #1 bus_dat_i_ctl [PAR_tc_rw-1:0];
  // decrement at the end of each transfer unit (byte by default)
  else if ( (&(cnt_bit [PAR_tu_cw-1:0])) )
    ctl_cnt <= #1 ctl_cnt - 1;
end

// spi transfer run status
assign ctl_run = (ctl_cnt != 0);

// output enable control register
always @(posedge clk, posedge rst)
if (rst)
  ctl_oe <= #1 0;
else
  ctl_oe <= #1 bus_dat_i_ctl [7];

// bus read value of the control register (output enable, transfer counter)
assign bus_dat_o_ctl = {ctl_oe, {8-1-PAR_tu_cw{1'b0}}, ctl_cnt};

/*\
 *  spi shift register
\*/

// shift register implementation
always @(posedge clk)
if (bus_trn & bus_we & bus_sel_dat) begin
  reg_s <= #1 wb_dat_i;
end else if (ctl_run) begin
  if (cfg_dir)
    reg_s <= #1 {reg_s [PAR_sh_rw-2:0], ser_i};
  else
    reg_s <= #1 {ser_i, reg_s [PAR_sh_rw-1:1]};
end

// bus read value of the data ragister
assign bus__dat_o_dat = reg_s;

/*\
 *  serial interface
\*/

// output register
always @(posedge clk)
if ( ((cfg_cpol == 0) & reg_clk_negedge) | ((cfg_cpol == 1) & reg_clk_posedge) )
  reg_o <= #1 ser_o;

// input register
always @(posedge clk)
if ( ((cfg_cpol == 0) & reg_clk_negedge) | ((cfg_cpol == 1) & reg_clk_posedge) )
  reg_i <= #1 ser_i;

// the serial output from the shift register depends on the direction of shifting
assign ser_o    = (cfg_dir) ? reg_s [shift_rw-1] : reg_s [0];
assign ser_i    = (cfg_cpha == 0) ? reg_i : (cfg_3wr == 0) ? spi_miso : spi_mosi;
assign spi_mosi = (ctl_oe) ? ( (cfg_cpha == 0) ? ser_o : reg_o ) : 1'bz;


endmodule
