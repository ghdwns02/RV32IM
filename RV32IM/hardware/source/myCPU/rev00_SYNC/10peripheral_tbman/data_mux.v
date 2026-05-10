
`timescale 1ns/1ps

module data_mux (
    // DATA MEM
    input           cs_dmem_n,
    input    [31:0]	read_data_dmem,

    // TBMAN
    input           cs_tbman_n,
    input    [31:0] read_data_tbman,

    // GPIO
    input           cs_gpio_n,
    input    [31:0] read_data_gpio,

    // TIMER
    input           cs_timer_n,
    input    [31:0] read_data_timer,

    // UART
    input           cs_uart_n,
    input    [31:0] read_data_uart,

    output reg [31:0] read_data 
);

`protect128
    always @(*)
    begin
        if      (~cs_tbman_n) read_data = read_data_tbman;
        else if (~cs_dmem_n)  read_data = read_data_dmem;
        else if (~cs_gpio_n)  read_data = read_data_gpio;
        else if (~cs_timer_n) read_data = read_data_timer;
        else if (~cs_uart_n)  read_data = read_data_uart;
        else            	  read_data = 32'd0;
    end
`endprotect128

endmodule  
