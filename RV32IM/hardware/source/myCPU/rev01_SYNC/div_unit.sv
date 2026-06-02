module div_unit (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,      // EX 단계 DIV/REM 명령 시작
    output     [31:0]   result,
    output              half_done   // 나눗셈 완료, EX stall 해제
);

    // 1. 명령어 디코딩 및 예외 조건 판별 (조합 논리)
    wire is_signed_op = (ALUControl == 5'b11000) | (ALUControl == 5'b11010);
    wire is_rem_op    = (ALUControl == 5'b11010) | (ALUControl == 5'b11011);
    
    wire div_by_zero  = (b_in == 32'd0);
    wire signed_ovfl  = is_signed_op & (a_in == 32'h8000_0000) & (b_in == 32'hFFFF_FFFF);

    wire a_neg_w = is_signed_op & a_in[31];
    wire b_neg_w = is_signed_op & b_in[31];
    
    // 절댓값 변환
    wire [31:0] a_abs_w = a_neg_w ? (~a_in + 32'd1) : a_in;
    wire [31:0] b_abs_w = b_neg_w ? (~b_in + 32'd1) : b_in;

    // 2. 상태 머신 및 레지스터 선언
    localparam ST_IDLE     = 2'b00;
    localparam ST_CALC     = 2'b01;
    localparam ST_DONE_EX  = 2'b10;
    localparam ST_DONE_MEM = 2'b11;

    reg [1:0]  state;
    reg [3:0]  count;       // 16번의 루프 카운트 (0~15)
    
    reg [63:0] AQ;          // A(나머지) : Q(몫) 레지스터
    reg [31:0] M;           // 제수(Divisor) 레지스터

    reg        a_neg, b_neg, is_rem, is_ex;
    reg [31:0] ex_res;      // 0으로 나누기, 오버플로우 발생 시 결과
    
    reg [31:0] out_reg;
    reg        half_done_reg;

    // 3. 한 사이클에 2비트를 계산하는 조합 논리회로 (Radix-2 Unrolled x 2)
    // 첫 번째 비트 연산 (Shift -> Subtract -> Mux)
    wire [31:0] A_sh1 = {AQ[62:32], AQ[31]};
    wire [32:0] sub1  = {1'b0, A_sh1} - {1'b0, M};
    wire        sel1  = ~sub1[32]; // 결과가 양수면 1 (M보다 크거나 같음)
    wire [31:0] A_n1  = sel1 ? sub1[31:0] : A_sh1;
    wire [31:0] Q_n1  = {AQ[30:0], sel1};

    // 두 번째 비트 연산 (Shift -> Subtract -> Mux)
    wire [31:0] A_sh2 = {A_n1[30:0], Q_n1[31]};
    wire [32:0] sub2  = {1'b0, A_sh2} - {1'b0, M};
    wire        sel2  = ~sub2[32];
    wire [31:0] A_n2  = sel2 ? sub2[31:0] : A_sh2;
    wire [31:0] Q_n2  = {Q_n1[30:0], sel2};

    // 부호 복원 계산식
    wire [31:0] Q_final = AQ[31:0];
    wire [31:0] R_final = AQ[63:32];
    wire [31:0] Q_corr  = (a_neg ^ b_neg) ? (~Q_final + 32'd1) : Q_final;
    wire [31:0] R_corr  = a_neg           ? (~R_final + 32'd1) : R_final;

    // 4. 순차 회로 제어 로직
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            state         <= ST_IDLE;
            count         <= 4'd0;
            AQ            <= 64'd0;
            M             <= 32'd0;
            a_neg         <= 1'b0;
            b_neg         <= 1'b0;
            is_rem        <= 1'b0;
            is_ex         <= 1'b0;
            ex_res        <= 32'd0;
            out_reg       <= 32'd0;
            half_done_reg <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    half_done_reg <= 1'b0;
                    if (start) begin
                        a_neg  <= a_neg_w;
                        b_neg  <= b_neg_w;
                        is_rem <= is_rem_op;
                        
                        // RISC-V 예외 처리: 0으로 나누거나 오버플로우 시 바로 종료로 건너뜀
                        if (div_by_zero | signed_ovfl) begin
                            is_ex <= 1'b1;
                            if (div_by_zero)
                                ex_res <= is_rem_op ? a_in : 32'hFFFF_FFFF;
                            else // signed overflow
                                ex_res <= is_rem_op ? 32'd0  : 32'h8000_0000;
                            state <= ST_DONE_EX;
                        end else begin
                            is_ex <= 1'b0;
                            AQ    <= {32'd0, a_abs_w}; // A를 0으로 비우고, Q에 배당자(Dividend) 적재
                            M     <= b_abs_w;          // 제수(Divisor) 적재
                            count <= 4'd0;
                            state <= ST_CALC;
                        end
                    end
                end

                ST_CALC: begin
                    // 매 사이클마다 조합논리로 계산된 2비트 분량의 결과를 레지스터에 업데이트
                    AQ    <= {A_n2, Q_n2};
                    count <= count + 4'd1;
                    // 16 사이클 반복 (16 * 2bits = 32bits 완료)
                    if (count == 4'd15) begin
                        state <= ST_DONE_EX;
                    end
                end

                ST_DONE_EX: begin
                    // EX stall을 해제하기 위해 half_done을 HIGH로 만듦
                    half_done_reg <= 1'b1;
                    
                    // 최종 결과 (예외 결과 or 연산된 결과) 반영
                    if (is_ex) begin
                        out_reg <= ex_res;
                    end else begin
                        out_reg <= is_rem ? R_corr : Q_corr;
                    end
                    state <= ST_DONE_MEM;
                end

                ST_DONE_MEM: begin
                    // 파이프라인이 MEM 단계로 넘어가면서 half_done 내림
                    half_done_reg <= 1'b0;
                    
                    // Datapath는 이 사이클에 div_result를 캡처하므로 결과를 안정적으로 유지하고 IDLE로 복귀
                    state <= ST_IDLE;
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

    // 최종 출력 할당
    assign result    = out_reg;
    assign half_done = half_done_reg;

endmodule