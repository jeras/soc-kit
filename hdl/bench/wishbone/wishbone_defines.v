//`timescale  1ns / 1ps

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
