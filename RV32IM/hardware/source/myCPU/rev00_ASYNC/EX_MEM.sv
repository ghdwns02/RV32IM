module EX_MEM (

    input               clk,
    input               n_rst,

    input       [1:0]   ResultSrcE,
    input               MemWriteE,
    input               RegWriteE,
    input       [31:0]  ALUResultE,
    input       [31:0]  InstrE,
    input       [31:0]  PCPlus4E,
    input       [31:0]  WDE,
    input       [4:0]   WAE,

    output  reg [1:0]   ResultSrcM,
    output  reg         MemWriteM,
    output  reg         RegWriteM,
    output  reg [31:0]  ALUResultM,
    output  reg [31:0]  InstrM,
    output  reg [31:0]  PCPlus4M,
    output  reg [31:0]  WDM,
    output  reg [4:0]   WAM
);

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            ResultSrcM <= 0;
            MemWriteM <= 0;
            RegWriteM <= 0;
            ALUResultM <= 0;
            InstrM <= 0;
            PCPlus4M <= 0;
            WDM <= 0;
            WAM <= 0;
        end else begin
            ResultSrcM <= ResultSrcE;
            MemWriteM <= MemWriteE;
            RegWriteM <= RegWriteE;
            ALUResultM <= ALUResultE;
            InstrM <= InstrE;
            PCPlus4M <= PCPlus4E;
            WDM <= WDE;
            WAM <= WAE;
        end
    end

endmodule
