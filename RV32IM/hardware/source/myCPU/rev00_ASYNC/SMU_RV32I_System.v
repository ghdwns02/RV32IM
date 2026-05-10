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

  parameter RESET_PC = 32'h1000_0000;
  parameter CLOCK_FREQ = 125_000_000;
  parameter BAUD_RATE = 115_200;
  parameter MIF_HEX = "";
  parameter MIF_BIOS_HEX = "";
  parameter DWIDTH = 32;
  parameter AWIDTH = 17;

  wire [31:0] PC, Instr;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  wire [31:0] ReadData;

  wire reset;
  wire reset_poweron;
  reg  reset_ff;

  wire [31:0] data_addr;
  wire [31:0] write_data;
  wire [3:0]  ByteEnable;
  wire  [31:0] read_data;
  wire        cs_mem_n;
  wire        cs_timer_n;
  wire        cs_gpio_n;
  wire        cs_uart_n;
  wire        data_we;
  wire        MemWriteM;
  wire [31:0] read_data_tbman, read_data_timer;

  wire cs_tbman_n;

  wire clk = CLOCK_50;
  wire clkb;

  wire data_re;

  assign  reset_poweron = BUTTON[0];
  assign  reset = reset_poweron;

  always @(posedge clk)
    reset_ff <= reset;

  assign clkb = ~clk;

  wire n_rst = reset_ff;

  riscvpipeline #(
      .RESET_PC(RESET_PC)
    ) icpu (
    .clk(clk),
    .n_rst(n_rst),
    .PC(PC),
    .Instr(Instr),
    .MemWriteM(MemWriteM),
    .ALUResultM(DataAdr),
    .BE_WD(WriteData),
    .ReadData(read_data),
    .ByteEnable(ByteEnable)
  );

    ASYNC_RAM_DP_WBE #(
        .DWIDTH (DWIDTH),
        .AWIDTH (AWIDTH),
        .MIF_HEX (MIF_HEX)
    ) imem (
      .clk      (clk),
      .addr0    (PC[AWIDTH+2-1:2]),
      .addr1    (DataAdr[AWIDTH+2-1:2]),
      .wbe0     (4'd0),
      .wbe1     (ByteEnable),
      .d0       (32'd0),
      .d1       (WriteData),
      .wen0     (1'b0),
      .wen1     (~cs_mem_n & MemWriteM),
      .q0       (Instr),
      .q1       (ReadData)
    );

    Addr_Decoder Address_Decoder(
      .Addr(DataAdr),
      .CS_MEM_N(cs_mem_n),
      .CS_TIMER_N(cs_timer_n),
      .CS_TBMAN_N(cs_tbman_n)
    );

    tbman_wrap TBMAN_Wrapper (
        .clk        (clk),
        .rst_n      (n_rst),

        .tbman_sel     (~cs_tbman_n),
        .tbman_write   (MemWriteM),
        .tbman_addr    (DataAdr[15:0]),
        .tbman_wdata   (WriteData),
        .tbman_rdata   (read_data_tbman)
    );

    data_mux Data_Multiplexer(

      .read_data_mem(ReadData),
      .cs_timer_n(cs_timer_n),
      .read_data_timer(read_data_timer),
      .cs_tbman_n(cs_tbman_n),
      .read_data_tbman(read_data_tbman),
      .read_data(read_data)
    );

    TimerCounter u_TimerCounter (
      .clk(clk),
      .reset(!n_rst),
      .CS_N(cs_timer_n),
      .RD_N(MemWriteM),
      .WR_N(~MemWriteM),
      .Addr(DataAdr[11:0]),
      .DataIn(WriteData),
      .DataOut(read_data_timer),
      .Intr()
    );

endmodule
