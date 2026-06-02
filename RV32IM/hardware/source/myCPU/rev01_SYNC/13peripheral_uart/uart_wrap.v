module uart_wrap (
    input clk,
    input reset,

    input CS_N,
    input RD_N,
    input WR_N,
    input [11:0] Addr,
    input [31:0] DataIn,
    output [31:0] DataOut,

    input uart_rx,
    output uart_tx 
);

    parameter CLOCK_FREQ = 125_000_000;

`ifdef FPGA
    parameter BAUD_RATE = 19_200;
`else
    parameter BAUD_RATE = 1_000_000;
`endif

    wire [7:0] data_in;
    wire data_in_valid;
    wire  data_in_ready;

    wire  [7:0] data_out;
    wire  data_out_valid;
    wire  data_out_ready;

    wire wen = ~CS_N & ~WR_N;
    wire ren = ~CS_N & ~RD_N;

    assign data_in = DataIn[7:0];
    assign data_in_valid = wen & (Addr[3:0] == 4'h8);
    assign data_out_ready = ren & (Addr[3:0] == 4'h4);
    
    reg [31:0] rmux_dout;

    always @(*)
    begin
      if (ren) begin
        case (Addr[7:0])
          8'h00:      rmux_dout = {30'b0, data_out_valid, data_in_ready};
          8'h04:      rmux_dout = {24'b0, data_out};
          default:    rmux_dout = 32'd0;
        endcase
      end
      else begin
        rmux_dout = 32'd0;
      end
    end

    uart #(
        .CLOCK_FREQ (CLOCK_FREQ),
        .BAUD_RATE  (BAUD_RATE)
    ) u_uart (
        .clk              (clk) ,
        .reset            (reset) ,
    
        .data_in          (data_in),
        .data_in_valid    (data_in_valid),
        .data_in_ready    (data_in_ready),
    
        .data_out         (data_out),
        .data_out_valid   (data_out_valid),
        .data_out_ready   (data_out_ready),
    
        .serial_in        (uart_rx),
        .serial_out       (uart_tx)
    );


    assign DataOut = rmux_dout;



endmodule
