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

module zbus #(
  // essential bus parameters
  parameter ZON    = 1,         // number of zbus output busses
  parameter ZOW    = ZON*32,    // sum of all zbus output bus widths
  parameter ZIN    = 1,         // number of zbus input busses
  parameter ZIW    = ZIN*32,    // sum of all zbus output bus widths
  // simulation behaviour parameters
  parameter IDLE   = 1'bx,       // bus idle state
  // input file (program), output file (read data)
  parameter ZO_FILE = "",        // output interface filename (program)
  parameter ZI_FILE = "",        // inptu interface  filename (received data)
  // presentation
  parameter NAME   = "noname",
  parameter AUTO   = 0
)(
  // system signals
  input  wire           clk,
  input  wire           rst,
  // output interface
  output reg  [ZON-1:0] zo_req,   // transfer request
  output reg  [ZOW-1:0] zo_bus,   // payload
  input  wire [ZON-1:0] zo_ack,   // transfer acknowledge (bus ready)
  // input interface
  input  wire [ZIN-1:0] zi_req,   // transfer request
  input  wire [ZIW-1:0] zi_bus,   // payload
  output wire [ZIN-1:0] zi_ack    // transfer acknowledge (bus ready)
);

//////////////////////////////////////////////////////////////////////////////
// local parameters and signals                                             //
//////////////////////////////////////////////////////////////////////////////

// bus transfer and bus readr signals
wire [ZON-1:0] zo_trn, zo_rdy;
wire [ZIN-1:0] zi_trn, zi_rdy;

// master status
reg     run = 0;   // master running status

// file pointer and access status
integer fp_zo, fs_zo = 0; // program input
integer fp_zi, fs_zi = 0; // read output

// program file parsing variables
reg [  3*8-1:0] inst;
//reg [128*8-1:0] text;
//reg       [7:0] c;

///////////////////////////////////////////////////////////////////////////////
// initialization and on request tasks                                       //
///////////////////////////////////////////////////////////////////////////////

initial begin
  $display ("DEBUG: Starting master");
  if (AUTO)  start (ZO_FILE, ZI_FILE);
end

task start (
  input reg [256*8-1:0] zo_file,
  input reg [256*8-1:0] zi_file
); begin
  if (zo_file != "") begin
    fp_zo = $fopen (zo_file, "r");
    $display ("DEBUG: Opening zbus output port file %0s", zo_file);
  end else begin
    $display ("ERROR: No zbus output port file specified!");
    $finish;
  end
  if (zi_file != "") begin
    fp_zi = $fopen (zi_file, "w");
    $display ("DEBUG: Opening zbus input port file %0s", zi_file);
  end else begin
    $display ("DEBUG: No zbus input port file specified!");
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

// bus ready for a new request
assign zo_rdy = ~zo_req | zo_trn;
assign zi_rdy = ~zi_req | zi_trn;

assign zi_ack = 1'b1;

///////////////////////////////////////////////////////////////////////////////
// bus otput machine                                                         //
///////////////////////////////////////////////////////////////////////////////

always @ (posedge clk, posedge rst)
if (rst) begin
  // set the bus into an idle state
  zo_req <= 1'b0;
  zo_bus <= {ZOW{IDLE}};
end else if (run) begin
  if (zo_rdy) begin
    // wait for a ne line in the file and skip comment lines
    fs_zo = 0;
    while (fs_zo == 0) begin
      fs_zo = $fscanf (fp_zo, "%s ", inst);
      if (inst == "#") begin
        while ($fgetc(fp_zo) != "\n") begin end
        fs_zo = 0;
      end
    end
    // TODO
    $display ("DEBUG: instruction: %s", inst);
    // instruction decoder
    case (inst)
      // zbus request
      "req" : begin
        zo_req <= 1'b1;
        fs_zo = $fscanf (fp_zo, "%h\n", zo_bus);
      end
      // zbus idle
      "idl" : begin
        zo_req <= 1'b0;
        zo_bus <= {ZOW{IDLE}};
      end
      // system instructions
      "fin" : begin
        $fclose (fp_zo);
        $fflush (fp_zi);
        $fclose (fp_zi);
        $finish;
      end
      // the default is an idle bus
      default  : begin
        $display ("WARNING: Parsing error: Unrecognized instruction \"%s\".", inst);
        zo_req <= 1'b0;
        zo_bus <= {ZOW{IDLE}};
      end
    endcase
  end
end

///////////////////////////////////////////////////////////////////////////////
// bus input machine                                                         //
///////////////////////////////////////////////////////////////////////////////

always @ (posedge clk)
if (zi_trn) begin
  $display ("there is an ZI transfer");
  $fdisplay (fp_zi, "%h", zi_bus);
end


endmodule
