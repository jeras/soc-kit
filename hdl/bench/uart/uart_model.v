//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  UART interface model                                                    //
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

module uart_model #(
  parameter DW     = 8,          // data width (sizes from 5 to 8 bits are supported)
  parameter SW     = 1,          // stop width (one or more stop bits are supported)
  parameter PARITY = "NONE",     // parity ("NONE" , "EVEN", "ODD")
  parameter BAUD   = 112.200,    // baud rate
  // data streams
  parameter FILE_I = "",         // program filename
  parameter FILE_O = "",         // program filename
  // presentation
  parameter NAME   = "noname",
  parameter AUTO   = 0
)(
//  output reg  DTR,  // Data Terminal Ready
//  output reg  DSR,  // Data Set Ready
//  output reg  RTS,  // Request To Send
//  output reg  CTS,  // Clear To Send
//  output reg  DCD,  // Carrier Detect
//  output reg  RI,   // Ring Indicator
  output reg  TxD,  // Transmitted Data
  input  wire RxD   // Received Data
);

///////////////////////////////////////////////////////////////////////////////
// internal signals                                                          //
///////////////////////////////////////////////////////////////////////////////

// running status
reg run;

//            transmitter, receiver   ;
integer       fp_tx , fp_rx ;
integer       fs_tx , fs_rx ;
integer       cnt_tx, cnt_rx;
integer       bit_tx, bit_rx;
reg [DW-1:0]  c_tx  , c_rx  ;  // transferred character

///////////////////////////////////////////////////////////////////////////////
// file handler                                                              //
///////////////////////////////////////////////////////////////////////////////

// automatic initialization if enabled
initial begin
  $display ("DEBUG: Starting master");
  TxD = 1'b1;
  if (AUTO)  start (FILE_I, FILE_O);
end

// start UART model
task start (
  input reg [256*8-1:0] filename_tx,
  input reg [256*8-1:0] filename_rx
); begin
  // transmit initialization
  cnt_tx = 0;
  if (filename_tx != "") begin
    fp_tx = $fopen (filename_tx, "r");
    $display ("DEBUG: Opening write file for input stream \"%0s\".", filename_tx);
  end
  // receive initialization
  cnt_rx = 0;
  if (filename_rx != "") begin
    fp_rx = $fopen (filename_rx, "w");
    $display ("DEBUG: Opening read file for output stream \"%0s\".", filename_rx);
  end
  run = 1;
end endtask

// stop UART model
task stop; begin
  run = 0;
  $fclose (fp_tx);
  $fclose (fp_rx);
end endtask

///////////////////////////////////////////////////////////////////////////////
// receive and transmitt handlers                                             //
///////////////////////////////////////////////////////////////////////////////

// transmitter
initial begin
  #50;
  while (run) begin
    c_tx = $fgetc(fp_tx);
    // start bit
    TxD = 1'b0;
    #10;
    // transmit bits LSB first
    for (bit_tx=0; bit_tx<DW; bit_tx=bit_tx+1) begin
      //{c_tx [DW-2:0], TxD} = c_tx;
      TxD = c_tx [bit_tx];
      #10;
    end
    // send parity
    case (PARITY)
      "ODD"  : begin  TxD = ~^c_tx; #10;  end
      "EVEN" : begin  TxD =  ^c_tx; #10;  end
      "NONE" : begin                        end
    endcase
    // increment counter
    cnt_tx = cnt_tx + 1;
    // stop bits
    for (bit_tx=DW; bit_tx<DW+SW; bit_tx=bit_tx+1) begin
      TxD = 1'b1;
      #10;
    end
  end
end

// receiver
initial begin
  while (run) begin
    @ (negedge RxD) begin
      // skip start bit
      #5;
      // sample in the middle of each bit
      for (bit_rx=0; bit_rx<DW; bit_rx=bit_rx+1) begin
        #10;
        //c_rx = {c_rx [DW-2:0], RxD};
        c_rx [bit_rx] = RxD;
      end
      // check parity
      case (PARITY)
        "ODD"  : begin  #10; if (RxD != ~^c_rx)  $display ("DEBUG: parity error.");  end
        "EVEN" : begin  #10; if (RxD !=  ^c_rx)  $display ("DEBUG: parity error.");  end
        "NONE" : begin                                                                 end
      endcase
      // increment counter
      cnt_rx = cnt_rx + 1;
      // skip the stop bit
      $fwrite (fp_rx, "%s", c_rx);
    end
  end
end


endmodule
