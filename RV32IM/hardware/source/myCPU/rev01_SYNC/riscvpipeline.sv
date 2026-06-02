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

    // controller와 extend가 EX 스테이지(datapath 내부)로 이동하여
    // ID 스테이지 InstrD 팬아웃 문제를 제거함
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
