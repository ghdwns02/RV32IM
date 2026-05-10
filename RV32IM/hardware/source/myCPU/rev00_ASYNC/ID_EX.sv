module ID_EX (

    input               clk,
    input               n_rst,
    input               Flush_ID_EX,

    input       [31:0]  RD1D,
    input       [31:0]  RD2D,
    input       [4:0]   WAD,

    input               BranchD,
    input               jalD,
    input               jalrD,
    input       [1:0]   ResultSrcD,
    input               MemWriteD,
    input       [4:0]   ALUControlD,
    input       [1:0]   ALUSrcAD,
    input               ALUSrcBD,
    input               RegWriteD,
    input       [31:0]  PCPlus4D,
    input       [31:0]  PCD,
    input       [31:0]  ImmExtD,
    input       [31:0]  InstrD,

    output  reg         BranchE,
    output  reg         jalE,
    output  reg         jalrE,
    output  reg [1:0]   ResultSrcE,
    output  reg         MemWriteE,
    output  reg [4:0]   ALUControlE,
    output  reg [1:0]   ALUSrcAE,
    output  reg         ALUSrcBE,
    output  reg         RegWriteE,
    output  reg [31:0]  InstrE,
    output  reg [31:0]  PCPlus4E,
    output  reg [31:0]  PCE,
    output  reg [31:0]  ImmExtE,

    output  reg [4:0]   RA1E,
    output  reg [31:0]  RD1E,
    output  reg [4:0]   RA2E,
    output  reg [31:0]  RD2E,
    output  reg [4:0]   WAE
);

    parameter RESET_PC = 32'h1000_0000;

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            BranchE <= 0;
            jalE <= 0;
            jalrE <= 0;
            ResultSrcE <= 0;
            MemWriteE <= 0;
            ALUControlE <= 0;
            ALUSrcAE <= 0;
            ALUSrcBE <= 0;
            RegWriteE <= 0;
            InstrE <= 32'h00000013;
            PCPlus4E <= 0;
            PCE <= RESET_PC;
            ImmExtE <= 0;
            RA1E <= 0;
            RD1E <= 0;
            RA2E <= 0;
            RD2E <= 0;
            WAE <= 0;
        end else begin
            if (Flush_ID_EX) begin
                BranchE <= 0;
                jalE <= 0;
                jalrE <= 0;
                ResultSrcE <= 0;
                MemWriteE <= 0;
                ALUControlE <= 0;
                ALUSrcAE <= 0;
                ALUSrcBE <= 0;
                RegWriteE <= 0;
                InstrE <= 32'h00000013;
                WAE <= 0;
            end else begin
                BranchE <= BranchD;
                jalE <= jalD;
                jalrE <= jalrD;
                ResultSrcE <= ResultSrcD;
                MemWriteE <= MemWriteD;
                ALUControlE <= ALUControlD;
                ALUSrcAE <= ALUSrcAD;
                ALUSrcBE <= ALUSrcBD;
                RegWriteE <= RegWriteD;
                InstrE <= InstrD;
                PCPlus4E <= PCPlus4D;
                PCE <= PCD;
                ImmExtE <= ImmExtD;
                RA1E <= InstrD[19:15];
                RD1E <= RD1D;
                RA2E <= InstrD[24:20];
                RD2E <= RD2D;
                WAE <= WAD;
            end
        end
    end

endmodule
