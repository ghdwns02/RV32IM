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
    parameter RESET_PC_SUB4 = 32'h0fff_fffc;

    reg        Stall_Del, Flush_IF_ID_Del;
    reg [31:0] Instr_Del;

    // stall/flush를 한 박자 지연시켜 IF 출력과 InstrD 선택 타이밍을 맞춤
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            Stall_Del       <= 1'b0;
            Flush_IF_ID_Del <= 1'b0;
            Instr_Del       <= 32'h00000013;
        end else begin
            Stall_Del       <= Stall;
            Flush_IF_ID_Del <= Flush_IF_ID;

            if (!Stall || !Stall_Del)
                Instr_Del <= RD;
        end
    end

    // reset/flush 시 NOP, stall 중에는 저장해둔 명령 유지
    always @(*) begin
        if (PC == RESET_PC || PC == RESET_PC_SUB4 || Flush_IF_ID_Del)
            InstrD = 32'h00000013;
        else if (Stall_Del)
            InstrD = Instr_Del;
        else
            InstrD = RD;
    end

    // PC 관련 값은 stall이 아닐 때만 ID 단계로 진행
    always @(posedge clk or negedge n_rst) begin
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
