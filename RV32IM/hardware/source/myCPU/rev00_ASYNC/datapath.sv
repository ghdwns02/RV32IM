module datapath(

    input               clk,
    input               n_rst,
    input               ALUSrcB,
    input               RegWrite,
    input       [31:0]  Instr,
    input       [31:0]  ReadDataM,
    input       [1:0]   ResultSrc,
    input       [1:0]   ALUSrcA,
    input       [2:0]   ImmSrc,
    input       [4:0]   ALUControl,
    input               Branch,
    input               jal,
    input               jalr,
    input               MemWriteD,

    output              MemWriteM,
    output      [31:0]  InstrD,
    output      [31:0]  PC,
    output      [31:0]  ALUResultM,
    output      [31:0]  BE_WD,
    output      [3:0]   ByteEnable,
    output              Z_flag
);

    parameter RESET_PC = 32'h1000_0000;

    wire            N_flag, C_flag, V_flag;
    wire    [31:0]  PC_next, PC_target;
    wire    [31:0]  ImmExt;
    wire    [31:0]  SrcA, SrcB;

    wire    [1:0]   PCSrc;
    wire    [31:0]  PCPlus4, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W;
    wire    [31:0]  InstrE, InstrM, InstrW;

    wire            BranchE;
    wire            jalE, jalrE;
    wire    [1:0]   ResultSrcE;
    wire            MemWriteE;

    wire    [4:0]   ALUControlE;
    wire    [1:0]   ALUSrcAE;
    wire            ALUSrcBE;
    wire    [31:0]  ALUResult, ALUResultW;

    wire            RegWriteE, RegWriteM, RegWriteW;
    wire    [31:0]  PCD, PCE;
    wire    [31:0]  ImmExtE;

    wire    [4:0]   WAE, WAM, WAW;
    wire    [31:0]  WDM;
    wire    [31:0]  RD1D, RD2D;
    wire    [4:0]   RA1E, RA2E;
    wire    [31:0]  RD1E, RD2E;

    wire    [1:0]   ResultSrcM, ResultSrcW;
    wire    [31:0]  ReadDataW;
    wire    [31:0]  ResultW;

    wire    [31:0]  rd1_data, rd2_data;
    wire            Stall, Flush_IF_ID, Flush_ID_EX;

    wire    [31:0]  BE_RD;
    wire    [31:0]  RD1E_mux, RD2E_mux;
    wire    [1:0]   ForwardAD, ForwardBD, ForwardAE, ForwardBE;

    wire            Csr = (InstrE[6:0] == 7'b111_0011) ? 1 : 0;

    reg     [31:0]  tohost_csr;

    always @(posedge clk) begin
        if (Csr == 1'b1) begin
            case (InstrE[14:12])
                3'b001 : tohost_csr = RD1E_mux;
                3'b101 : tohost_csr = ImmExtE;
                default : tohost_csr = 32'd0;
            endcase
        end
        else
            tohost_csr = 32'd0;
    end

    IF_ID u_IF_ID(
        .clk(clk),
        .n_rst(n_rst),
        .Stall(Stall),
        .Flush_IF_ID(Flush_IF_ID),

        .RD(Instr),
        .PC(PC),
        .PCPlus4(PCPlus4),

        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D)
    );

    ID_EX u_ID_EX(
        .clk(clk),
        .n_rst(n_rst),
        .Flush_ID_EX(Flush_ID_EX),

        .RD1D(RD1D),
        .RD2D(RD2D),
        .WAD(InstrD[11:7]),

        .BranchD(Branch),
        .jalD(jal),
        .jalrD(jalr),
        .ResultSrcD(ResultSrc),
        .MemWriteD(MemWriteD),
        .ALUControlD(ALUControl),
        .ALUSrcAD(ALUSrcA),
        .ALUSrcBD(ALUSrcB),
        .RegWriteD(RegWrite),
        .PCPlus4D(PCPlus4D),
        .PCD(PCD),
        .ImmExtD(ImmExt),
        .InstrD(InstrD),

        .BranchE(BranchE),
        .jalE(jalE),
        .jalrE(jalrE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .ALUControlE(ALUControlE),
        .ALUSrcAE(ALUSrcAE),
        .ALUSrcBE(ALUSrcBE),
        .RegWriteE(RegWriteE),
        .InstrE(InstrE),
        .PCPlus4E(PCPlus4E),
        .PCE(PCE),
        .ImmExtE(ImmExtE),

        .RA1E(RA1E),
        .RD1E(RD1E),
        .RA2E(RA2E),
        .RD2E(RD2E),
        .WAE(WAE)
    );

    EX_MEM u_EX_MEM(
        .clk(clk),
        .n_rst(n_rst),

        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .RegWriteE(RegWriteE),
        .ALUResultE(ALUResult),
        .InstrE(InstrE),
        .PCPlus4E(PCPlus4E),
        .WDE(RD2E_mux),
        .WAE(WAE),

        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .RegWriteM(RegWriteM),
        .ALUResultM(ALUResultM),
        .InstrM(InstrM),
        .PCPlus4M(PCPlus4M),
        .WDM(WDM),
        .WAM(WAM)
    );

    MEM_WB u_MEM_WB(
        .clk(clk),
        .n_rst(n_rst),

        .ResultSrcM(ResultSrcM),
        .RegWriteM(RegWriteM),
        .ALUResultM(ALUResultM),
        .PCPlus4M(PCPlus4M),
        .InstrM(InstrM),

        .WAM(WAM),
        .ReadDataM(ReadDataM),

        .ResultSrcW(ResultSrcW),
        .RegWriteW(RegWriteW),
        .PCPlus4W(PCPlus4W),
        .ALUResultW(ALUResultW),
        .InstrW(InstrW),

        .WAW(WAW),
        .ReadDataW(ReadDataW)
    );

    mux3 u_RD1_D(
        .in0(rd1_data),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardAD),
        .out(RD1D)
    );

    mux3 u_RD2_D(
        .in0(rd2_data),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardBD),
        .out(RD2D)
    );

    mux3 u_RD1_E(
        .in0(RD1E),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardAE),
        .out(RD1E_mux)
    );

    mux3 u_RD2_E(
        .in0(RD2E),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardBE),
        .out(RD2E_mux)
    );

    mux3 u_pc_mux3(
        .in0(PCPlus4),
        .in1(PC_target),
        .in2(ALUResult),
        .sel(PCSrc),
        .out(PC_next)
    );

    flopenr #(
        .RESET_VALUE(RESET_PC)
    )  u_pc_register(
        .clk(clk),
        .n_rst(n_rst),
        .en(!Stall),
        .d(PC_next),
        .q(PC)
    );

    adder u_pc_plus4(
        .a(PC),
        .b(32'h4),
        .ci(1'b0),
        .sum(PCPlus4),
        .N(),
        .Z(),
        .C(),
        .V()
    );

    extend u_Extend(
        .ImmSrc(ImmSrc),
        .in(InstrD),
        .out(ImmExt)
    );

    adder u_pc_target(
        .a(PCE),
        .b(ImmExtE),
        .ci(1'b0),
        .sum(PC_target),
        .N(),
        .Z(),
        .C(),
        .V()
    );

    reg_file_async rf(
        .clk(clk),
        .clkb(clk),
        .we(RegWriteW),
        .ra1(InstrD[19:15]),
        .ra2(InstrD[24:20]),
        .wa(WAW),
        .wd(ResultW),
        .rd1(rd1_data),
        .rd2(rd2_data)
    );

    mux3 u_SrcA_mux3(
        .in0(RD1E_mux),
        .in1(PCE),
        .in2(32'd0),
        .sel(ALUSrcAE),
        .out(SrcA)
    );

    mux2 u_SrcB_mux2(
        .in0(RD2E_mux),
        .in1(ImmExtE),
        .sel(ALUSrcBE),
        .out(SrcB)
    );

    alu u_ALU(
        .a_in(SrcA),
        .b_in(SrcB),
        .ALUControl(ALUControlE),
        .result(ALUResult),
        .aN(N_flag),
        .aZ(Z_flag),
        .aC(C_flag),
        .aV(V_flag)
    );

    mux3 u_result_mux3(
        .in0(ALUResultW),
        .in1(BE_RD),
        .in2(PCPlus4W),
        .sel(ResultSrcW),
        .out(ResultW)
    );

    branch_logic u_branch_logic(
        .N_flag(N_flag),
        .Z_flag(Z_flag),
        .C_flag(C_flag),
        .V_flag(V_flag),
        .funct3(InstrE[14:12]),
        .Branch(BranchE),

        .jalE(jalE),
        .jalrE(jalrE),
        .PCSrc(PCSrc)
    );

    be_logic u_be_logic(
        .AddrLast2M(ALUResultM[1:0]),
        .funct3M(InstrM[14:12]),
        .AddrLast2W(ALUResultW[1:0]),
        .funct3W(InstrW[14:12]),
        .WD(WDM),
        .RD(ReadDataW),
        .ByteEnable(ByteEnable),
        .BE_WD(BE_WD),
        .BE_RD(BE_RD)
    );

    hazard_unit u_hazard_unit(
        .RA1D(InstrD[19:15]),
        .RA2D(InstrD[24:20]),
        .WAE(WAE),
        .WAM(WAM),
        .RegWriteM(RegWriteM),
        .WAW(WAW),
        .RegWriteW(RegWriteW),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .PCSrcE(PCSrc),
        .ForwardAD(ForwardAD),
        .ForwardBD(ForwardBD),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .Stall(Stall),
        .Flush_IF_ID(Flush_IF_ID),
        .Flush_ID_EX(Flush_ID_EX),
        .RA1E(RA1E),
        .RA2E(RA2E)
    );

endmodule
