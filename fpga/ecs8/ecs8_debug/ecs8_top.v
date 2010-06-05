module ecs8_top (
  // system clock (32.768MHz)
  input wire         clk,
  // EPCS SPI Flash interface
  output wire        epcs_asd,
  output wire        epcs_cs_n,
  // PIO
  input  wire  [1:0] button,
  input  wire  [1:0] switch.
  output wire  [1:0] led_n,
  input  wire        rtc_irq_n,
  // 1-wire
  inout  wire        onewire,
  // I2C
  inout  wire        i2c_scl,
  inout  wire        i2c_sda,
  // UART user
  input  wire        uart_user_rx,
  output wire        uart_user_tx,
  // UART host (can be used as a GPIO)
  inout  wire        uart_host_rx,
  inout  wire        uart_host_rts,
  inout  wire        uart_host_tx,
  inout  wire        uart_host_cts,
  // Flash and Ethernet (shared IO)
  output wire [26:1] shared_a,
  output wire [31:0] shared_d,
  // Flash
  output wire        flash_ce_n,
  output wire        flash_oe_n,
  output wire        flash_oe_n,
  output wire        flash_reset_n,
  output wire        flash_wp_n,
  input  wire        flash_ry_by_n,
  // Ethernet
  output wire        enet_wr_n,
  output wire        enet_rd_n,
  output wire        enet_res,
  output wire  [3:0] enet_be_n,
  input  wire        enet_intr,
  // DDR SDRAM
  output wire        ddr_ck_p,
  output wire        ddr_ck_n,
  output wire        ddr_cke,
  output wire        ddr_cs_n,
  output wire        ddr_we_n,
  output wire        ddr_ras_n,
  output wire        ddr_cas_n,
  output wire  [1:0] ddr_ba,
  output wire [12:0] ddr_a,
  output wire  [1:0] ddr_dm,
  inout  wire  [1:0] ddr_dqs,
  inout  wire [15:0] ddr_dq
)



endmodule
