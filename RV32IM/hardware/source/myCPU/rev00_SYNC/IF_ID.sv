// IF 단계 값을 ID 단계로 전달하는 파이프라인 레지스터
module IF_ID (
    input               clk,
    input               n_rst,
    input               Stall,
    input               Flush_IF_ID,
    input       [31:0]  RD,
    input       [31:0]  PC,
    input       [31:0]  PCPlus4,
    output  reg [31:0]  InstrD,
    output  reg [31:0]  PCD,
    output  reg [31:0]  PCPlus4D
);

    parameter RESET_PC      = 32'h1000_0000;
    parameter RESET_PC_SUB4 = RESET_PC - 32'd4;

    reg        Stall_Del, Flush_IF_ID_Del;
    reg [31:0] Instr_Del;

    always @(posedge clk or negedge n_rst) begin
        // stall/flush 한 박자 지연, 조합 InstrD 선택용
        if (!n_rst) begin
            Stall_Del       <= 1'b0;
            Flush_IF_ID_Del <= 1'b0;
            Instr_Del       <= 32'h00000013;
        end else begin
            Stall_Del       <= Stall;
            Flush_IF_ID_Del <= Flush_IF_ID;

            // stall 진입 직전 명령 저장, ID 단계 유지
            if (!Stall || !Stall_Del)
                Instr_Del <= RD;
        end
    end

    always @(*) begin
        // reset 직후 또는 flush 시 NOP(addi x0,x0,0), ID 단계 전달
        if (PC == RESET_PC || PC == RESET_PC_SUB4 || Flush_IF_ID_Del)
            InstrD = 32'h00000013;
        else if (Stall_Del)
            InstrD = Instr_Del;
        else
            InstrD = RD;
    end

    always @(posedge clk or negedge n_rst) begin
        // PC 관련 값: stall이 아닐 때만 ID 단계 진행
        if (!n_rst) begin
            PCD      <= RESET_PC;
            PCPlus4D <= 32'd0;
        end else begin
            if (!Stall) begin
                PCD      <= PC;
                PCPlus4D <= PCPlus4;
            end
        end
    end

endmodule
