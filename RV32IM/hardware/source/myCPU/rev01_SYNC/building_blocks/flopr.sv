module flopr(
    clk,
    n_rst,
    d,
    q
);

    parameter RESET_VALUE = 32'h0000_0000;

    input clk, n_rst;
    input [31:0] d;
    output reg [31:0] q;

    always@(posedge clk or negedge n_rst) begin
        if(!n_rst) begin
            q <= RESET_VALUE;
        end
        else begin
            q <= d;
        end
    end

endmodule
