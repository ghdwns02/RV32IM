// ALU 연산과 조건 플래그 생성
// rev00_ASYNC: RV32M 곱셈/나눗셈도 ALU 내부 조합 연산으로 처리
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

    // SUB처럼 b 반전 + carry-in=1이 필요한 연산
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

    wire signed [31:0] a_in_signed = a_in;
    wire signed [31:0] b_in_signed = b_in;

    // M-extension 곱셈 결과 미리 계산
    wire        [63:0] mul_uu = $unsigned(a_in) * $unsigned(b_in);
    wire signed [63:0] mul_ss = a_in_signed * b_in_signed;
    wire signed [63:0] mul_su = a_in_signed * $signed({1'b0, b_in});

    // RISC-V DIV/REM 예외 케이스
    wire div_by_zero   = (b_in == 32'h0);
    wire signed_overfl = ($signed(a_in) == 32'h8000_0000) && ($signed(b_in) == -32'sd1);

    // ALUControl에 따라 RV32I/M 결과 선택
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
            5'b01111: result = (a_in < b_in) ? 32'd1 : 32'd0;
            5'b10000: result = (a_in < b_in) ? 32'd1 : 32'd0;
            5'b10001: result = a_in & b_in;
            5'b10010: result = a_in | b_in;
            5'b10011: result = a_in ^ b_in;

            // RV32M: MUL/MULH/MULHSU/MULHU
            5'b10100: result = mul_uu[31:0];
            5'b10101: result = mul_ss[63:32];
            5'b10110: result = mul_su[63:32];
            5'b10111: result = mul_uu[63:32];
            // RV32M: DIV/DIVU/REM/REMU
            5'b11000: begin
                if (div_by_zero)
                    result = 32'hFFFF_FFFF;
                else if (signed_overfl)
                    result = a_in;
                else
                    result = $signed(a_in) / $signed(b_in);
            end
            5'b11001: begin
                if (div_by_zero)
                    result = 32'hFFFF_FFFF;
                else
                    result = $unsigned(a_in) / $unsigned(b_in);
            end
            5'b11010: begin
                if (div_by_zero)
                    result = a_in;
                else if (signed_overfl)
                    result = 32'h0;
                else
                    result = $signed(a_in) % $signed(b_in);
            end
            5'b11011: begin
                if (div_by_zero)
                    result = a_in;
                else
                    result = $unsigned(a_in) % $unsigned(b_in);
            end
            default:  result = 32'hx;
        endcase
    end

    // branch 비교에 사용할 NZCV flag 생성
    // adder 기반 연산은 adder flag, 나머지는 result 기준
    always @(*) begin
        case (ALUControl)
            5'b00000, 5'b00001, 5'b01101,
            5'b00101, 5'b01110, 5'b10000, 5'b01111:
                {aN, aZ, aC, aV} = {N, Z, C, V};
            default: begin
                aN = result[31];
                aZ = (result == 32'h0);
                aC = 1'b0;
                aV = 1'b0;
            end
        endcase
    end

endmodule
