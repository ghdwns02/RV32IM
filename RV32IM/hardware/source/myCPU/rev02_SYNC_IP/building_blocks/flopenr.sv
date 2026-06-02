module flopenr(
    clk,
    n_rst,
    en,
    d,
    q
);
    parameter RESET_VALUE = 32'h1000_0000;

    input clk, n_rst, en;
    input [31:0] d;
    output reg [31:0] q;

    always@(posedge clk or negedge n_rst) begin
        if(!n_rst) begin
            q <= RESET_VALUE;
        end
        else begin
            if(en)
                q <= d;
        end
    end

endmodule
