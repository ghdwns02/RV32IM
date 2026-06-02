// opcode 기반 주요 제어 신호 디코딩
module maindec(

    input               Z_flag,
    input       [6:0]   opcode,

    output  reg         MemWrite,
    output  reg         ALUSrcB,
    output  reg         RegWrite,
    output  reg         Branch,
    output  reg [1:0]   ALUSrcA,
    output  reg [1:0]   ResultSrc,
    output  reg [2:0]   ImmSrc,
    output  reg [1:0]   ALUop,
    output              jal,
    output              jalr
);

    // jump 계열은 opcode만으로 바로 식별
    assign jal = (opcode == 7'b110_1111) ? 1'b1 : 1'b0;
    assign jalr = (opcode == 7'b110_0111) ? 1'b1 : 1'b0;

    // 묶음 대입 순서:
    // {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop}
    always@(*) begin
        case(opcode)
            // load, store, R-type, branch, I-type
            7'b000_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_000_00_1001_000;
            7'b010_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b0_001_00_1100_000;
            7'b011_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_000_00_0000_010;
            7'b110_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b0_010_00_0000_101;
            7'b001_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_000_00_1000_011;
            // jal, lui, auipc, jalr, csr/tohost
            7'b110_1111 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_011_00_0010_000;
            7'b011_0111 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_100_10_1000_000;
            7'b001_0111 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_100_01_1000_000;
            7'b110_0111 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b1_000_00_1010_011;
            7'b111_0011 : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'b0_101_00_0000_000;
            default : {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, ResultSrc, Branch, ALUop} = 13'hx;
        endcase
    end

endmodule
