// MEM 단계 값을 WB 단계로 전달하는 파이프라인 레지스터
module MEM_WB (

    input               clk,
    input               n_rst,

    input       [1:0]   ResultSrcM,
    input               RegWriteM,
    input       [31:0]  PCPlus4M,
    input       [31:0]  ALUResultM,
    input       [31:0]  InstrM,

    input       [4:0]   WAM,
    input       [31:0]  ReadDataM,

    output  reg [1:0]   ResultSrcW,
    output  reg         RegWriteW,
    output  reg [31:0]  PCPlus4W,
    output  reg [31:0]  ALUResultW,
    output  reg [31:0]  InstrW,

    output  reg [4:0]   WAW
);

    always @(posedge clk or negedge n_rst) begin
        // MEM 단계 결과와 목적지 정보, WB 단계까지 유지
        if (!n_rst) begin
            ResultSrcW <= 0;
            RegWriteW <= 0;
            PCPlus4W <= 0;
            ALUResultW <= 0;
            InstrW <= 0;
            WAW <= 0;
        end else begin
            ResultSrcW <= ResultSrcM;
            RegWriteW <= RegWriteM;
            PCPlus4W <= PCPlus4M;
            ALUResultW <= ALUResultM;
            InstrW <= InstrM;
            WAW <= WAM;
        end
    end

endmodule
