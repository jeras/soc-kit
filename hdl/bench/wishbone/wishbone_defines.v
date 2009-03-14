//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  WISHBONE bus interface definitions                                      //
//                                                                          //
//  Copyright (C) 2008/2009  Iztok Jeras                                    //
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

// Wishbone bus parameters
`define WB_AW 32            // address bus width
`define WB_DW 32            // data bus width
`define WB_DE "BIG"         // endianness

// we - 'write enable' signal options
`define WB_READ    1'b0
`define WB_WRITE   1'b1

// cti - 'cycle type identifier' signal options
`define WB_CLASSIC_SINGLE   3'b000
`define WB_CONST_ADR_BURST  3'b001
`define WB_INCR_ADR_BURST   3'b010
`define WB_END_OF_BURST     3'b111

// bte - 'burst type extension' signal options
`define WB_LINEAR  2'b00
`define WB_WRAP4   2'b01
`define WB_WRAP8   2'b10
`define WB_WRAP16  2'b11
