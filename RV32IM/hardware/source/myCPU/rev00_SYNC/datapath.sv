// 파이프라인 데이터 경로와 스테이지 연결
module datapath(
    input               clk,
    input               n_rst,
    input       [31:0]  Instr,
    input       [31:0]  ReadDataM,
    output              MemWriteM,
    output      [31:0]  PC,
    output      [31:0]  ALUResultM,
    output      [31:0]  BE_WD,
    output      [3:0]   ByteEnable
);

    parameter RESET_PC = 32'h1000_0000;

    wire            N_flag, Z_flag, C_flag, V_flag;

    wire    [31:0]  PC_next, PC_target;
    wire    [1:0]   PCSrc;
    wire    [31:0]  PCPlus4, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W;

    wire    [31:0]  InstrD;
    wire    [31:0]  InstrE, InstrM, InstrW;

    wire    [2:0]   ImmSrcD;
    wire    [1:0]   ResultSrcD;
    wire            MemWriteD;
    wire    [4:0]   ALUControlD;
    wire    [1:0]   ALUSrcAD;
    wire            ALUSrcBD;
    wire            RegWriteD;
    wire            BranchD, jalD, jalrD;
    wire    [31:0]  ImmExtD;

    wire    [31:0]  ImmExtE;
    wire            BranchE, jalE, jalrE;
    wire    [1:0]   ResultSrcE;
    wire            MemWriteE;
    wire    [4:0]   ALUControlE;
    wire    [1:0]   ALUSrcAE;
    wire            ALUSrcBE;
    wire            RegWriteE;

    wire    [31:0]  SrcA, SrcB;
    wire    [31:0]  ALUResult, ALUResultW;

    wire            RegWriteM, RegWriteW;
    wire    [4:0]   WAE, WAM, WAW;
    wire    [31:0]  RD1D, RD2D;
    wire    [4:0]   RA1E, RA2E;
    wire    [31:0]  RD1E, RD2E;

    wire    [1:0]   ResultSrcM, ResultSrcW;
    wire    [31:0]  WDM;
    wire    [31:0]  ResultW;
    wire    [31:0]  PCD, PCE;

    wire    [31:0]  rd1_data, rd2_data;
    wire    [31:0]  RD1E_mux, RD2E_mux;
    wire    [1:0]   ForwardAD, ForwardBD;
    wire    [1:0]   ForwardAE, ForwardBE;
    wire            Stall, Flush_IF_ID, Flush_ID_EX;

    wire    [31:0]  BE_RD;

    wire            is_mul_in_EX  = (ALUControlE[4:2] == 3'b101);
    wire            is_div_in_EX  = (ALUControlE[4:3] == 2'b11);
    wire            is_mul_in_MEM;
    wire            is_div_in_MEM;

    wire    [31:0]  mul_result;
    wire    [31:0]  div_result;
    wire            div_half_done;

    // 곱셈: 1사이클 등록, 나눗셈: 내부 phase 완료까지 EX stall
    wire            mul_start = is_mul_in_EX;

    wire            div_start = is_div_in_EX;

    wire            MDUStall  = is_div_in_EX & ~div_half_done;
    wire            Stall_all = Stall | MDUStall;

    wire    [31:0]  ALUResultM_eff = is_div_in_MEM ? div_result :
                                     is_mul_in_MEM ? mul_result : ALUResultM;

    wire            Csr = (InstrE[6:0] == 7'b111_0011) ? 1 : 0;
    reg     [31:0]  tohost_csr;

    always @(posedge clk) begin
        // 테스트 프로그램 tohost CSR write 값 관찰용 경로
        if (Csr == 1'b1) begin
            case (InstrE[14:12])
                3'b001 : tohost_csr <= RD1E_mux;
                3'b101 : tohost_csr <= ImmExtE;
                default : tohost_csr <= 32'd0;
            endcase
        end
        else
            tohost_csr <= 32'd0;
    end

    // 제어 신호와 immediate: ID가 아닌 EX의 등록된 InstrE 기준 생성
    controller u_controller(
        .opcode     (InstrD[6:0]),
        .funct3     (InstrD[14:12]),
        .funct7     (InstrD[31:25]),
        .ResultSrc  (ResultSrcD),
        .MemWrite   (MemWriteD),
        .ALUSrcA    (ALUSrcAD),
        .ALUSrcB    (ALUSrcBD),
        .ImmSrc     (ImmSrcD),
        .Branch     (BranchD),
        .RegWrite   (RegWriteD),
        .ALUControl (ALUControlD),
        .jal        (jalD),
        .jalr       (jalrD)
    );

    extend u_Extend(
        .ImmSrc (ImmSrcD),
        .in     (InstrD),
        .out    (ImmExtD)
    );

    // RV32M 곱셈/나눗셈 유닛: ALU 입력과 같은 forwarding 결과 사용
    mul_unit u_mul_unit(
        .clk        (clk),
        .n_rst      (n_rst),
        .a_in       (SrcA),
        .b_in       (SrcB),
        .ALUControl (ALUControlE),
        .start      (mul_start),
        .result     (mul_result)
    );

    div_unit u_div_unit(
        .clk        (clk),
        .n_rst      (n_rst),
        .a_in       (SrcA),
        .b_in       (SrcB),
        .ALUControl (ALUControlE),
        .start      (div_start),
        .result     (div_result),
        .half_done  (div_half_done),
        .done       ()
    );

    // 파이프라인 레지스터: stall/flush에 맞춘 명령과 제어 흐름 정렬
    IF_ID u_IF_ID(
        .clk         (clk),
        .n_rst       (n_rst),
        .Stall       (Stall_all),
        .Flush_IF_ID (Flush_IF_ID),
        .RD          (Instr),
        .PC          (PC),
        .PCPlus4     (PCPlus4),
        .InstrD      (InstrD),
        .PCD         (PCD),
        .PCPlus4D    (PCPlus4D)
    );

    ID_EX u_ID_EX(
        .clk          (clk),
        .n_rst        (n_rst),
        .Flush_ID_EX  (Flush_ID_EX),
        .StallEX      (MDUStall),
        .RD1D         (RD1D),
        .RD2D         (RD2D),
        .WAD          (InstrD[11:7]),
        .PCPlus4D     (PCPlus4D),
        .PCD          (PCD),
        .InstrD       (InstrD),
        .ALUControlD  (ALUControlD),
        .ALUSrcAD     (ALUSrcAD),
        .ALUSrcBD     (ALUSrcBD),
        .ResultSrcD   (ResultSrcD),
        .MemWriteD    (MemWriteD),
        .RegWriteD    (RegWriteD),
        .BranchD      (BranchD),
        .jalD         (jalD),
        .jalrD        (jalrD),
        .ImmExtD      (ImmExtD),
        .PCPlus4E     (PCPlus4E),
        .PCE          (PCE),
        .InstrE       (InstrE),
        .RA1E         (RA1E),
        .RD1E         (RD1E),
        .RA2E         (RA2E),
        .RD2E         (RD2E),
        .WAE          (WAE),
        .ALUControlE  (ALUControlE),
        .ALUSrcAE     (ALUSrcAE),
        .ALUSrcBE     (ALUSrcBE),
        .ResultSrcE   (ResultSrcE),
        .MemWriteE    (MemWriteE),
        .RegWriteE    (RegWriteE),
        .BranchE      (BranchE),
        .jalE         (jalE),
        .jalrE        (jalrE),
        .ImmExtE      (ImmExtE)
    );

    EX_MEM u_EX_MEM(
        .clk          (clk),
        .n_rst        (n_rst),
        .MDUStall     (MDUStall),
        .is_mul_in    (is_mul_in_EX),
        .is_div_in    (is_div_in_EX),
        .ResultSrcE   (ResultSrcE),
        .MemWriteE    (MemWriteE),
        .RegWriteE    (RegWriteE),
        .ALUResultE   (ALUResult),
        .InstrE       (InstrE),
        .PCPlus4E     (PCPlus4E),
        .WDE          (RD2E_mux),
        .WAE          (WAE),
        .is_mul_out   (is_mul_in_MEM),
        .is_div_out   (is_div_in_MEM),
        .ResultSrcM   (ResultSrcM),
        .MemWriteM    (MemWriteM),
        .RegWriteM    (RegWriteM),
        .ALUResultM   (ALUResultM),
        .InstrM       (InstrM),
        .PCPlus4M     (PCPlus4M),
        .WDM          (WDM),
        .WAM          (WAM)
    );

    MEM_WB u_MEM_WB(
        .clk          (clk),
        .n_rst        (n_rst),
        .ResultSrcM   (ResultSrcM),
        .RegWriteM    (RegWriteM),
        .ALUResultM   (ALUResultM_eff),
        .PCPlus4M     (PCPlus4M),
        .InstrM       (InstrM),
        .WAM          (WAM),
        .ReadDataM    (ReadDataM),
        .ResultSrcW   (ResultSrcW),
        .RegWriteW    (RegWriteW),
        .PCPlus4W     (PCPlus4W),
        .ALUResultW   (ALUResultW),
        .InstrW       (InstrW),
        .WAW          (WAW)
    );

    // ID/EX 입력: MEM/WB 결과 forwarding으로 RAW hazard 감소
    mux3 u_RD1_D(
        .in0 (rd1_data),
        .in1 (ResultW),
        .in2 (ALUResultM_eff),
        .sel (ForwardAD),
        .out (RD1D)
    );

    mux3 u_RD2_D(
        .in0 (rd2_data),
        .in1 (ResultW),
        .in2 (ALUResultM_eff),
        .sel (ForwardBD),
        .out (RD2D)
    );

    mux3 u_RD1_E(
        .in0 (RD1E),
        .in1 (ResultW),
        .in2 (ALUResultM_eff),
        .sel (ForwardAE),
        .out (RD1E_mux)
    );

    mux3 u_RD2_E(
        .in0 (RD2E),
        .in1 (ResultW),
        .in2 (ALUResultM_eff),
        .sel (ForwardBE),
        .out (RD2E_mux)
    );

    // PC: 기본 PC+4, branch/jump 시 target 또는 jalr 주소 선택
    mux3 u_pc_mux3(
        .in0 (PCPlus4),
        .in1 (PC_target),
        .in2 (ALUResult),
        .sel (PCSrc),
        .out (PC_next)
    );

    flopenr #(.RESET_VALUE(RESET_PC)) u_pc_register(
        .clk   (clk),
        .n_rst (n_rst),
        .en    (!Stall_all),
        .d     (PC_next),
        .q     (PC)
    );

    adder u_pc_plus4(
        .a   (PC),
        .b   (32'h4),
        .ci  (1'b0),
        .sum (PCPlus4),
        .N   (),
        .Z   (),
        .C   (),
        .V   ()
    );

    adder u_pc_target(
        .a   (PCE),
        .b   (ImmExtE),
        .ci  (1'b0),
        .sum (PC_target),
        .N   (),
        .Z   (),
        .C   (),
        .V   ()
    );

    // ID 단계: 레지스터 파일 read, WB 단계: 선택된 ResultW write
    reg_file_async rf(
        .clkb (clk),
        .we   (RegWriteW),
        .ra1  (InstrD[19:15]),
        .ra2  (InstrD[24:20]),
        .wa   (WAW),
        .wd   (ResultW),
        .rd1  (rd1_data),
        .rd2  (rd2_data)
    );

    // ALU 입력: 레지스터 값, PC, immediate 중 명령별 선택
    mux3 u_SrcA_mux3(
        .in0 (RD1E_mux),
        .in1 (PCE),
        .in2 (32'd0),
        .sel (ALUSrcAE),
        .out (SrcA)
    );

    mux2 u_SrcB_mux2(
        .in0 (RD2E_mux),
        .in1 (ImmExtE),
        .sel (ALUSrcBE),
        .out (SrcB)
    );

    alu u_ALU(
        .a_in       (SrcA),
        .b_in       (SrcB),
        .ALUControl (ALUControlE),
        .result     (ALUResult),
        .aN         (N_flag),
        .aZ         (Z_flag),
        .aC         (C_flag),
        .aV         (V_flag)
    );

    // WB 결과: ALU 결과, load 데이터, PC+4 중 하나
    mux3 u_result_mux3(
        .in0 (ALUResultW),
        .in1 (BE_RD),
        .in2 (PCPlus4W),
        .sel (ResultSrcW),
        .out (ResultW)
    );

    // branch_logic: ALU flag와 branch/jump 제어 신호로 PCSrc 결정
    branch_logic u_branch_logic(
        .N_flag  (N_flag),
        .Z_flag  (Z_flag),
        .C_flag  (C_flag),
        .V_flag  (V_flag),
        .funct3  (InstrE[14:12]),
        .Branch  (BranchE),
        .jalE    (jalE),
        .jalrE   (jalrE),
        .PCSrc   (PCSrc)
    );

    // load/store byte/halfword 접근: be_logic의 byte enable과 정렬 처리
    be_logic u_be_logic(
        .AddrLast2M (ALUResultM[1:0]),
        .funct3M    (InstrM[14:12]),
        .AddrLast2W (ALUResultW[1:0]),
        .funct3W    (InstrW[14:12]),
        .WD         (WDM),
        .RD         (ReadDataM),
        .ByteEnable (ByteEnable),
        .BE_WD      (BE_WD),
        .BE_RD      (BE_RD)
    );

    // hazard_unit: forwarding 선택, load-use stall, flush 신호 생성
    hazard_unit u_hazard_unit(
        .RA1D       (InstrD[19:15]),
        .RA2D       (InstrD[24:20]),
        .WAE        (WAE),
        .WAM        (WAM),
        .WAW        (WAW),
        .RegWriteE  (RegWriteE),
        .RegWriteM  (RegWriteM),
        .RegWriteW  (RegWriteW),
        .ResultSrcE (ResultSrcE),
        .PCSrcE     (PCSrc),
        .ForwardAD  (ForwardAD),
        .ForwardBD  (ForwardBD),
        .ForwardAE  (ForwardAE),
        .ForwardBE  (ForwardBE),
        .Stall      (Stall),
        .Flush_IF_ID(Flush_IF_ID),
        .Flush_ID_EX(Flush_ID_EX),
        .RA1E       (RA1E),
        .RA2E       (RA2E)
    );

endmodule
