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

module wishbone_master #(
  // parameter declaration
  parameter AW = `WB_AW,         // address bus width
  parameter DW = `WB_DW,         // data bus width
  parameter SW = `WB_DW/8,       // byte select bus width
  parameter DE = `WB_DE,         // data endianness ('BIG' or 'LITTLE')
  parameter IV = 1'bx,           // idle value (value of signals when bus is idle)
  // file parameter
  parameter FILE = "",           // program filename
  // presentation parameter
  parameter NAME = "noname",      // instance name used for ERROR reporting
  parameter AUTOBOOT = 1,
  parameter STREAM = 1
)(
  // Wishbone system signals
  input  wire          clk,      // system clock
  input  wire          rst,      // system reset
  // Wishbone master outputs
  output reg           cyc,      // cycle
  output reg           stb,      // data strobe
  output reg           we,       // write enable
  output reg  [AW-1:0] adr,      // address
  output reg  [SW-1:0] sel,      // byte select
  // Wishbone master burst outputs
  output reg     [2:0] cti,      // cycle type identifier
  output reg     [1:0] bte,      // burst type extension
  // Wishbone data outputs and inputs
  output reg  [DW-1:0] dat_o,    // data output
  input  wire [DW-1:0] dat_i,    // data input
  // Wishbone slave response
  input  wire          ack,      // acknowledge
  input  wire          err,      // error
  input  wire          rty,      // retry
  // transfer error detection
  output wire          error
);

//////////////////////////////////////////////////////////////////////////////
// local signals                                                            //
//////////////////////////////////////////////////////////////////////////////

reg raw;
reg [7:0] cnt_bst;

// runnung status
reg run = 0;

// wishbone status
wire    trn;       // transfer completion indicator
wire    rdy;       // bus redyness status

// program file
integer program_file;       // program file pointer
integer program_status = 0; // program file access stattus

// program file parsing variables
reg [8*8-1:0] inst, text;

///////////////////////////////////////////////////////////////////////////////
// wishbone data path                                                        //
///////////////////////////////////////////////////////////////////////////////

assign trn = cyc & stb & (ack | err | rty);
assign rdy = ~cyc | trn & ((cti == 3'b000) | (cti == 3'b111));

initial begin
  $display ("DEBUG: Stating master");
  if (AUTOBOOT)  start (FILE);
  #200 $finish;
end

task start (input reg [256*8-1:0] filename); begin
  $display ("DEBUG: Opening program file %s", filename);
  program_file = $fopen (filename, "r");
  run = 1;
end endtask

task stop; begin
  run = 0;
end endtask

reg t_cyc;
integer cnt_clk = 0;
integer position = 0;


always @ (posedge clk) begin
  cnt_clk <= cnt_clk + 1;
//  program_status = $fscanf (program_file, "%s ", instruction);
  position = $ftell(program_file);
//  $display ("DEBUG: at positions %d, parsing %s", position, instruction);
//  program_status = $fscanf (program_file, "%s", instruction);
  if (program_status == -4) $finish;
  if (cnt_clk > 20) $finish;
end

integer character;

always @ (posedge rst, posedge clk)
if (rst) begin
  // set the bus into an idle state
  {cyc, stb, we, adr, sel, cti, bte, dat_o} <= {1'b0, IV, IV, {AW{IV}}, {SW{IV}}, {3{IV}}, {2{IV}}, {DW{IV}}};
  raw <= 0;
end else begin
  if (run) begin
    if (trn) begin
//    if (we && STREAM)  $fwrite (program_file, "%h\n", dat_i);
      if (~((cti == 3'b000) | (cti == 3'b111))) begin
        cnt_bst <= cnt_bst - 1;
        if (cnt_bst == 1)
          cti <= 3'b111;
      end
    end
    if (rdy | raw) begin
      program_status = $fscanf (program_file, "%s ", inst);
      case (inst)
        "display" : begin
          program_status = $fscanf (program_file, "%s ", text);
          $display ("INFO: Master program requested to display \"%s\".", text);
        end
        "raw_wb" : begin
          program_status = $fscanf (program_file, "%b %b %b %h %h %b %b %h ", cyc, stb, we, adr, sel, cti, bte, dat_o);
          raw <= 1;
        end
        "write"  : begin
          {cyc, stb, we, cti, bte} <= {1'b1, 1'b1, 1'b1, 3'b000, 2'b00};
          program_status = $fscanf (program_file, "%h %h %h ", adr, sel, dat_o);
        end
        "read"   : begin
          {cyc, stb, we, cti, bte} <= {1'b1, 1'b1, 1'b0, 3'b000, 2'b00};
          program_status = $fscanf (program_file, "%h %h ", adr, sel);
          dat_o <= {DW{IV}};
        end
        "finish" : begin
          $fclose (program_file);
          $finish;
        end
        default  : begin
          $display ("WARNING: Unrecognized instruction \"%s\".", inst);
          {cyc, stb, we, adr, sel, cti, bte, dat_o} <= {1'b0, IV, IV, {AW{IV}}, {SW{IV}}, {3{IV}}, {2{IV}}, {DW{IV}}};
        end
      endcase
    end
  end
end

///////////////////////////////////////////////////////////////////////////////
// tasks performing wishbone cycles                                          //
///////////////////////////////////////////////////////////////////////////////

//// raw FIFO loading
//task fifo_load;
//  input [lw-1:0] line;  // raw line to be loaded to the FIFO
//begin
//  if (i_d + 1 < fl) begin
//    fifo[i_w] <= line;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl; 
//  end else
//    $display ("ERROR: %s: Wishbone master fifo overflow", name);
//end
//endtask
//
//// filling the space between cycles
//task cyc_idle;
//  input [32-1:0] len;   // the number of loaded IDLE cycles
//  integer        n;
//begin
//  if (i_d + len < fl) begin
//    for (n=0; n<len; n=n+1) begin
//      fifo[i_w] = line0;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
//  end end else
//    $display ("ERROR: %s: Wishbone master fifo overflow", name);
//end
//endtask
//
//// generating a single transfer
//task cyc_single;
//  input    [aw-1:0] adr;    // address
//  input             we;     // write enable
//  input    [sw-1:0] sel;    // byte select
//  input    [dw-1:0] dat_o;  // output (write) data
//  input    [dw-1:0] dat_i;  // expected input (read) data
//  // local variables
//  reg      [aw-1:0] tadr;   // truncated address
//begin
//  tadr = adr/sw*sw;  // zeroing constant address bits
//  if (i_d + 1 < fl) begin
//    fifo[i_w] = {1'b1, 1'b1, 1'b1, we, tadr, sel, 3'b000, {2{iv}}, dat_o, dat_i, 3'b100};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
//    //   name     chk,  cyc,  stb, we,  adr, sel     cti,     bte, dat_o, dat_i, reply_x;
//  end else
//    $display ("ERROR: %s: Wishbone master fifo overflow", name);
//end
//endtask
//
//// generating a fixed length burst transfer
//task cyc_burst;
//  input    [aw-1:0] adr;    // address
//  input             we;     // write enable
//  input       [2:0] cti;    // cycle type identifier
//  input       [1:0] bte;    // burst type extension
//  input [fl*dw-1:0] dat_o;  // output (write) data array
//  input [fl*dw-1:0] dat_i;  // expected input (read) data array
//  input    [aw-1:0] len;
//  // local variables
//  integer           n, len_out;
//  reg      [aw-1:0] mask;   // address mask for wrapping bursts
//  reg      [aw-1:0] incr;   // address increment
//  reg      [aw-1:0] tadr;   // truncated address
//  reg      [aw-1:0] badr;   // calculated burst address
//  integer           midx;   // pointer into the data array
//begin
//  tadr = adr/sw*sw;  // zeroing constant address bits
//  if (cti == 3'b000)
//    len_out = 1;
//  else if ( (cti == 3'b001) | (cti == 3'b010) ) begin
//    if (bte == 2'b00)  len_out = len;
//    else               len_out = 4*(2**(bte-1));
//    if (i_d + len_out < fl) begin
//      if (cti == 3'b010) begin
//        incr = sw;
//        mask = len_out*sw-1;
//      end else begin
//        incr = 0;
//        mask = 0;
//      end
//      for (n=0; n<len_out-1; n=n+1) begin
//        if (bte == 2'b00)  badr =  tadr          +          incr*n;
//        else               badr = (tadr & ~mask) + ((tadr + incr*n) & mask);
//        midx = len_out-n-1;
//        fifo[i_w] = {1'b1, 1'b1, 1'b1, we, badr, {sw{1'b1}},    cti, bte, dat_o[dw*midx+:dw], dat_i[dw*midx+:dw], 3'b100};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
//      end
//        if (bte == 2'b00)  badr =  tadr          +          incr*n;
//        else               badr = (tadr & ~mask) + ((tadr + incr*n) & mask);
//        midx = len_out-n-1;
//        fifo[i_w] = {1'b1, 1'b1, 1'b1, we, badr, {sw{1'b1}}, 3'b111, bte, dat_o[dw*midx+:dw], dat_i[dw*midx+:dw], 3'b100};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
//      //     name     chk,  cyc,  stb, we,  adr,        sel     cti, bte, dat_o,              dat_i,              reply_x;
//    end else
//      $display ("ERROR: %s: Wishbone master fifo overflow", name);
//  end else
//    $display ("ERROR: %s: Wrong value for 'cti' signal", name);
//end
//endtask


endmodule

