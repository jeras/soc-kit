//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  WISHBONE bus interface master model                                     //
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
  // bus properties
  parameter AW = `WB_AW,         // address bus width
  parameter DW = `WB_DW,         // data bus width
  parameter SW = `WB_DW/8,       // byte select bus width
  parameter AM = {AW{1'b1}}-(SW-1), // log2(SW),
  parameter IV = 1'bx,           // idle value (value of signals when bus is idle)
  // input file (program), output file (read data)
  parameter FILE_I = "",         // program filename
  parameter FILE_O = "",         // program filename
  // presentation
  parameter NAME = "noname",     // instance name used for ERROR reporting
  parameter AUTO = 0
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

// temporal wishbone variables (used for parsing)
reg [AW-1:0] t_adr;
reg [SW-1:0] t_sel;
reg [DW-1:0] t_dat;
reg [DW-1:0] t_mask;

// wishbone status
wire    trn;       // transfer completion indicator
wire    rdy;       // bus redyness status

// wishbone master status
integer cnt;       // burst or idle state counter
reg     run = 0;   // master running status
reg     raw;       // raw access status

// file pointer and access status
integer fp_i, fs_i = 0; // program input
integer fp_o, fs_o = 0; // read output

// program file parsing variables
reg [8*8-1:0] inst, text;
reg     [7:0] c;
reg [8*8-1:0] endian;
integer       width;
integer       shift;
integer       i;

// debug TODO
integer p;

///////////////////////////////////////////////////////////////////////////////
// wishbone controller                                                       //
///////////////////////////////////////////////////////////////////////////////

// wishbone bus status
assign trn = cyc & stb & (ack | err | rty);
assign rdy = ~cyc | trn & ((cti == 3'b000) | (cti == 3'b111));

// automatic initialization if enabled
initial begin
  $display ("DEBUG: Starting master");
  if (AUTO)  start (FILE_I, FILE_O);
end

// start the wishbone master (open files and start parsing cycle commands)
task start (
  input reg [256*8-1:0] filename_i,
  input reg [256*8-1:0] filename_o
); begin
  if (filename_i != "") begin
    fp_i = $fopen (filename_i, "r");
    $display ("DEBUG: Opening program input file \"%0s\".", filename_i);
  end else begin
    $display ("ERROR: No program input file specified!");
    $finish;
  end
  if (filename_o != "") begin
    fp_o = $fopen (filename_o, "w");
    $display ("DEBUG: Opening read output file \"%0s\".", filename_o);
  end else begin
    $display ("DEBUG: No read ouptut file specified!");
    $finish;
  end
  run = 1;
end endtask

// stop wishbone master (stop parsing wait for end of cycle and close files)
task stop; begin
  run = 0;
  $fclose (fp_i);
  $fclose (fp_o);
end endtask

integer cnt_clk = 0;
integer position = 0;
always @ (posedge clk) begin
  cnt_clk <= cnt_clk + 1;
//  fs_i = $fscanf (fp_i, "%s ", instruction);
  position = $ftell(fp_i);
//  $display ("DEBUG: at positions %d, parsing %s", position, instruction);
//  fs_i = $fscanf (fp_i, "%s", instruction);
  if (fs_i == -4) $finish;
  if (cnt_clk > 100) $finish;
end

// command parser and cycle controller
always @ (posedge rst, posedge clk)
if (rst) begin
  // set the bus into an idle state
  {cyc, stb, we, adr, sel, cti, bte, dat_o} <= {1'b0, IV, IV, {AW{IV}}, {SW{IV}}, {3{IV}}, {2{IV}}, {DW{IV}}};
  cnt <= 0;
  raw <= 0;
end else begin
  // if 'run' is disabled, the master skips the clock pulse
  if (run) begin
    // in the event of a data transfer
    if (trn) begin
      // sent the data to the output file
      if (~we)  $fwrite (fp_o, "%h", dat_i);
      case (instr)
        "write", "read" : begin end
        default : begin
          if (ack)  $fwrite (fp_o, " ack");
          if (err)  $fwrite (fp_o, " err");
          if (rty)  $fwrite (fp_o, " rty");
        end
      endcase
      $fwrite (fp_o, "/n");
      // properly finish burst cycles
      if (cnt >  0)  cnt <= cnt - 1;
      if (cnt == 1)  cti <= 3'b111;
      // burst address incrementer
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
    end
    // handler for raw transfers
    if (raw) begin
      if (cnt >  0)  cnt <= cnt - 1;
    end
    // in the case of the end of a single or burst cycle and in the case of raw cycles
    if ((rdy | raw) & (cnt == 0)) begin
      // wait for a new line in the file and skip comment lines
      fs_i = 0;
      while (fs_i == 0) begin
        $display ("DEBUG: program file status %d.", fs_i);
        while (fs_i == 0) begin
          c = $fgetc(fp_i);
          case (c)
          " ", "\n" : fs_i = 0;
          default   : fs_i = 1;
          endcase
        end
        fs_i = $ungetc(c, fp_i);
        fs_i = $fscanf (fp_i, "%s ", inst);
        $display ("DEBUG: program file status %d.", fs_i);
        if (inst == "#") begin
          while ($fgetc(fp_i) != "\n") begin end
          fs_i = 0;
        end
      end
      // instruction decoder
      case (inst)
        // system instructions
        "display" : begin
          fs_i = $fscanf (fp_i, "%s ", text);
          $display ("INFO: Master program requested to display \"%s\".", text);
        end
        "end"    : begin
          run <= 0;
        end
        "finish" : begin
          $fclose (fp_i);
          $fflush (fp_o);
          $fclose (fp_o);
          $finish;
        end
        // bus generic instructions
        "idle" : begin
          {cyc, stb, we, adr, sel, cti, bte, dat_o} <= {1'b0, IV, IV, {AW{IV}}, {SW{IV}}, {3{IV}}, {2{IV}}, {DW{IV}}};
          raw <= 1;
        end
        "write", "read" : begin
          // parsing
          fs_i = $fscanf (fp_i, "%s %d %h ", endian, width, t_adr);
          if (inst == "write")  fs_i = $fscanf (fp_i, "%h ", t_dat);
          // processing
          case (endian)
            "be"    : shift = SW - width/8 - (t_adr & ~AM);
            "le"    : shift =                (t_adr & ~AM);
            default : $display ("ERROR: Parsing error: Endianness not specified corectly");
          endcase
          t_sel = (2**(width/8))-1 << shift;
          for (i=0; i<SW; i=i+1)
            t_mask = {(t_sel [i] ? 8'h00 : 8'hxx), t_mask [DW-1:8]};
            //t_mask = {t_mask [DW-8-1:0], (t_sel [i] ? 8'h00 : 8'hxx)};
          t_dat = t_dat << (8*shift);
          // applying signals to the bus
          cyc   <= 1'b1;
          stb   <= 1'b1;
          we    <= (inst == "write") ? 1'b1 : 1'b0;
          adr   <= t_adr & AM;
          sel   <= t_sel;
          cti   <= 3'b000;
          bte   <= 2'b00;
          dat_o <= (inst == "write") ? (t_dat ^ t_mask) : {DW{IV}};
        end
        // wishbone specific instructions
        "wb_bst", "wb_raw" : begin
          fs_i = $fscanf (fp_i, "%d ", cnt);
          fs_i = $fscanf (fp_i, "%b %b %b %h %h %b %b %h ", cyc, stb, we, adr, sel, cti, bte, dat_o);
          if (inst == "wb_raw")  raw <= 1;
        end
        // the default is an idle bus
        default  : begin
          $display ("WARNING: Parsing error: Unrecognized instruction \"%s\".", inst);
          {cyc, stb, we, adr, sel, cti, bte, dat_o} <= {1'b0, IV, IV, {AW{IV}}, {SW{IV}}, {3{IV}}, {2{IV}}, {DW{IV}}};
          while (1) begin
            c    = $fgetc(fp_i);
            p    = $ftell(fp_i);
            $display ("DEBUG: Character %d, \"%s\", position %d", c, c, p);
            //fs_i = $ferror(fp_i, text);
            //$display ("DEBUG: Character %d, \"%s\", position %d, status %d, error %s", c, c, p, fs_i, text);
          end
        end
      endcase
    end
  end
end

///////////////////////////////////////////////////////////////////////////////
// tasks performing wishbone cycles                                          //
///////////////////////////////////////////////////////////////////////////////

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

