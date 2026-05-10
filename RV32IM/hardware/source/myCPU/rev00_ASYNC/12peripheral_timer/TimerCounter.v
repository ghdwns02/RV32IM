`timescale 1ns/1ns

module TimerCounter(
  input clk,
  input reset,
  input CS_N,
  input RD_N,
  input WR_N,
  input [11:0] Addr,
  input [31:0] DataIn,
  output reg [31:0] DataOut,
  output Intr);

  reg [31:0] CompareR;
  reg [31:0] CounterR;
  reg [31:0] StatusR;

  always @(posedge clk)
  begin
    if(reset)
          CompareR <=32'hFFFF_FFFF;

    else if(~CS_N && ~WR_N && (Addr[11:0]==12'h000))
          CompareR <= DataIn;

  end

  always @(posedge clk)
  begin
    if (reset)
         StatusR <= 32'b0;

    else if (CompareR == CounterR)
         StatusR[0] <= 1'b1;

    else if (~CS_N && ~RD_N && Addr[11:0] == 12'h200)
         StatusR[0] <= 1'b0;

  end

  assign  Intr = ~StatusR[0];

  always @(posedge clk)
  begin
    if(reset | StatusR[0])   CounterR <= 32'b0;
    else                      CounterR <= CounterR + 32'b1;
  end

  always @(*)
  begin
    if(~CS_N && ~RD_N)
    begin
      if      (Addr[11:0] == 12'h000) DataOut = CompareR;
      else if (Addr[11:0] == 12'h100) DataOut = CounterR;
      else if (Addr[11:0] == 12'h200) DataOut = StatusR;
      else                            DataOut = 32'b0;
     end
     else                             DataOut = 32'b0;
  end

endmodule
