

module mul_unit (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,
    output     [31:0]   result
);

    wire signed [32:0] a_ext = {(ALUControl != 5'b10111) & a_in[31], a_in};
    wire signed [32:0] b_ext = {(ALUControl == 5'b10101) & b_in[31], b_in};

    reg signed [65:0]  s1_result;
    reg        [4:0]   s1_ctrl;

    always @(posedge clk) begin
        if(!n_rst) begin
            s1_result <= 66'b0;
            s1_ctrl   <= 5'b0;
        end else if (start) begin
            s1_result <= a_ext * b_ext;
            s1_ctrl   <= ALUControl;
        end else begin
            s1_result <= 66'b0;
            s1_ctrl   <= 5'b0;
        end
    end

    reg [31:0] result_r;
    always @(*) begin
        case (s1_ctrl)
            5'b10100: result_r = s1_result[31:0];
            5'b10101: result_r = s1_result[63:32];
            5'b10110: result_r = s1_result[63:32];
            5'b10111: result_r = s1_result[63:32];
            default:  result_r = s1_result[31:0];
        endcase
    end

    assign result = result_r;

endmodule
