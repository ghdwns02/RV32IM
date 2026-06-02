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

    // EX/MEM 파이프라인 레지스터
    // DIV 대기 중에는 MEM 단계에 NOP 성격의 값만 전달
    always @(posedge clk or negedge n_rst) begin
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
