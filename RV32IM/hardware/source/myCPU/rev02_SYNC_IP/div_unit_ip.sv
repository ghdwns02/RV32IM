
module div_unit_ip (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,      // EX 단계 DIV/REM 명령 시작
    output     [31:0]   result,
    output              half_done   // 나눗셈 완료, EX stall 해제
);

    // ALUControl (aludec.sv 기준)
    // 5'b11000 = DIV  (signed quotient)
    // 5'b11001 = DIVU (unsigned quotient)
    // 5'b11010 = REM  (signed remainder)
    // 5'b11011 = REMU (unsigned remainder)

    wire is_signed_op = (ALUControl == 5'b11000) | (ALUControl == 5'b11010);
    wire is_rem_op    = (ALUControl == 5'b11010) | (ALUControl == 5'b11011);

    wire div_by_zero = (b_in == 32'd0);
    wire signed_ovfl = is_signed_op & (a_in == 32'h8000_0000) & (b_in == 32'hFFFF_FFFF);

    wire a_neg_w = is_signed_op & a_in[31];
    wire b_neg_w = is_signed_op & b_in[31];

    wire [31:0] a_abs_w = a_neg_w ? (~a_in + 32'd1) : a_in;
    wire [31:0] b_abs_w = b_neg_w ? (~b_in + 32'd1) : b_in;

    localparam ST_IDLE     = 2'b00;
    localparam ST_WAIT     = 2'b01;
    localparam ST_DONE_EX  = 2'b10;
    localparam ST_DONE_MEM = 2'b11;

    reg [1:0]  state;
    reg        a_neg, b_neg, is_rem, is_ex;
    reg [31:0] ex_res;
    reg [31:0] raw_quotient, raw_remainder;
    reg [31:0] out_reg;
    reg        half_done_reg;

    // AXI-S 입력 (1클럭 펄스)
    reg        ip_tvalid;
    reg [39:0] ip_dividend_tdata;  // [32:0] = {1'b0, a_abs}, [39:33] = 0
    reg [31:0] ip_divisor_tdata;

    // AXI-S 출력
    wire        ip_dout_tvalid;
    wire [0:0]  ip_dout_tuser;  // divide-by-zero 플래그 (wrapper에서 별도 처리하므로 미사용)
    wire [71:0] ip_dout_tdata;  // [31:0]=remainder, [64:32]=quotient(33-bit)

    div_gen_0 u_div_gen_0 (
        .aclk                   (clk),
        .s_axis_divisor_tvalid  (ip_tvalid),
        .s_axis_divisor_tdata   (ip_divisor_tdata),
        .s_axis_dividend_tvalid (ip_tvalid),
        .s_axis_dividend_tdata  (ip_dividend_tdata),
        .m_axis_dout_tvalid     (ip_dout_tvalid),
        .m_axis_dout_tuser      (ip_dout_tuser),
        .m_axis_dout_tdata      (ip_dout_tdata)
    );

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            state             <= ST_IDLE;
            ip_tvalid         <= 1'b0;
            ip_dividend_tdata <= 40'd0;
            ip_divisor_tdata  <= 32'd0;
            a_neg             <= 1'b0;
            b_neg             <= 1'b0;
            is_rem            <= 1'b0;
            is_ex             <= 1'b0;
            ex_res            <= 32'd0;
            raw_quotient      <= 32'd0;
            raw_remainder     <= 32'd0;
            out_reg           <= 32'd0;
            half_done_reg     <= 1'b0;
        end else begin
            ip_tvalid <= 1'b0;  // 기본: 매 사이클 디어서트

            case (state)
                ST_IDLE: begin
                    half_done_reg <= 1'b0;
                    if (start) begin
                        a_neg  <= a_neg_w;
                        b_neg  <= b_neg_w;
                        is_rem <= is_rem_op;

                        if (div_by_zero | signed_ovfl) begin
                            is_ex <= 1'b1;
                            if (div_by_zero)
                                ex_res <= is_rem_op ? a_in : 32'hFFFF_FFFF;
                            else  // signed overflow: DIV→MIN_INT, REM→0
                                ex_res <= is_rem_op ? 32'd0 : 32'h8000_0000;
                            state <= ST_DONE_EX;
                        end else begin
                            is_ex             <= 1'b0;
                            // 33-bit 피제수: [32]=0, [31:0]=절댓값
                            ip_dividend_tdata <= {8'd0, a_abs_w};
                            ip_divisor_tdata  <= b_abs_w;
                            ip_tvalid         <= 1'b1;  // 다음 클럭 1사이클만 어서트
                            state             <= ST_WAIT;
                        end
                    end
                end

                ST_WAIT: begin
                    if (ip_dout_tvalid) begin
                        // IP 출력 래치: tdata[63:32]=quotient(32비트 유효), tdata[31:0]=remainder
                        raw_quotient  <= ip_dout_tdata[63:32];
                        raw_remainder <= ip_dout_tdata[31:0];
                        state         <= ST_DONE_EX;
                    end
                end

                ST_DONE_EX: begin
                    half_done_reg <= 1'b1;
                    if (is_ex) begin
                        out_reg <= ex_res;
                    end else if (is_rem) begin
                        out_reg <= a_neg ? (~raw_remainder + 32'd1) : raw_remainder;
                    end else begin
                        out_reg <= (a_neg ^ b_neg) ? (~raw_quotient + 32'd1) : raw_quotient;
                    end
                    state <= ST_DONE_MEM;
                end

                ST_DONE_MEM: begin
                    half_done_reg <= 1'b0;
                    state         <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    assign result    = out_reg;
    assign half_done = half_done_reg;

endmodule
