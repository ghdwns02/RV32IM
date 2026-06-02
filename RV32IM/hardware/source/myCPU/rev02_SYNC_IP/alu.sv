module alu(
    input         [31:0] a_in,
    input         [31:0] b_in,
    input         [4:0]  ALUControl,
    output reg    [31:0] result,
    output reg           aN, aZ, aC, aV
);

    // ADD/SUB/비교 계열은 adder 하나를 공유
    wire [31:0] adder_result;
    wire        N, Z, C, V;

    // SUB처럼 b를 반전하고 carry-in=1이 필요한 연산들
    wire sub_ctrl =
              (ALUControl == 5'b00001)
           || (ALUControl == 5'b00101)
           || (ALUControl == 5'b01110)
           || (ALUControl == 5'b10000)
           || (ALUControl == 5'b01111);

    adder u_adder (
        .a  (a_in),
        .b  (sub_ctrl ? ~b_in : b_in),
        .ci (sub_ctrl),
        .sum(adder_result),
        .N  (N),
        .Z  (Z),
        .C  (C),
        .V  (V)
    );

    // ALUControl에 따라 RV32I 산술/논리/시프트 결과 선택
    always @(*) begin
        case (ALUControl)

            5'b00000: result = adder_result;
            5'b00001: result = adder_result;
            5'b00010: result = a_in & b_in;
            5'b00011: result = a_in | b_in;
            5'b00100: result = a_in ^ b_in;
            5'b00101: result = ($signed(a_in) < $signed(b_in)) ? 32'd1 : 32'd0;
            5'b00110: result = a_in << b_in[4:0];
            5'b00111: result = a_in >> b_in[4:0];
            5'b01000: result = $signed(a_in) >>> b_in[4:0];
            5'b01001: result = (a_in + b_in) & 32'hFFFF_FFFE;
            5'b01010: result = $signed(a_in) >>> b_in[4:0];
            5'b01011: result = a_in >> b_in[4:0];
            5'b01100: result = a_in << b_in[4:0];
            5'b01101: result = adder_result;
            5'b01110: result = ($signed(a_in) < $signed(b_in)) ? 32'd1 : 32'd0;
            5'b01111: result = ($unsigned(a_in) < $unsigned(b_in)) ? 32'd1 : 32'd0;
            5'b10000: result = ($unsigned(a_in) < $unsigned(b_in)) ? 32'd1 : 32'd0;
            5'b10001: result = a_in & b_in;
            5'b10010: result = a_in | b_in;
            5'b10011: result = a_in ^ b_in;

            default:  result = 32'h0;
        endcase
    end

    // 분기 판단에 사용할 NZCV 플래그 생성
    // adder 기반 연산은 adder 플래그, 나머지는 result 기준으로 간단 생성
    always @(*) begin
        case (ALUControl)

            5'b00000, 5'b00001, 5'b01101,
            5'b00101, 5'b01110, 5'b10000, 5'b01111:
                {aN, aZ, aC, aV} = {N, Z, C, V};

            5'b00110, 5'b00111, 5'b01000,
            5'b01010, 5'b01011, 5'b01100: begin
                aN = result[31];
                aZ = (result == 32'h0);
                aC = 1'b0;
                aV = 1'b0;
            end

            default: begin
                aN = result[31];
                aZ = (result == 32'h0);
                aC = 1'b0;
                aV = 1'b0;
            end
        endcase
    end

endmodule
