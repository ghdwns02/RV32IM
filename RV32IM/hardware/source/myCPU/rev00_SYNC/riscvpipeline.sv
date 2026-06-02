// RV32IM 파이프라인 코어 최상위 모듈
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

    // 외부 메모리 인터페이스와 내부 datapath 신호 연결 wrapper
    datapath #(
        .RESET_PC(RESET_PC)
    ) i_datapath(
        .clk        (clk),
        .n_rst      (n_rst),
        .Instr      (Instr),
        .ReadDataM  (ReadData),
        .MemWriteM  (MemWriteM),
        .PC         (PC),
        .ALUResultM (ALUResultM),
        .BE_WD      (BE_WD),
        .ByteEnable (ByteEnable)
    );

endmodule
