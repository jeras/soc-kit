`timescale 1ns/1ns

module sdram_tb ();

// system signals
reg        CLOCK_50;
reg  [0:0] SW;
wire [1:0] LEDG;
wire [0:0] LEDR;
// SDRAM signals
wire [11:0] DRAM_ADDR;
wire        DRAM_BA_0;
wire        DRAM_BA_1;
wire        DRAM_CAS_N;
wire        DRAM_CKE;
wire        DRAM_CLK;
wire        DRAM_CS_N;
wire [15:0] DRAM_DQ;
wire        DRAM_LDQM;
wire        DRAM_UDQM;
wire        DRAM_RAS_N;
wire        DRAM_WE_N;

// request for a dumpfile
initial begin
  $dumpfile("test.lt2");
  $dumpvars(0, sdram_tb);
end

// clock
initial    CLOCK_50 = 1;
always #10 CLOCK_50 = ~CLOCK_50;

// reset
initial begin
  SW = 1;
  repeat (4) @ (posedge CLOCK_50);
  SW = 0;
  repeat (4) @ (posedge CLOCK_50);
  SW = 1;
  repeat (9999999) @ (posedge CLOCK_50);
  $finish();
end

sdram sdram_soc (
// system signals
  .CLOCK_50    (CLOCK_50  ),
  .SW          (SW        ),
  .LEDG        (LEDG      ),
  .LEDR        (LEDR      ),
// SDRAM signals
  .DRAM_ADDR   (DRAM_ADDR ),
  .DRAM_BA_0   (DRAM_BA_0 ),
  .DRAM_BA_1   (DRAM_BA_1 ),
  .DRAM_CAS_N  (DRAM_CAS_N),
  .DRAM_CKE    (DRAM_CKE  ),
  .DRAM_CLK    (DRAM_CLK  ),
  .DRAM_CS_N   (DRAM_CS_N ),
  .DRAM_DQ     (DRAM_DQ   ),
  .DRAM_LDQM   (DRAM_LDQM ),
  .DRAM_UDQM   (DRAM_UDQM ),
  .DRAM_RAS_N  (DRAM_RAS_N),
  .DRAM_WE_N   (DRAM_WE_N )
);

mt48lc4m16a2 mt48lc4m16a2 (
  .Dq     (DRAM_DQ   ),
  .Addr   (DRAM_ADDR ),
  .Ba     ({DRAM_BA_1, DRAM_BA_0}),
  .Clk    (DRAM_CLK  ),
  .Cke    (DRAM_CKE  ),
  .Cs_n   (DRAM_CS_N ),
  .Ras_n  (DRAM_RAS_N),
  .Cas_n  (DRAM_CAS_N),
  .We_n   (DRAM_WE_N ),
  .Dqm    ({DRAM_UDQM, DRAM_LDQM})
);

endmodule


module pll (
  input  wire areset,
  input  wire inclk0,
  output reg  c0,
  output reg  c1,
  output reg  c2,
  output reg  locked
);

reg clk;
initial                 clk = 1'b0;
always  #(1000.0/133.0) clk = ~clk;

// clock 0
always @(*) c0 = #3 clk;
// clock 1
always @(*) c1 = inclk0;
// clock 2
always @(*) c2 =    clk;

// reset
initial begin
  locked = 0;
  repeat (100) @ (posedge inclk0);
  locked = 1;
end

endmodule
