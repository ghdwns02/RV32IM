//
//  Author: Prof. Yongwoo Kim
//          System Semiconductor Engineering
//          Sangmyung University
//  Date: July 19, 2022
//  Description: Simple Hardware System based on RISC-V RV32I
//  This code references RVbook in Korea Univ. and EECS151 in UCB.
//
//`timescale 1ns/1ns

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
  parameter CLOCK_FREQ = 50_000_000;
  parameter BAUD_RATE = 115_200;
  parameter MIF_HEX = "";
  parameter MIF_BIOS_HEX = "";
  parameter DWIDTH = 32;
  //parameter AWIDTH = 12;
  //parameter AWIDTH = 14;
  parameter AWIDTH = 17;

  wire reset;
  wire reset_poweron;
  reg  reset_ff;
  wire [31:0] fetch_addr;
  wire [31:0] data_addr;
  wire [31:0] write_data;
  wire [3:0]  ByteEnable;
  wire [31:0] read_data;
  wire        cs_mem_n;
  wire        cs_timer_n;
  wire        cs_tbman_n;
  wire        data_we;

  wire clk = CLOCK_50;

  wire data_re;
  
  // reset =  BUTTON[0]
  // if BUTTON[0] is pressed, the reset goes down to "0"
  // reset is a low-active signal
  assign  reset_poweron = BUTTON[0];
  assign  reset = reset_poweron;

  always @(posedge clk)
    reset_ff <= reset;

    assign data_re = ~data_we;

    //peripheral---------------------------    

    wire [31:0] read_imem_data_mem;
    wire [31:0] read_data_timer;
    wire [31:0] read_data_tbman;

    wire [31:0] imem_inst;
    wire [31:0] inst = imem_inst;

    wire rst_n = reset_ff;
    wire rst = ~reset_ff;

    //---------------------------------------
    //CPU
    //---------------------------------------

    rv32i_cpu #(
      .RESET_PC(RESET_PC)
    ) icpu (
        .clk          (clk), 
        .reset        (rst),
        .pc          (fetch_addr),
        .inst        (inst),
        .MemWrite       (data_we),  // data_we: active high
        .MemAddr    (data_addr), 
        .MemWData      (write_data),
        .ByteEnable      (ByteEnable),
        .MemRData      (read_data)
    );

    //---------------------------------------
    //memory
    //---------------------------------------

`ifdef FPGA
    dualport_mem_synch_rw_dualclk #(
      .DATA_WIDTH(DWIDTH),
        .ADDRESS_WIDTH(AWIDTH),
        .MIF_HEX (MIF_HEX)
    )imem (
      .clk1(clk),
        .clk2(clk),
        .addr1(fetch_addr[AWIDTH+2-1:2]),
        .addr2(data_addr[AWIDTH+2-1:2]),
        .be1(4'd0),
        .be2(ByteEnable),
        .data_in1(32'd0),
        .data_in2(write_data),
        .we1(1'b0),
        .we2(data_we & ~cs_mem_n),
        .data_out1(imem_inst),
        .data_out2(read_imem_data_mem)
    );  

`else

    ASYNC_RAM_DP_WBE #(
      .DWIDTH (DWIDTH),
      .AWIDTH (AWIDTH),
      .MIF_HEX (MIF_HEX)
    ) imem (
        .clk      (clk),
        .addr0    (fetch_addr[AWIDTH+2-1:2]),
        .addr1    (data_addr[AWIDTH+2-1:2]),
        .wbe0     (4'd0),
        .wbe1     (ByteEnable),
        .d0       (32'd0),
        .d1       (write_data),
        .wen0     (1'b0),
        .wen1     (data_we & ~cs_mem_n),//~cs_mem_n &
        .q0       (imem_inst),
        .q1       (read_imem_data_mem)
    );

`endif

    //---------------------------------------
    //data_mux
    //---------------------------------------

    data_mux u_data_mux (
`ifdef FPGA
        .clk(clk),
`endif

        //MEM
        .read_data_mem(read_imem_data_mem),

        //Timer
        .cs_timer_n(cs_timer_n),
        .read_data_timer(read_data_timer),
    
        //TBMAN
        .cs_tbman_n(cs_tbman_n),
        .read_data_tbman(read_data_tbman),

        .read_data(read_data)
    );

    //---------------------------------------
    //Addr_Decoder
    //---------------------------------------
    Addr_Decoder iDecoder (
        .Addr        (data_addr),
        .CS_MEM_N    (cs_mem_n) ,
        .CS_TIMER_N  (cs_timer_n),
        .CS_TBMAN_N  (cs_tbman_n)
    );

    //---------------------------------------
    //Timer
    //---------------------------------------
    TimerCounter iTimer (
        .clk     (clk),
        .reset   (rst),
        .CS_N    (cs_timer_n),
        .RD_N    (~data_re),
        .WR_N    (~data_we),
        .Addr    (data_addr[11:0]),
        .DataIn  (write_data),
        .DataOut (read_data_timer),
        .Intr    ()
    );

  //---------------------------------------
  //TBMAN
  //---------------------------------------
      tbman_wrap u_tbman_wrap (
      .clk            (clk),
      .rst_n          (rst_n),

      .tbman_sel      (~cs_tbman_n),  // High Active
      .tbman_write    (data_we), // Write : 1, Read : 0
      .tbman_addr     (data_addr[15:0]),
      .tbman_wdata    (write_data),
      .tbman_rdata    (read_data_tbman)
    );

endmodule
