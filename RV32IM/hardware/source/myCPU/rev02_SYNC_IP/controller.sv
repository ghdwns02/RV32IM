module controller(

    input               Z_flag,
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

    // opcode 기준의 주 제어 신호 생성
    maindec mdec(
        .Z_flag(Z_flag),
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

    // funct 필드까지 반영해 실제 ALU/MDU 연산 코드 생성
    aludec adec(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .ALUop(ALUop),
        .ALUControl(ALUControl)
    );

endmodule
