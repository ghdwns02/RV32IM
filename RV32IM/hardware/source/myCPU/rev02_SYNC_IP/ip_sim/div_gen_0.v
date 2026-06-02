
// Vivado Divider Generator IP (xilinx.com:ip:div_gen:5.1) 설정:
//   Algorithm  : Radix-2 (non-pipelined)
//   Operand    : Unsigned
//   Dividend   : 33-bit  -> s_axis_dividend_tdata[39:0], 실제값 [32:0]
//   Divisor    : 32-bit  -> s_axis_divisor_tdata[31:0]
//   Output     : Quotient + Remainder
//   DBZ detect : 활성화  -> m_axis_dout_tuser[0]

`timescale 1ps/1ps

module div_gen_0 (
    input  wire        aclk,
    input  wire        s_axis_divisor_tvalid,
    input  wire [31:0] s_axis_divisor_tdata,
    input  wire        s_axis_dividend_tvalid,
    input  wire [39:0] s_axis_dividend_tdata,
    output reg         m_axis_dout_tvalid,
    output reg  [0:0]  m_axis_dout_tuser,
    output reg  [71:0] m_axis_dout_tdata
);

    // Radix-2 레이턴시: dividend_width(33) + 3 = 36 클럭
    localparam LATENCY = 36;

    // 쉬프트 레지스터 파이프라인
    reg [LATENCY-1:0] vld_sr;
    reg [LATENCY-1:0] dbz_sr;
    reg [71:0]        dat_sr [0:LATENCY-1];

    integer i;

    always @(posedge aclk) begin : pipeline
        // 매 사이클 계산할 임시 변수
        reg          new_vld;
        reg          new_dbz;
        reg [71:0]   new_dat;
        reg [32:0]   dividend;
        reg [31:0]   divisor;
        reg [32:0]   quotient;
        reg [31:0]   remainder;

        new_vld = s_axis_dividend_tvalid & s_axis_divisor_tvalid;

        if (new_vld) begin
            dividend  = s_axis_dividend_tdata[32:0];
            divisor   = s_axis_divisor_tdata[31:0];
            new_dbz   = (divisor == 32'd0);

            if (new_dbz) begin
                quotient  = {33{1'b1}};
                remainder = 32'd0;
            end else begin
                quotient  = dividend / {1'b0, divisor};
                remainder = dividend % {1'b0, divisor};
            end
            // tdata: [71:65]=0, [64:32]=quotient(33-bit), [31:0]=remainder
            new_dat = {7'd0, quotient, remainder};
        end else begin
            new_dbz = 1'b0;
            new_dat = 72'd0;
        end

        // 파이프라인 쉬프트 (인덱스 0 = 최신, LATENCY-1 = 출력단)
        vld_sr <= {vld_sr[LATENCY-2:0], new_vld};
        dbz_sr <= {dbz_sr[LATENCY-2:0], new_dbz};
        for (i = LATENCY-1; i > 0; i = i - 1)
            dat_sr[i] <= dat_sr[i-1];
        dat_sr[0] <= new_dat;

        // 출력 레지스터 갱신 (현재 파이프라인 최상단 값 래치)
        m_axis_dout_tvalid <= vld_sr[LATENCY-1];
        m_axis_dout_tuser  <= {dbz_sr[LATENCY-1]};
        m_axis_dout_tdata  <= dat_sr[LATENCY-1];
    end

    initial begin
        vld_sr             = {LATENCY{1'b0}};
        dbz_sr             = {LATENCY{1'b0}};
        m_axis_dout_tvalid = 1'b0;
        m_axis_dout_tuser  = 1'b0;
        m_axis_dout_tdata  = 72'd0;
        for (i = 0; i < LATENCY; i = i + 1)
            dat_sr[i] = 72'd0;
    end

endmodule
