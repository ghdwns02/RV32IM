module SMU_RV32I_System (
  input         CLOCK_50,
  input   [2:0] BUTTON,
  input   [9:0] SW,
  output  [6:0] HEX3,
  output  [6:0] HEX2,
  output  [6:0] HEX1,
  output  [6:0] HEX0,
  output  [9:0] LEDR,

  output        UART_TXD,
  input         UART_RXD
);

  parameter RESET_PC     = 32'h1000_0000;
  parameter CLOCK_FREQ   = 125_000_000;
  parameter BAUD_RATE    = 115_200;
  parameter MIF_HEX      = "";
  parameter MIF_BIOS_HEX = "";
  parameter DWIDTH       = 32;
  parameter AWIDTH       = 14;

  wire reset;
  wire reset_poweron;
  reg  reset_ff;
  wire rst;
  wire rst_n;

  wire [31:0] fetch_addr;
  wire [31:0] imem_inst;
  wire [31:0] inst;
  wire [31:0] data_addr;
  wire [31:0] write_data;
  wire [3:0]  ByteEnable;
  wire [31:0] read_data;
  wire        data_we;
  wire        data_re;

  wire        cs_dmem_n;
  wire        cs_tbman_n;
  wire        cs_gpio_n;
  wire        cs_timer_n;
  wire        cs_uart_n;

  wire [31:0] read_imem_data_mem;
  wire [31:0] read_data_tbman;
  wire [31:0] read_data_gpio;
  wire [31:0] read_data_timer;
  wire [31:0] read_data_uart;

  reg        cs_dmem_n_r, cs_tbman_n_r, cs_gpio_n_r, cs_timer_n_r, cs_uart_n_r;
  reg [31:0] read_data_tbman_r, read_data_gpio_r, read_data_timer_r, read_data_uart_r;

  wire clk = CLOCK_50;

  assign reset_poweron = BUTTON[0];
  assign reset         = reset_poweron;

  always @(posedge clk)
    reset_ff <= reset;

  assign rst   = ~reset_ff;
  assign rst_n =  reset_ff;

  assign data_re = ~data_we;
  assign inst    = imem_inst;

  always @(posedge clk) begin
    cs_dmem_n_r       <= cs_dmem_n;
    cs_tbman_n_r      <= cs_tbman_n;
    cs_gpio_n_r       <= cs_gpio_n;
    cs_timer_n_r      <= cs_timer_n;
    cs_uart_n_r       <= cs_uart_n;
    read_data_tbman_r <= read_data_tbman;
    read_data_gpio_r  <= read_data_gpio;
    read_data_timer_r <= read_data_timer;
    read_data_uart_r  <= read_data_uart;
  end

  riscvpipeline #(
    .RESET_PC(RESET_PC)
  ) icpu (
    .clk       (clk),
    .n_rst     (rst_n),
    .PC        (fetch_addr),
    .Instr     (inst),
    .MemWriteM (data_we),
    .ALUResultM(data_addr),
    .BE_WD     (write_data),
    .ReadData  (read_data),
    .ByteEnable(ByteEnable)
  );

  SYNC_RAM_DP_WBE #(
    .DWIDTH  (DWIDTH),
    .AWIDTH  (AWIDTH),
    .MIF_HEX (MIF_HEX)
  ) imem (
    .clk   (clk),
    .addr0 (fetch_addr[AWIDTH+2-1:2]),
    .addr1 (data_addr[AWIDTH+2-1:2]),
    .wbe0  (4'd0),
    .wbe1  (ByteEnable),
    .d0    (32'd0),
    .d1    (write_data),
    .wen0  (1'b0),
    .wen1  (~cs_dmem_n & data_we),
    .q0    (imem_inst),
    .q1    (read_imem_data_mem)
  );

  Addr_Decoder uAddrDecoder (
    .Addr       (data_addr),
    .CS_DMEM_N  (cs_dmem_n),
    .CS_TBMAN_N (cs_tbman_n),
    .CS_GPIO_N  (cs_gpio_n),
    .CS_TIMER_N (cs_timer_n),
    .CS_UART_N  (cs_uart_n)
  );

  data_mux u_data_mux (
    .cs_dmem_n       (cs_dmem_n_r),
    .read_data_dmem  (read_imem_data_mem),

    .cs_tbman_n      (cs_tbman_n_r),
    .read_data_tbman (read_data_tbman_r),

    .cs_gpio_n       (cs_gpio_n_r),
    .read_data_gpio  (read_data_gpio_r),

    .cs_timer_n      (cs_timer_n_r),
    .read_data_timer (read_data_timer_r),

    .cs_uart_n       (cs_uart_n_r),
    .read_data_uart  (read_data_uart_r),

    .read_data       (read_data)
  );

  tbman_wrap u_tbman_wrap (
    .clk         (clk),
    .rst_n       (rst_n),

    .tbman_sel   (~cs_tbman_n),
    .tbman_write (data_we),
    .tbman_addr  (data_addr[15:0]),
    .tbman_wdata (write_data),
    .tbman_rdata (read_data_tbman)
  );

  GPIO u_GPIO (
    .clk    (clk),
    .reset  (rst),

    .CS_N   (cs_gpio_n),
    .RD_N   (~data_re),
    .WR_N   (~data_we),
    .Addr   (data_addr[11:0]),
    .DataIn (write_data),
    .DataOut(read_data_gpio),

    .BUTTON (BUTTON[2:1]),
    .SW     (SW),
    .o_HEX3 (HEX3),
    .o_HEX2 (HEX2),
    .o_HEX1 (HEX1),
    .o_HEX0 (HEX0),
    .LEDG   (LEDR),
    .Intr   ()
  );

  TimerCounter u_TimerCounter (
    .clk    (clk),
    .reset  (rst),
    .CS_N   (cs_timer_n),
    .RD_N   (~data_re),
    .WR_N   (~data_we),
    .Addr   (data_addr[11:0]),
    .DataIn (write_data),
    .DataOut(read_data_timer),
    .Intr   ()
  );

  uart_wrap #(
    .CLOCK_FREQ (CLOCK_FREQ),
    .BAUD_RATE  (BAUD_RATE)
  ) u_uart_wrap (
    .clk     (clk),
    .reset   (rst),
    .CS_N    (cs_uart_n),
    .RD_N    (~data_re),
    .WR_N    (~data_we),
    .Addr    (data_addr[11:0]),
    .DataIn  (write_data),
    .DataOut (read_data_uart),
    .uart_rx (UART_RXD),
    .uart_tx (UART_TXD)
  );

endmodule
