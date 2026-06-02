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

    output  reg [4:0]   WAW,
    output  reg [31:0]  ReadDataW
);

    // load data와 ALU 결과를 WB 선택 mux까지 정렬
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            ResultSrcW <= 0;
            RegWriteW <= 0;
            PCPlus4W <= 0;
            ALUResultW <= 0;
            ReadDataW <= 0;
            InstrW <= 0;
            WAW <= 0;
        end else begin
            ResultSrcW <= ResultSrcM;
            RegWriteW <= RegWriteM;
            PCPlus4W <= PCPlus4M;
            ALUResultW <= ALUResultM;
            ReadDataW <= ReadDataM;
            InstrW <= InstrM;
            WAW <= WAM;
        end
    end

endmodule
