//
//  Author: Prof. Yongwoo Kim
//          System Semiconductor Engineering
//          Sangmyung University
//  Date: July 19, 2022
//  Revision: Jan. 26, 2023
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
  parameter CLOCK_FREQ = 125_000_000;
  parameter BAUD_RATE = 115_200;
  parameter MIF_HEX = "";
  parameter MIF_BIOS_HEX = "";
  parameter DWIDTH = 32;
  parameter AWIDTH = 16;

  wire reset;
  wire reset_poweron;
  reg  reset_ff;

  wire [31:0] fetch_addr;
  wire [31:0] imem_inst;
  wire [31:0] inst;
  wire [31:0] data_addr;
  wire [31:0] write_data;
  wire [3:0]  ByteEnable;
  wire  [31:0] read_data;
  wire        data_we;
  wire        data_re;

  // Address Mux Signal
  wire        cs_dmem_n;
  wire        cs_tbman_n;

  // Data Mux Signal
  wire [31:0] read_imem_data_mem;
  wire [31:0] read_data_tbman;

  wire clk = CLOCK_50;
  wire clkb;
  
  // reset =  BUTTON[0]
  // if BUTTON[0] is pressed, the reset goes down to "0"
  // reset is a low-active signal

  assign  reset_poweron = BUTTON[0];
  assign  reset = reset_poweron;

  // reset_ff is a low-active signal
  always @(posedge clk)
    reset_ff <= reset;

  assign clkb = ~clk;

  assign data_re = ~data_we;
  
  assign inst = imem_inst;

  rv32i_cpu #(
      .RESET_PC(RESET_PC)
  ) icpu (
    .clk			  (clk), 
    .clkb       (clkb),
    .reset		  (~reset_ff),
    .pc			    (fetch_addr),
    .inst		  	(inst),
    .MemWrite   (data_we),  // data_we: active high
    .MemAddr		(data_addr), 
    .MemWData	  (write_data),
    .ByteEnable	(ByteEnable),
    .MemRData	  (read_data)
  );

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
    .wen1     (data_we & ~cs_dmem_n),
    .q0       (imem_inst),
    .q1       (read_imem_data_mem)
  );

// Put your code
`protected128
PH'=:YO:50,4.;<LSK^VZER>IUJ=35T[)W1AS@X6M(9K0T+S !P>HJOM@]]6JW$ O
PB#7VL51_BC*J2XFV_DF/BB%%1U1'"VYX"CSYU&S%ZTEEKY!5"P9G+U&&1M6Y,?["
P1=%K.LF.((-1GL=9>'I.VR0.4/^7L_I)?S)!V?'6 "%W\$P61W7GK)B>,[)_RB;R
P:W7@5P=NB2522>=Y[='IM(!XMGC;-UL&5F2?P9>K9;XMG/6,GKC8'%<-N8/"D9(@
P+4'-D-'YZS.OO )%?F>?>])B"=T<4OQ1@@X'^W7\W3SH+R4WK,9"'8688B=VHX*+
PQ",3/!&ZR-4W7Z\TP)6=:&O7F5<W#1@V/_:.2V%-Q#_JOE*8P#*,DQN,-,)3?;P.
P>*L<]21$E'/&=X2O1?7T)8KH06CY*\"KC?4Z0MDOD;VA6*  5Q,S1]>2AWF*2I9]
P!]G'SVEH9F=(WO)7_11.-SJZN3QJRR.H;R="/UBZI&:[ZPCA!4DY(/MYNL%7RY*V
P,#-]N*(.F81<]4'06I=K':D__&>!Y\A:?E5X7[FL)7'#H0\E*KSZ;.5MT B>Q 78
PW(3:C2EE1B$2#U)!F\J@,3UI2V;(?9(C!,2?]" 5?U^E"^@*+76C\M3]CR--_]G<
P$"\LCBR5PX^V):E(04K=;][72PPZ>SZ"U;6)[D#/GVWIQZZ/TWTBX532R]-A+\P@
P^UL?1EA%.WHJ#=4>_;QLZKT8:F'4%7Y?!X??F/0B<* %: UG4P\GO%P.!]\:VC(K
P^E^/]?6]-,J&(LV!W-,%N6C:+XCA?KCV0R%(#U#M][4T4=HVR]OK2W6?%MI!U_:F
PGGTDJ.>H0;DJF.J,H11&&Y+)84U!"0Y9Y[.KY_5^X:H^/0A)*^#VM4"12#R:\/MY
PPC,G0-WCZ;.4+>>99/C?LSB_T,3938T=6 N0L,>%V/X (7YBDT-WC),M@=V!. B0
P_[GA(8<?%<?=%"*4AUPC*Q2S8\T)"4DK+"[ZJ/HU%ON,XYPL2&$_Q&L.K\,SST8=
`endprotected128


endmodule
