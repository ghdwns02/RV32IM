// 메인 디코더와 ALU 디코더 연결
module controller(

    input       [6:0]   opcode,
    input       [2:0]   funct3,
    input       [6:0]   funct7,

    output              MemWrite,
    output              ALUSrcB,
    output              RegWrite,
    output              Branch,
    output      [1:0]   ALUSrcA,
    output      [1:0]   ResultSrc,
    output      [2:0]   ImmSrc,
    output      [4:0]   ALUControl,
    output              jal,
    output              jalr
);

    wire [1:0] ALUop;

    // maindec: opcode 기반 datapath 주요 제어 흐름 생성
    maindec mdec(
        .opcode(opcode),
        .MemWrite(MemWrite),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .RegWrite(RegWrite),
        .Branch(Branch),
        .ResultSrc(ResultSrc),
        .ImmSrc(ImmSrc),
        .ALUop(ALUop),
        .jal(jal),
        .jalr(jalr)
    );

    // aludec: funct 필드 기반 실제 ALU 연산 코드 생성
    aludec adec(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .ALUop(ALUop),
        .ALUControl(ALUControl)
    );

endmodule
