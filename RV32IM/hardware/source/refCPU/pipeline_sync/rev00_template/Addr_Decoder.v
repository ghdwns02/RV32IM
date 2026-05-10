`timescale 1ns/1ns

module Addr_Decoder (
    input [31:0] Addr,
    output reg CS_MEM_N,
    output reg CS_TIMER_N,
    output reg CS_TBMAN_N
);
  
 
  always @(*)
  begin
    if       (Addr[31:28] == 4'h1 || Addr[31:28] == 4'h3)  // Instruction & Data Memory
      begin
           CS_MEM_N   = 1'b0;
           CS_TIMER_N = 1'b1;
           CS_TBMAN_N = 1'b1;
      end
    
    else if  (Addr[31:12] == 20'h80001)  // Timer
      begin
           CS_MEM_N    =1'b1;
           CS_TIMER_N  =1'b0;
           CS_TBMAN_N  =1'b1;
      end

    else if  (Addr[31:12] == 20'h8000F)   // TBMAN
      begin
           CS_MEM_N    =1'b1;
           CS_TIMER_N  =1'b1;
           CS_TBMAN_N  =1'b0;
      end

    else 
      begin
           CS_MEM_N    =1'b1;
           CS_TIMER_N  =1'b1;
           CS_TBMAN_N  =1'b1;
      end
  end
  
endmodule  
