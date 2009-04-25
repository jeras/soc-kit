//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  Zbus device (master/slave) model                                        //
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

module zbus_master #(
  // essential bus parameters
  parameter DW     = 32,         // data width
  parameter AW     = 32,         // address width
  parameter SW     = DW/8,       // byte select width
  parameter DE     = "BIG",      // data endianness ("BIG" or "LITTLE")
  parameter FD     = 1,          // request fifo deepth
  // bus parameter
  parameter BW     = 1 + SW + AW + DW,
  // supported features
  parameter ORDER  = 0,
  parameter INTERLEAVE = 0,
  // simulation behaviour parameters
  parameter IDLE   = 1'b1,       // bus idle state
  // input file (program), output file (read data)
  parameter ZO_FILE = "",        // output interface filename (program)
  parameter ZI_FILE = "",        // inptu interface  filename (received data)
  // presentation
  parameter NAME   = "noname",
  parameter AUTO   = 0
)(
  // system signals
  input  wire          clk,
  input  wire          rst,
  // output interface standard signals
  output wire          zo_req,   // transfer request
  output wire          zo_bus,   // payload
  input  wire          zo_ack,   // transfer acknowledge (bus ready)
  // output interface custom signals
  output wire          zo_wen,   // write enable (0-read or 1-wite)
  output wire [DW-1:0] zo_dat,   // data
  output wire [AW-1:0] zo_adr,   // address
  output wire [SW-1:0] zo_sel,   // byte select
  // input interface
  input  wire          zi_req,   // transfer request
  input  wire          zi_bus,   // payload
  output wire          zi_ack,   // transfer acknowledge (bus ready)
  // input interface custom signals
  input  wire          zi_wen,   // write enable (0-read or 1-wite)
  input  wire [DW-1:0] zi_dat,   // data
  input  wire [AW-1:0] zi_adr,   // address
  input  wire [SW-1:0] zi_sel    // byte select
);

//////////////////////////////////////////////////////////////////////////////
// local parameters and signals                                             //
//////////////////////////////////////////////////////////////////////////////

localparam FCW = $clog2(FD);
localparam AM  = {BW{1'b1}};

// bus status and events
wire    zo_rdy, zi_rdy;         // bus ready for a new transfer
wire    zo_trn, zi_trn;         // bus transfer in progres

// request pipeline counters
wire [FCW-1:0] zo_cnt, zi_cnt;

// master status
reg     run = 0;   // master running status

// file pointer and access status
integer fp_i, fs_i = 0; // program input
integer fp_o, fs_o = 0; // read output

// program file parsing variables
reg [8*8-1:0] inst, instr_r, text;
reg     [7:0] c;
reg [8*8-1:0] endian;
integer       shift;
integer       width;
integer       address;
integer       data;

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
// bus status and events                                                     //
///////////////////////////////////////////////////////////////////////////////

// bus transfer in progres event
assign zo_trn = zo_req & zo_ack;
assign zi_trn = zi_req & zi_ack;

assign zo_rdy = (zo_cnt <= FD);
assign zi_ack = (zi_cnt <= FD);

// pending read request fifos
always @ (posedge clk, posedge rst)
if (rst) begin
  zo_cnt <= 'd0;
  zi_cnt <= 'd0;
end else begin
  if (zo_trn) zo_cnt = zo_cnt + 'd1;
  if (zi_trn) zi_cnt = zi_cnt + 'd1;
end

///////////////////////////////////////////////////////////////////////////////
// bus otput machine                                                         //
///////////////////////////////////////////////////////////////////////////////

always @ (posedge clk, posedge rst)
if (rst) begin
  // set the bus into an idle state
  zo_req <= 1'b0;
  zo_bus <= {BW{IV}};
end else if (run) begin
  if (zo_trn) begin
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
        zo_req <= 1'b0;
        zo_bus <= {BW{IV}};
      end
      "write", "read" : begin
        // parsing
        fs_i = $fscanf (fp_i, "%s %d %h ", endian, width, address);
        if (inst == "write")  fs_i = $fscanf (fp_i, "%h ", data);
        // processing
        byte_select = {SW{1'b1}};
        mask        = {DW{1'b1}};
        case (endian)
          "be"    : shift = (DW-width)/8 - (address & ~AM);
          "le"    : shift =                (address & ~AM);
          default : $display ("ERROR: Parsing error: Unsuported endianness: %0s", endian);
        endcase
        // applying signals to the bus
        hwdata <= (inst == "write") ? (data ^ mask) : {DW{IV}};
      end
      // zbus raw access
      "zbus_raw" : begin
        fs_i = $fscanf (fp_i, "%h", zo_bus);
        if (inst == "wb_raw")  raw <= 1;
      end
      // the default is an idle bus
      default  : begin
        $display ("WARNING: Parsing error: Unrecognized instruction \"%s\".", inst);
        zo_req <= 1'b0;
        zo_bus <= {BW{IV}};
      end
    endcase
  end
end

///////////////////////////////////////////////////////////////////////////////
// bus input machine                                                         //
///////////////////////////////////////////////////////////////////////////////

always @ (posedge clk)
if (zi_trn) begin
  $display (fp_o, "%h", ti_bus);
//  case (instr_r)
//    "write", "read" : begin end
//    default : begin
//      $fwrite (fp_o, " %s", hresp ? "ERROR" : "OKAY");
//    end
//  endcase
//  $fwrite (fp_o, "/n");
end


endmodule
