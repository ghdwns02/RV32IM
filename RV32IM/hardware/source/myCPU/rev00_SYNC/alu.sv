// ALU 연산과 조건 플래그 생성
module alu(
    input         [31:0] a_in,
    input         [31:0] b_in,
    input         [4:0]  ALUControl,
    output reg    [31:0] result,
    output reg           aN, aZ, aC, aV
);

    wire [31:0] adder_result;
    wire        N, Z, C, V;

    // SUB, SLT 계열: adder 입력 반전, carry-in 1, 뺄셈
    wire sub_ctrl =
              (ALUControl == 5'b00001)
           || (ALUControl == 5'b00101)
           || (ALUControl == 5'b10000);

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

    always @(*) begin
        // ALUControl 값에 따른 32비트 연산 결과 선택
        case (ALUControl)

            5'b00000: result = adder_result;                                        // ADD, ADDI, load/store 주소 계산
            5'b00001: result = adder_result;                                        // SUB, branch 비교
            5'b00010: result = a_in & b_in;                                         // AND, ANDI
            5'b00011: result = a_in | b_in;                                         // OR, ORI
            5'b00100: result = a_in ^ b_in;                                         // XOR, XORI
            5'b00101: result = ($signed(a_in) < $signed(b_in)) ? 32'd1 : 32'd0;     // SLT, SLTI
            5'b00110: result = a_in << b_in[4:0];                                   // SLL, SLLI
            5'b00111: result = a_in >> b_in[4:0];                                   // SRL, SRLI
            5'b01000: result = $signed(a_in) >>> b_in[4:0];                         // SRA, SRAI
            5'b01001: result = (a_in + b_in) & 32'hFFFF_FFFE;                       // JALR target
            5'b10000: result = ($unsigned(a_in) < $unsigned(b_in)) ? 32'd1 : 32'd0; // SLTU, SLTIU

            default:  result = 32'h0;
        endcase
    end

    always @(*) begin
        // branch 비교용 플래그: 덧셈기 결과 또는 최종 result 기준
        case (ALUControl)

            5'b00000, 5'b00001,
            5'b00101, 5'b10000:
                {aN, aZ, aC, aV} = {N, Z, C, V};

            5'b00110, 5'b00111, 5'b01000: begin
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
