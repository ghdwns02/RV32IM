module ID_EX (

    input               clk,
    input               n_rst,
    input               Flush_ID_EX,
    input               StallEX,

    input       [31:0]  RD1D,
    input       [31:0]  RD2D,
    input       [4:0]   WAD,
    input       [31:0]  PCPlus4D,
    input       [31:0]  PCD,
    input       [31:0]  InstrD,

    output  reg [31:0]  PCPlus4E,
    output  reg [31:0]  PCE,
    output  reg [31:0]  InstrE,
    output  reg [4:0]   RA1E,
    output  reg [31:0]  RD1E,
    output  reg [4:0]   RA2E,
    output  reg [31:0]  RD2E,
    output  reg [4:0]   WAE
);

    // 제어 신호(ALUControl, ImmSrc, ALUSrcA/B, Branch, RegWrite 등)는
    // EX 스테이지에서 InstrE를 기반으로 조합 디코딩하므로 이 레지스터에서 제거됨
    parameter RESET_PC = 32'h1000_0000;

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            PCPlus4E <= 32'h0;
            PCE      <= RESET_PC;
            InstrE   <= 32'h00000013;
            RA1E     <= 5'h0;
            RD1E     <= 32'h0;
            RA2E     <= 5'h0;
            RD2E     <= 32'h0;
            WAE      <= 5'h0;
        end else begin
            if (Flush_ID_EX) begin
                // NOP(addi x0,x0,0)으로 플러시: EX 디코더가 무해한 제어 신호를 생성
                InstrE <= 32'h00000013;
                WAE    <= 5'h0;
            end else if (!StallEX) begin
                PCPlus4E <= PCPlus4D;
                PCE      <= PCD;
                InstrE   <= InstrD;
                RA1E     <= InstrD[19:15];
                RD1E     <= RD1D;
                RA2E     <= InstrD[24:20];
                RD2E     <= RD2D;
                WAE      <= WAD;
            end
            // StallEX=1 이고 Flush 없음: 모든 레지스터 유지
        end
    end

endmodule
