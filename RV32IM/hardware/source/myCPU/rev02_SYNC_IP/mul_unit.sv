// 1사이클 레이턴시 곱셈기 (RV32M: MUL / MULH / MULHSU / MULHU)
// EX단계에서 start → 클록 엣지에 곱을 레지스터에 래치 → MEM단계에서 결과 유효
module mul_unit (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,
    output     [31:0]   result
);

    // MULHU(10111): 둘 다 부호 없음 / MULHSU(10110): a만 부호 있음 / 나머지: 둘 다 부호 있음
    wire signed [32:0] a_ext = {(ALUControl != 5'b10111) & a_in[31], a_in};
    wire signed [32:0] b_ext = {(ALUControl == 5'b10101) & b_in[31], b_in};

    reg signed [65:0]  s1_result;
    reg        [4:0]   s1_ctrl;

    always @(posedge clk or negedge n_rst) begin
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

    // MUL: 하위 32비트, MULH/MULHSU/MULHU: 상위 32비트 선택
    reg [31:0] result_r;
    always @(*) begin
        case (s1_ctrl)
            5'b10100: result_r = s1_result[31:0];   // MUL
            5'b10101: result_r = s1_result[63:32];  // MULH
            5'b10110: result_r = s1_result[63:32];  // MULHSU
            5'b10111: result_r = s1_result[63:32];  // MULHU
            default:  result_r = s1_result[31:0];
        endcase
    end

    assign result = result_r;

endmodule
