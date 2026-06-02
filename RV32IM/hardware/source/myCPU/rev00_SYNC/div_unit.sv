module div_unit (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,      // EX 단계 DIV/REM 명령 시작
    output     [31:0]   result,
    output              half_done,  // 중간 phase 완료, EX stall 해제
    output              done        // 최종 결과 유효
);

    // signed 명령: 절댓값 나눗셈 후 마지막 부호 복원
    wire is_signed_op = (ALUControl == 5'b11000) | (ALUControl == 5'b11010);
    wire div_by_zero  = (b_in == 32'd0);
    wire signed_ovfl  = (a_in == 32'h8000_0000) & (b_in == 32'hFFFF_FFFF) & is_signed_op;

    wire [31:0] a_abs = (a_in[31] & is_signed_op) ? (~a_in + 32'd1) : a_in;
    wire [31:0] b_abs = (b_in[31] & is_signed_op) ? (~b_in + 32'd1) : b_in;
    wire        a_neg = a_in[31] & is_signed_op;
    wire        b_neg = b_in[31] & is_signed_op;
    wire [32:0] a_pad = {1'b0, a_abs};

    // radix-8 단계 비교용 divisor 1배~7배 사전 생성
    wire [34:0] b1 = {3'b000, b_abs};
    wire [34:0] b2 = {2'b00,  b_abs, 1'b0};
    wire [34:0] b3 = b2 + b1;
    wire [34:0] b4 = {1'b0,   b_abs, 2'b00};
    wire [34:0] b5 = b4 + b1;
    wire [34:0] b6 = b4 + b2;
    wire [34:0] b7 = {b_abs, 3'b000} - {3'b000, b_abs};

    function automatic [38:0] div_stage;
        input [35:0] rem;
        input [2:0]  bits;
        input [34:0] f_b1, f_b2, f_b3, f_b4, f_b5, f_b6, f_b7;

        reg [35:0] rsh;
        reg [35:0] d1, d2, d3, d4, d5, d6, d7;
        reg [6:0]  ge;
        reg [2:0]  qd;
        reg [35:0] rn;

        begin
            // radix-8: 단계마다 dividend 3비트 shift-in
            rsh = {rem[32:0], bits};

            // 각 배수 subtraction 후 음수가 아닌 후보 탐색
            d7 = rsh - {1'b0, f_b7};
            d6 = rsh - {1'b0, f_b6};
            d5 = rsh - {1'b0, f_b5};
            d4 = rsh - {1'b0, f_b4};
            d3 = rsh - {1'b0, f_b3};
            d2 = rsh - {1'b0, f_b2};
            d1 = rsh - {1'b0, f_b1};

            ge[6] = ~d7[35];
            ge[5] = ~d6[35];
            ge[4] = ~d5[35];
            ge[3] = ~d4[35];
            ge[2] = ~d3[35];
            ge[1] = ~d2[35];
            ge[0] = ~d1[35];

            qd = ge[6] ? 3'd7 :
                 ge[5] ? 3'd6 :
                 ge[4] ? 3'd5 :
                 ge[3] ? 3'd4 :
                 ge[2] ? 3'd3 :
                 ge[1] ? 3'd2 :
                 ge[0] ? 3'd1 : 3'd0;

            case (qd)
                3'd7: rn = d7;
                3'd6: rn = d6;
                3'd5: rn = d5;
                3'd4: rn = d4;
                3'd3: rn = d3;
                3'd2: rn = d2;
                3'd1: rn = d1;
                default: rn = rsh;
            endcase

            div_stage = {qd, rn};
        end
    endfunction

    // Phase 0: live 입력으로 상위 9비트 몫 선계산
    wire [38:0] s0_live = div_stage(36'd0,         a_pad[32:30], b1,b2,b3,b4,b5,b6,b7);
    wire [38:0] s1_live = div_stage(s0_live[35:0], a_pad[29:27], b1,b2,b3,b4,b5,b6,b7);
    wire [38:0] s2_live = div_stage(s1_live[35:0], a_pad[26:24], b1,b2,b3,b4,b5,b6,b7);

    reg [35:0] r_rem_ph0;
    reg [8:0]  r_q_ph0;
    reg [32:0] r_apad_ph0;
    reg [34:0] r_b1_ph0, r_b2_ph0, r_b3_ph0, r_b4_ph0;
    reg [34:0] r_b5_ph0, r_b6_ph0, r_b7_ph0;
    reg        r_aneg_ph0, r_bneg_ph0;
    reg        r_dbz_ph0, r_sovfl_ph0;
    reg [4:0]  r_aluctl_ph0;
    reg [31:0] r_ain_ph0;
    reg        r_ph0_valid;

    // Phase 1: 저장된 Phase 0 결과에서 다음 12비트 몫 계산
    wire [38:0] s3     = div_stage(r_rem_ph0,   r_apad_ph0[23:21], r_b1_ph0,r_b2_ph0,r_b3_ph0,r_b4_ph0,r_b5_ph0,r_b6_ph0,r_b7_ph0);
    wire [38:0] s4     = div_stage(s3[35:0],    r_apad_ph0[20:18], r_b1_ph0,r_b2_ph0,r_b3_ph0,r_b4_ph0,r_b5_ph0,r_b6_ph0,r_b7_ph0);
    wire [38:0] s5     = div_stage(s4[35:0],    r_apad_ph0[17:15], r_b1_ph0,r_b2_ph0,r_b3_ph0,r_b4_ph0,r_b5_ph0,r_b6_ph0,r_b7_ph0);
    wire [38:0] t0_p1  = div_stage(s5[35:0],    r_apad_ph0[14:12], r_b1_ph0,r_b2_ph0,r_b3_ph0,r_b4_ph0,r_b5_ph0,r_b6_ph0,r_b7_ph0);

    wire [11:0] q_ph1_digits = {s3[38:36], s4[38:36], s5[38:36], t0_p1[38:36]};

    reg [35:0] r_rem;
    reg [20:0] r_q_ph1;
    reg [32:0] r_apad;
    reg [34:0] rb1, rb2, rb3, rb4, rb5, rb6, rb7;
    reg        r_aneg, r_bneg;
    reg        r_dbz, r_sovfl;
    reg [4:0]  r_aluctl;
    reg [31:0] r_ain;
    reg        r_valid;

    always @(posedge clk or negedge n_rst) begin
        // start 후 두 내부 phase, MEM 단계용 중간값 준비
        if (!n_rst) begin
            r_ph0_valid  <= 1'b0;
            r_valid      <= 1'b0;
            r_rem_ph0    <= 36'd0; r_q_ph0      <= 9'd0;
            r_rem        <= 36'd0; r_q_ph1      <= 21'd0;
            r_apad_ph0   <= 33'd0; r_apad       <= 33'd0;
            r_b1_ph0 <= 35'd0; r_b2_ph0 <= 35'd0; r_b3_ph0 <= 35'd0; r_b4_ph0 <= 35'd0;
            r_b5_ph0 <= 35'd0; r_b6_ph0 <= 35'd0; r_b7_ph0 <= 35'd0;
            r_aneg_ph0 <= 1'b0; r_bneg_ph0 <= 1'b0;
            r_dbz_ph0  <= 1'b0; r_sovfl_ph0 <= 1'b0;
            r_aluctl_ph0 <= 5'd0; r_ain_ph0 <= 32'd0;
            rb1 <= 35'd0; rb2 <= 35'd0; rb3 <= 35'd0; rb4 <= 35'd0;
            rb5 <= 35'd0; rb6 <= 35'd0; rb7 <= 35'd0;
            r_aneg  <= 1'b0; r_bneg  <= 1'b0;
            r_dbz   <= 1'b0; r_sovfl <= 1'b0;
            r_aluctl <= 5'd0; r_ain  <= 32'd0;

        end else if (start & ~r_ph0_valid & ~r_valid) begin
            // Phase 0 결과, 예외 정보, 부호 정보 저장
            r_rem_ph0    <= s2_live[35:0];
            r_q_ph0      <= {s0_live[38:36], s1_live[38:36], s2_live[38:36]};
            r_apad_ph0   <= a_pad;
            r_b1_ph0 <= b1; r_b2_ph0 <= b2; r_b3_ph0 <= b3; r_b4_ph0 <= b4;
            r_b5_ph0 <= b5; r_b6_ph0 <= b6; r_b7_ph0 <= b7;
            r_aneg_ph0   <= a_neg;       r_bneg_ph0  <= b_neg;
            r_dbz_ph0    <= div_by_zero;
            r_sovfl_ph0  <= signed_ovfl;
            r_aluctl_ph0 <= ALUControl;
            r_ain_ph0    <= a_in;
            r_ph0_valid  <= 1'b1;

        end else if (r_ph0_valid) begin
            // Phase 1 완료: half_done 상승, EX stall 해제
            r_rem        <= t0_p1[35:0];
            r_q_ph1      <= {r_q_ph0, q_ph1_digits};
            r_apad       <= r_apad_ph0;
            rb1 <= r_b1_ph0; rb2 <= r_b2_ph0; rb3 <= r_b3_ph0; rb4 <= r_b4_ph0;
            rb5 <= r_b5_ph0; rb6 <= r_b6_ph0; rb7 <= r_b7_ph0;
            r_aneg       <= r_aneg_ph0;   r_bneg  <= r_bneg_ph0;
            r_dbz        <= r_dbz_ph0;    r_sovfl <= r_sovfl_ph0;
            r_aluctl     <= r_aluctl_ph0; r_ain   <= r_ain_ph0;
            r_ph0_valid  <= 1'b0;
            r_valid      <= 1'b1;

        end else begin
            r_valid <= 1'b0;
        end
    end

    // Phase 2: 남은 하위 12비트 몫 조합 계산
    wire [38:0] t1 = div_stage(r_rem,    r_apad[11: 9], rb1,rb2,rb3,rb4,rb5,rb6,rb7);
    wire [38:0] t2 = div_stage(t1[35:0], r_apad[ 8: 6], rb1,rb2,rb3,rb4,rb5,rb6,rb7);
    wire [38:0] t3 = div_stage(t2[35:0], r_apad[ 5: 3], rb1,rb2,rb3,rb4,rb5,rb6,rb7);
    wire [38:0] t4 = div_stage(t3[35:0], r_apad[ 2: 0], rb1,rb2,rb3,rb4,rb5,rb6,rb7);

    wire [11:0] q_ph2    = {t1[38:36], t2[38:36], t3[38:36], t4[38:36]};

    wire [32:0] quot_full = {r_q_ph1, q_ph2};
    wire [31:0] quot_raw  = quot_full[31:0];
    wire [31:0] rem_raw   = t4[31:0];

    // signed 나눗셈: quotient/remainder 부호, RISC-V 규칙 기준 복원
    wire [31:0] quot_corr = (r_aneg ^ r_bneg) ? (~quot_raw + 32'd1) : quot_raw;
    wire [31:0] rem_corr  =  r_aneg           ? (~rem_raw  + 32'd1) : rem_raw;

    reg [31:0] final_result;
    always @(*) begin
        // divide-by-zero와 signed overflow 결과: RISC-V ISA 고정값
        if (r_dbz)
            final_result = r_aluctl[1] ? r_ain : 32'hFFFF_FFFF;
        else if (r_sovfl)
            final_result = r_aluctl[1] ? 32'h0 : 32'h8000_0000;
        else case (r_aluctl)
            5'b11000: final_result = quot_corr;
            5'b11001: final_result = quot_raw;
            5'b11010: final_result = rem_corr;
            5'b11011: final_result = rem_raw;
            default:  final_result = 32'd0;
        endcase
    end

    reg [31:0] s2_result;
    reg        s2_valid;

    always @(posedge clk or negedge n_rst) begin
        // 최종 결과 추가 등록, MEM 단계 결과 유효 타이밍 정렬
        if (!n_rst)       begin s2_result <= 32'h0; s2_valid <= 1'b0; end
        else if (r_valid) begin s2_result <= final_result; s2_valid <= 1'b1; end
        else              begin s2_result <= 32'h0;        s2_valid <= 1'b0; end
    end

    assign result    = s2_result;
    assign half_done = r_valid;
    assign done      = s2_valid;

endmodule
