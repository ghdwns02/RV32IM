// 파이프라인 hazard, stall, forwarding 신호 생성
module hazard_unit(

    input       [4:0]   RA1D,
    input       [4:0]   RA2D,
    input       [4:0]   WAE,
    input       [1:0]   ResultSrcE,
    input               RegWriteW,
    input               RegWriteE,
    input       [1:0]   PCSrcE,

    input       [4:0]   RA1E,
    input       [4:0]   RA2E,
    input       [4:0]   WAM,
    input               RegWriteM,

    input       [4:0]   WAW,

    output  reg [1:0]   ForwardAD,
    output  reg [1:0]   ForwardBD,
    output  reg [1:0]   ForwardAE,
    output  reg [1:0]   ForwardBE,
    output  reg         Stall,
    output  reg         Flush_IF_ID,
    output  reg         Flush_ID_EX
);

    // ID 단계 branch 비교값: MEM/WB에서 직접 forwarding
    always @(*) begin
        if (((RA1D == WAM) && RegWriteM) && (RA1D != 5'd0))
            ForwardAD = 2'b10;
        else if (((RA1D == WAW) && RegWriteW) && (RA1D != 5'd0))
            ForwardAD = 2'b01;
        else
            ForwardAD = 2'b00;
    end

    // rs2: 같은 우선순위의 ID 단계 forwarding
    always @(*) begin
        if (((RA2D == WAM) && RegWriteM) && (RA2D != 5'd0))
            ForwardBD = 2'b10;
        else if (((RA2D == WAW) && RegWriteW) && (RA2D != 5'd0))
            ForwardBD = 2'b01;
        else
            ForwardBD = 2'b00;
    end

    // EX 단계 ALU 입력: 최신 MEM 결과를 WB보다 우선
    always @(*) begin
        if (((RA1E == WAM) && RegWriteM) && (RA1E != 5'd0))
            ForwardAE = 2'b10;
        else if (((RA1E == WAW) && RegWriteW) && (RA1E != 5'd0))
            ForwardAE = 2'b01;
        else
            ForwardAE = 2'b00;
    end

    // EX 단계 두 번째 피연산자: 동일 forwarding 규칙
    always @(*) begin
        if (((RA2E == WAM) && RegWriteM) && (RA2E != 5'd0))
            ForwardBE = 2'b10;
        else if (((RA2E == WAW) && RegWriteW) && (RA2E != 5'd0))
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
    end

    // load 결과: MEM 이후 유효, 바로 다음 명령 사용 시 1사이클 stall
    always @(*) begin
        if (RegWriteE && ((RA1D == WAE) || (RA2D == WAE)) && (ResultSrcE == 2'b01) && (WAE != 5'd0))
                Stall = 1;
        else
                Stall = 0;
    end

    // branch/jump 결정 시 이미 가져온 IF/ID 명령 폐기
    always @(*) begin
        if (PCSrcE == 2'b01 || PCSrcE == 2'b10)
            Flush_IF_ID = 1;
        else
            Flush_IF_ID = 0;
    end

    // load-use stall 또는 PC 변경 시 ID/EX에 NOP 삽입
    always @(*) begin
        if (Stall || (PCSrcE == 2'b01) || (PCSrcE == 2'b10))
            Flush_ID_EX = 1;
        else
            Flush_ID_EX = 0;
    end

endmodule
