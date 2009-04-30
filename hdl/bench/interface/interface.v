//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  general purpuse verilog <-> software interface                          //
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

module interface #(
  // bus parameters
  parameter NO  = 8,       // number of output signals
  parameter NI  = 8,       // number of input  signals
  // software interface parameters
  parameter FNO = "",      // file name for output signals (read  file)
  parameter FNI = "",      // file name for input  signals (write file)
  parameter DT  = "hex",   // data type ("hex" (default), "bin", "raw")
  // presentation
  parameter NAME = "noname",
  parameter AUTO = 0
)(
  input  wire          c,  // clock
  output reg  [NO-1:0] o,  // output signals
  input  wire [NI-1:0] i   // input  signals
);

//////////////////////////////////////////////////////////////////////////////
// local parameters and signals                                             //
//////////////////////////////////////////////////////////////////////////////

// master status
reg     run = 0;   // master running status

// file pointer and access status
integer fpi, fsi = 0;  // write file
integer fpo, fso = 0;  // read  file

// program file parsing variables
reg [3*8-1:0] cmd;

reg [18*8-1:0] t;
reg [7:0] ch;
integer cnt;
integer cnt_str;

///////////////////////////////////////////////////////////////////////////////
// initialization                                                            //
///////////////////////////////////////////////////////////////////////////////

initial begin
  $display ("DEBUG: Starting master");
  if (AUTO)  start (FNO, FNI);
end

task start (
  input reg [256*8-1:0] fno,
  input reg [256*8-1:0] fni
); begin
  // open file for output signals (read)  file
  $display ("DEBUG: Opening output signals (read)  file: \"%0s\"", fno);
  fpo = $fopen (fno, "r");
  if (fpo)  $display ("DEBUG: File open SUCESS");
  else      $display ("DEBUG: File open FAIL");
  // open file for input  signals (write) file
  $display ("DEBUG: Opening input  signals (write) file: \"%0s\"", fni);
  fpi = $fopen (fni, "w");
  if (fpi)  $display ("DEBUG: File open SUCESS");
  else      $display ("DEBUG: File open FAIL");

  for (cnt=0; cnt<8; cnt=cnt+1) begin
    //interface_o;
    //interface_i;
    for (cnt_str=0; cnt_str<8; cnt_str=cnt_str+1) begin
      ch = $fgetc (fpo);
      $display("%s", ch);
    end
    $fwrite (fpi, "test message");
    @ (posedge c);
  end
  $finish();
//  interface_o;
//  interface_i;

//  run = 1;
end endtask

task stop; begin
  run = 0;
end endtask

///////////////////////////////////////////////////////////////////////////////
// implementation                                                            //
///////////////////////////////////////////////////////////////////////////////

//always @ (posedge c)
//if (run) begin
//  interface_o;
//  interface_i;
//end

task interface_i; begin
  //$fdisplay       (fpi, "%h", i);
  //$fwrite         (fpi, "%h \n \n", i);
  $fwrite         (fpi, "test message");
  $display ("interface:i %h", i);
end endtask

task interface_o; begin
  fso = 0;
  while (fso == 0) begin
    fso = $fscanf (fpo, "%h", o);
    //$write ("%d", fso);
    //$display ("DEBUG: Opening input  signals (write) file: \"%0d\"", fso);
  end
  $display ("interface:o %h", o);
end endtask

endmodule

// read the first output values
//  for (j=0; j<18; j=j+1) begin
//    ch = $fgetc(fpo);
//    $write ("\'%s\'", ch);
//  end
//  $display ("end of string");
//  fso = $fread   (fpo, "%s", t);
//  $display ("interface:o %s", t);

