// ID 단계 값을 EX 단계로 전달하는 파이프라인 레지스터
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

    input       [4:0]   ALUControlD,
    input       [1:0]   ALUSrcAD,
    input               ALUSrcBD,
    input       [1:0]   ResultSrcD,
    input               MemWriteD,
    input               RegWriteD,
    input               BranchD,
    input               jalD,
    input               jalrD,
    input       [31:0]  ImmExtD,

    output  reg [31:0]  PCPlus4E,
    output  reg [31:0]  PCE,
    output  reg [31:0]  InstrE,
    output  reg [4:0]   RA1E,
    output  reg [31:0]  RD1E,
    output  reg [4:0]   RA2E,
    output  reg [31:0]  RD2E,
    output  reg [4:0]   WAE,

    output  reg [4:0]   ALUControlE,
    output  reg [1:0]   ALUSrcAE,
    output  reg         ALUSrcBE,
    output  reg [1:0]   ResultSrcE,
    output  reg         MemWriteE,
    output  reg         RegWriteE,
    output  reg         BranchE,
    output  reg         jalE,
    output  reg         jalrE,
    output  reg [31:0]  ImmExtE
);

    parameter RESET_PC = 32'h1000_0000;

    always @(posedge clk or negedge n_rst) begin
        // reset/flush 시 EX 단계 NOP 동작용 instruction 초기화
        if (!n_rst) begin
            PCPlus4E   <= 32'h0;
            PCE        <= RESET_PC;
            InstrE     <= 32'h00000013;
            RA1E       <= 5'h0;
            RD1E       <= 32'h0;
            RA2E       <= 5'h0;
            RD2E       <= 32'h0;
            WAE        <= 5'h0;
            ALUControlE <= 5'h0;
            ALUSrcAE   <= 2'h0;
            ALUSrcBE   <= 1'h0;
            ResultSrcE <= 2'h0;
            MemWriteE  <= 1'h0;
            RegWriteE  <= 1'h0;
            BranchE    <= 1'h0;
            jalE       <= 1'h0;
            jalrE      <= 1'h0;
            ImmExtE    <= 32'h0;
        end else begin
            if (Flush_ID_EX) begin
                // branch/jump 또는 load-use stall 시 잘못 들어온 명령 writeback 차단
                InstrE     <= 32'h00000013;
                WAE        <= 5'h0;
                ALUControlE <= 5'h0;
                ALUSrcAE   <= 2'h0;
                ALUSrcBE   <= 1'h0;
                ResultSrcE <= 2'h0;
                MemWriteE  <= 1'h0;
                RegWriteE  <= 1'h0;
                BranchE    <= 1'h0;
                jalE       <= 1'h0;
                jalrE      <= 1'h0;
                ImmExtE    <= 32'h0;
            end else if (!StallEX) begin
                // 나눗셈 stall 없음: ID 단계 피연산자와 명령 필드, EX 전달
                PCPlus4E   <= PCPlus4D;
                PCE        <= PCD;
                InstrE     <= InstrD;
                RA1E       <= InstrD[19:15];
                RD1E       <= RD1D;
                RA2E       <= InstrD[24:20];
                RD2E       <= RD2D;
                WAE        <= WAD;
                ALUControlE <= ALUControlD;
                ALUSrcAE   <= ALUSrcAD;
                ALUSrcBE   <= ALUSrcBD;
                ResultSrcE <= ResultSrcD;
                MemWriteE  <= MemWriteD;
                RegWriteE  <= RegWriteD;
                BranchE    <= BranchD;
                jalE       <= jalD;
                jalrE      <= jalrD;
                ImmExtE    <= ImmExtD;
            end
        end
    end

endmodule
