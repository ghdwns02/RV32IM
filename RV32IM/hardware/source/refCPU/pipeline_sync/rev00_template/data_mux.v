`timescale 1ns/1ns

module data_mux (
`ifdef FPGA
    input clk,
`endif

    //MEM
    input [31:0]	read_data_mem,

    //Timer
    input cs_timer_n,
    input [31:0] read_data_timer,
        
    //TBMAN
    input cs_tbman_n,
    input [31:0] read_data_tbman,

    output reg [31:0] read_data 
);

 `ifdef FPGA 

    reg [31:0] read_data_timer_1d;
    reg [31:0] read_data_tbman_1d;

    reg  cs_timer_n_1d;
    reg  cs_tbman_n_1d;
    
    //------------------------
    //Timer
    //------------------------

    always @(posedge clk)
    begin 
        cs_timer_n_1d <= cs_timer_n;
    end

    always @(posedge clk)
    begin 
        read_data_timer_1d <= read_data_timer;
    end

    //------------------------
    //TBMAN
    //------------------------

    always @(posedge clk)
    begin 
        cs_tbman_n_1d <= cs_tbman_n;
    end

    always @(posedge clk)
    begin 
        read_data_tbman_1d <= read_data_tbman;
    end

`endif


`ifdef FPGA
    always @(*)
    begin
        if      (~cs_timer_n_1d) 	read_data = read_data_timer_1d;
        else if (~cs_tbman_n_1d) 	read_data = read_data_tbman_1d;
       else            				read_data = read_data_mem;
     end

`else // ASYNC MEM

  always @(*)
    begin
        if          (~cs_timer_n) 	read_data = read_data_timer;
        else if     (~cs_tbman_n) 	read_data = read_data_tbman;
       else            	            read_data = read_data_mem;
     end
`endif
 
endmodule