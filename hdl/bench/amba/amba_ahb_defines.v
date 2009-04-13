//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  AMBA AHB constant definitions                                           //
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

// AMBA AHB version
//`define AMBA_AHB_VER_2   // version 2 is partially supported (no arbitration)
`define AMBA_AHB_VER_3   // version 3 is supported

// AHB bus parameters
`define AW 32            // address bus width
`define DW 32            // data bus width
`ifdef AMBA_AHB_VER_3
`define RW 1             // response signal width
`elsif AMBA_AHB_VER_2
`define RW 2             // response signal width
`endif
`define DE "BIG"         // endianness ("BIG" or "LITTLE")

// HWRITE      Transfer direction
`define H_READ       1'b0
`define H_WRITE      1'b1

// HTRAN[1:0]  Transfer Type
`define H_IDLE       2'b00   // Indicates that no data transfer is required
`define H_BUSY       2'b01   // The BUSY transfer type enables masters to insert idle cycles in the middle of a burst
`define H_NONSEQ     2'b10   // Indicates a single transfer or the first transfer of a burst
`define H_SEQ        2'b11   // The remaining transfers in a burst are SEQUENTIAL

// HSIZE[2:0]  Transfer Size
`define H_SIZE_8     3'b000
`define H_SIZE_16    3'b001
`define H_SIZE_32    3'b010
`define H_SIZE_64    3'b011
`define H_SIZE_128   3'b100
`define H_SIZE_256   3'b101
`define H_SIZE_512   3'b110
`define H_SIZE_1024  3'b111

// HBURST[2:0] Burst Type
`define H_SINGLE     3'b000  // Single burst
`define H_INCR       3'b001  // Incrementing burst of undefined length
`define H_WRAP4      3'b010  // 4-beat wrapping burst
`define H_INCR4      3'b011  // 4-beat incrementing burst
`define H_WRAP8      3'b100  // 8-beat wrapping burst
`define H_INCR8      3'b101  // 8-beat incrementing burst
`define H_WRAP16     3'b110  // 16-beat wrapping burst
`define H_INCR16     3'b111  // 16-beat incrementing burst

// HRESP       Transfer Response
`ifdef AMBA_AHB_VER_3
`define H_OKAY    1'b0       //
`define H_ERROR   1'b1       //
`elsif AMBA_AHB_VER_2
`define H_OKAY    2'b00
`define H_ERROR   2'b01
`endif
`define H_RETRY   2'b10      //
`define H_SPLIT   2'b11      //

