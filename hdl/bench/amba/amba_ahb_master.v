//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AHB bus master model                                                    //
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

`include "amba_ahb_defines.v"

module amba_ahb_master #(
  // bus parameters
  parameter AW = `AW,            // address bus width
  parameter DW = `DW,            // data bus width
  parameter RW = `RW,            // response width
  parameter DE = `DE,            // available options are 'BIG' and 'LITTLE'
  parameter IV = 1'bx,           // idle value (value of signals when bus is idle)
  // input file (program), output file (read data)
  parameter FILE_I = "",         // program filename
  parameter FILE_O = "",         // program filename
  // presentation
  parameter NAME = "noname",     // instance name used for ERROR reporting
  parameter AUTO = 0
)(
  // AMBA AHB system signals
  input  wire          hclk,     // Bus clock
  input  wire          hresetn,  // Reset (active low)
  // AMBA AHB master signals
  output reg  [AW-1:0] haddr,    // Address bus
  output reg     [1:0] htrans,   // Transfer type
  output reg           hwrite,   // Transfer direction
  output reg     [2:0] hsize,    // Transfer size
  output reg     [2:0] hburst,   // Burst type
  output reg     [3:0] hprot,    // Protection control
  output reg  [DW-1:0] hwdata,   // Write data bus
  // AMBA AHB slave signals
  input  wire [DW-1:0] hrdata,   // Read data bus
  input  wire          hready,   // Transfer done
  input  wire [RW-1:0] hresp,    // Transfer response
  // slave response check
  output wire          error     // unexpected response from slave
);

//////////////////////////////////////////////////////////////////////////////
// local parameters and signals                                             //
//////////////////////////////////////////////////////////////////////////////

localparam AM = 2;

// registered (delayed) values of master output signals
reg [AW-1:0] haddr_r;
reg    [1:0] htrans_r;
reg          hwrite_r;
reg    [2:0] hsiz_r;
reg    [2:0] hburst_r;
reg    [2:0] hprot_r;

// temporal wishbone variables (used for parsing)
reg [AW-1:0] t_haddr;
reg    [2:0] t_hsize;
reg [DW-1:0] t_hwdata;
reg [DW-1:0] t_mask;            // data mask

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
reg [8*8-1:0] inst, instr_r, text;
reg     [7:0] c;
reg [8*8-1:0] endian;
integer       width;
integer       shift;
integer       i;

///////////////////////////////////////////////////////////////////////////////
// initialization and on request tasks                                       //
///////////////////////////////////////////////////////////////////////////////

initial begin
  $display ("DEBUG: Starting master");
  if (AUTO)  start (FILE_I, FILE_O);
  $finish;
end

task start (
  input reg [256*8-1:0] filename_i,
  input reg [256*8-1:0] filename_o
); begin
  if (filename_i != "") begin
    fp_i = $fopen (filename_i, "r");
    $display ("DEBUG: Opening program input file %s", filename_i);
  end else begin
    $display ("ERROR: No program input file specified!");
    $finish;
  end
  if (filename_o != "") begin
    fp_o = $fopen (filename_o, "w");
    $display ("DEBUG: Opening read output file %s", filename_o);
  end else begin
    $display ("DEBUG: No read ouptut file specified!");
    $finish;
  end
  run = 1;
end endtask

task stop; begin
  run = 0;
end endtask

///////////////////////////////////////////////////////////////////////////////
// master state machine                                                      //
///////////////////////////////////////////////////////////////////////////////

assign rdy = hready & htrans_r[1];
assign trn = hready | (hresp != `OKAY);

always @ (negedge hresetn, posedge hclk)
if (~hresetn) begin
  // set the bus into an idle state
  {haddr, htrans, hwrite, hsize, hburst, hprot, hwdata} <= {{AW{IV}}, `IDLE, IV, {3{IV}}, {3{IV}}, {4{IV}}, {DW{IV}}};
  cnt <= 0;
  raw <= 0;
end else begin
  // if 'run' is disabled, the master skips the clock pulse
  if (run) begin
    // in the event of a data transfer
    if (trn) begin
      // sent the data to the output file
      if (~hwrite)  $fwrite (fp_o, "%h", hrdata);
      case (instr_r)
        "write", "read" : begin end
        default : begin
          $fwrite (fp_o, " %s", hresp ? "ERROR" : "OKAY");
        end
      endcase
      $fwrite (fp_o, "/n");
      // properly finish burst cycles
//      if (cnt >  0)  cnt <= cnt - 1;
//      if (cnt == 1)  cti <= 3'b111;
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
      // wait for a ne line in the file and skip comment lines
      fs_i = 0;
      while (fs_i == 0) begin
        fs_i = $fscanf (fp_i, "%s ", inst);
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
          {haddr, htrans, hwrite, hsize, hburst, hprot, hwdata} <= {{AW{IV}}, `IDLE, IV, {3{IV}}, {3{IV}}, {4{IV}}, {DW{IV}}};
          raw <= 1;
        end
        "write", "read" : begin
          // parsing
          fs_i = $fscanf (fp_i, "%s %d %h ", endian, width, t_haddr);
          if (inst == "write")  fs_i = $fscanf (fp_i, "%h ", t_hwdata);
          // processing
          case (width)
                  8 : t_hsize = 3'b000;
                 16 : t_hsize = 3'b001;
                 32 : t_hsize = 3'b010;
                 64 : t_hsize = 3'b011;
                128 : t_hsize = 3'b100;
                256 : t_hsize = 3'b101;
                512 : t_hsize = 3'b110;
               1024 : t_hsize = 3'b111;
            default : $display ("ERROR: Parsing error: Unsupported transfer width: %0d", width);
          endcase
          case (endian)
            "be"    : shift = (DW-width)/8 - (t_haddr & ~AM);
            "le"    : shift =                (t_haddr & ~AM);
            default : $display ("ERROR: Parsing error: Unsuported endianness: %0s", endian);
          endcase
          t_mask = {DW{1'bx}} | (2**width)-1 << shift;
          t_hwdata = t_hwdata << (8*shift);
          // applying signals to the bus
          haddr  <= t_haddr & AM;
          htrans <= `NONSEQ;
          hwrite <= (inst == "write") ? 1'b1 : 1'b0;
          hsize  <= t_hsize;
          hburst <= `SINGLE;
          hprot  <= 4'b0011;
          hwdata <= (inst == "write") ? (t_hwdata ^ t_mask) : {DW{IV}};
        end
        // wishbone specific instructions
        "ahb_bst", "ahb_raw" : begin
          fs_i = $fscanf (fp_i, "%d ", cnt);
          fs_i = $fscanf (fp_i, "%h %b %b %b %b %b %h", haddr, htrans, hwrite, hsize, hburst, hprot, hwdata);
          if (inst == "wb_raw")  raw <= 1;
        end
        // the default is an idle bus
        default  : begin
          $display ("WARNING: Parsing error: Unrecognized instruction \"%s\".", inst);
          {haddr, htrans, hwrite, hsize, hburst, hprot, hwdata} <= {{AW{IV}}, `IDLE, IV, {3{IV}}, {3{IV}}, {4{IV}}, {DW{IV}}};
        end
      endcase
    end
  end
end


/*
// error due to unexpected AHB slave response
assign error = htrans_r[1] & hready & (~hwrite_r & (hrdata_x !== hrdata) | (hresp_x !== hresp));

// raw FIFO loading
task fifo_load;
  input [lw-1:0] line;  // raw line to be loaded to the FIFO
begin
  if (i_d + 1 < fl) begin
    fifo[i_w] <= line;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl; 
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// filling the space between cycles
task cyc_idle;
  input [32-1:0] len;        // the number of loaded IDLE cycles
  integer        n;
begin
  if (i_d + len < fl) begin
    for (n=0; n<len; n=n+1) begin
      fifo[i_w] = line0;  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
  end end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// generating a single transfer
task cyc_single;
  input    [AW-1:0] adr;
  input             we;
  input       [2:0] siz;
  input       [3:0] prt;
  input    [DW-1:0] dat_o;  // output (write) data
  input    [DW-1:0] dat_i;  // expected input (read) data
begin
  if (i_d + 1 < fl) begin
    fifo[i_w] = {1'b1,   adr, `NONSEQ,     we,   siz, `SINGLE,   prt,  dat_o,    dat_i,   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    // name       chk, haddr,  htrans, hwrite, hsize,  hburst, hprot, hwdata, hrdata_t, hresp_t
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask

// generating a fixed length burst transfer
task cyc_burst;
  input    [AW-1:0] adr;
  input             we;
  input       [2:0] siz;
  input       [2:0] bst;    // burst type
  input       [3:0] prt;
  input [16*DW-1:0] dat_o;  // output (write) data array
  input [16*DW-1:0] dat_i;  // expected input (read) data array
  input    [AW-1:0] len;
  // local variables
  integer           n;
  reg      [AW-1:0] mask;   // address mask for wrapping bursts
  reg      [AW-1:0] incr;   // address increment
  reg      [AW-1:0] badr;   // calculated burst address
  integer           midx;   // pointer into the data array
begin
  if (i_d + 2**(bst[2:1]+1) < fl) begin
    mask = (1 << (siz+bst[2:1]+1)) - 1;
    badr = adr;
    midx = 2**(bst[2:1]+1)-1;
    fifo[i_w] = {1'b1,  badr, `NONSEQ,     we,   siz,    bst,   prt, dat_o[DW*midx+:DW], dat_i[DW*midx+:DW],   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    for (n=1; n<2**(bst[2:1]+1); n=n+1) begin
    incr = (2**siz)*n;
    if (bst[0])  badr =  adr          +         incr;
    else         badr = (adr & ~mask) + ((adr + incr) & mask);
    midx = midx - 1;
    fifo[i_w] = {1'b1,  badr,    `SEQ,     we,   siz,    bst,   prt, dat_o[DW*midx+:DW], dat_i[DW*midx+:DW],   `OKAY};  i_w=(i_w+1)%fl; i_d=(i_w-i_r)%fl;
    // name       chk, haddr,  htrans, hwrite, hsize, hburst, hprot,             hwdata,           hrdata_t, hresp_t
    end
  end else
    $display ("ERROR: %s: AMBA AHB master fifo overflow", name);
end
endtask
*/

endmodule

