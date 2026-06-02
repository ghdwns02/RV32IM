// RV32IM 파이프라인 코어 최상위 wrapper
module riscvpipeline(

    input               clk,
    input               n_rst,
    input       [31:0]  Instr,
    input       [31:0]  ReadData,

    output              MemWriteM,
    output      [31:0]  PC,
    output      [31:0]  ALUResultM,
    output      [31:0]  BE_WD,
    output      [3:0]   ByteEnable
);

    parameter   RESET_PC = 32'h1000_0000;

    // rev00_ASYNC: controller는 InstrD를 직접 보고 ID 단계 제어 신호 생성
    wire            Z_flag, ALUSrcB, RegWrite;
    wire    [1:0]   ResultSrc, ALUSrcA, PCSrc;
    wire    [2:0]   ImmSrc;
    wire    [4:0]   ALUControl;
    wire            Branch, Btaken;
    wire    [31:0]  InstrD;

    // 명령 디코드 결과를 datapath의 ID/EX 레지스터로 전달
    controller u_controller(
        .Z_flag(Z_flag),
        .opcode(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7(InstrD[31:25]),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .Branch(Branch),
        .RegWrite(RegWrite),
        .ALUControl(ALUControl),
        .jal(jal),
        .jalr(jalr)
    );

    // 외부 instruction/data memory 인터페이스와 내부 파이프라인 연결
    datapath #(
        .RESET_PC(RESET_PC)
    ) i_datapath(
        .clk(clk),
        .n_rst(n_rst),
        .Instr(Instr),
        .ReadDataM(ReadData),
        .MemWriteD(MemWrite),
        .MemWriteM(MemWriteM),
        .ResultSrc(ResultSrc),
        .ALUControl(ALUControl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite),
        .Branch(Branch),
        .PC(PC),
        .ALUResultM(ALUResultM),
        .BE_WD(BE_WD),
        .ByteEnable(ByteEnable),
        .Z_flag(Z_flag),
        .jal(jal),
        .jalr(jalr),
        .InstrD(InstrD)
    );

endmodule
