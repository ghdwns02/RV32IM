// EX 단계 값을 MEM 단계로 전달하는 파이프라인 레지스터
module EX_MEM (

    input               clk,
    input               n_rst,
    input               MDUStall,

    input               is_mul_in,
    input               is_div_in,
    input       [1:0]   ResultSrcE,
    input               MemWriteE,
    input               RegWriteE,
    input       [31:0]  ALUResultE,
    input       [31:0]  InstrE,
    input       [31:0]  PCPlus4E,
    input       [31:0]  WDE,
    input       [4:0]   WAE,

    output  reg         is_mul_out,
    output  reg         is_div_out,
    output  reg [1:0]   ResultSrcM,
    output  reg         MemWriteM,
    output  reg         RegWriteM,
    output  reg [31:0]  ALUResultM,
    output  reg [31:0]  InstrM,
    output  reg [31:0]  PCPlus4M,
    output  reg [31:0]  WDM,
    output  reg [4:0]   WAM
);

    always @(posedge clk or negedge n_rst) begin
        // reset: MEM 단계 제어 신호 무효화
        if (!n_rst) begin
            is_mul_out  <= 0;
            is_div_out  <= 0;
            ResultSrcM  <= 0;
            MemWriteM   <= 0;
            RegWriteM   <= 0;
            ALUResultM  <= 0;
            InstrM      <= 0;
            PCPlus4M    <= 0;
            WDM         <= 0;
            WAM         <= 0;
        end else if (MDUStall) begin

            // 나눗셈 EX stall 중: MEM으로 NOP 전달, side effect 차단
            is_mul_out  <= 1'b0;
            is_div_out  <= 1'b0;
            ResultSrcM  <= 2'b00;
            MemWriteM   <= 1'b0;
            RegWriteM   <= 1'b0;
            ALUResultM  <= 32'h0;
            InstrM      <= 32'h00000013;
            PCPlus4M    <= 32'h0;
            WDM         <= 32'h0;
            WAM         <= 5'h0;
        end else begin
            // 정상 동작: EX 단계 결과와 제어 신호, MEM 단계 전달
            is_mul_out  <= is_mul_in;
            is_div_out  <= is_div_in;
            ResultSrcM  <= ResultSrcE;
            MemWriteM   <= MemWriteE;
            RegWriteM   <= RegWriteE;
            ALUResultM  <= ALUResultE;
            InstrM      <= InstrE;
            PCPlus4M    <= PCPlus4E;
            WDM         <= WDE;
            WAM         <= WAE;
        end
    end

endmodule
