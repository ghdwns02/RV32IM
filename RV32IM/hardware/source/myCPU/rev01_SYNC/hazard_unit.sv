module hazard_unit(

    input       [4:0]   RA1D,       // ID단계 rs1
    input       [4:0]   RA2D,       // ID단계 rs2
    input       [4:0]   WAE,        // EX단계 목적지 레지스터 (load-use 검사용)
    input       [1:0]   ResultSrcE, // 01 = EX단계에 load 명령
    input               RegWriteW,
    input               RegWriteE,
    input       [1:0]   PCSrcE,     // 분기/점프 발생 신호

    input       [4:0]   RA1E,       // EX단계 rs1
    input       [4:0]   RA2E,       // EX단계 rs2
    input       [4:0]   WAM,        // MEM단계 목적지 레지스터
    input               RegWriteM,

    input       [4:0]   WAW,        // WB단계 목적지 레지스터

    // 포워딩 선택: 00=레지스터파일, 01=WB, 10=MEM
    output  reg [1:0]   ForwardAD,
    output  reg [1:0]   ForwardBD,
    output  reg [1:0]   ForwardAE,
    output  reg [1:0]   ForwardBE,
    output  reg         Stall,
    output  reg         Flush_IF_ID,
    output  reg         Flush_ID_EX
);

    // ID단계 포워딩 (분기 조기 판정용)
    always @(*) begin
        if (((RA1D == WAM) && RegWriteM) && (RA1D != 5'd0))
            ForwardAD = 2'b10;
        else if (((RA1D == WAW) && RegWriteW) && (RA1D != 5'd0))
            ForwardAD = 2'b01;
        else
            ForwardAD = 2'b00;
    end

    always @(*) begin
        if (((RA2D == WAM) && RegWriteM) && (RA2D != 5'd0))
            ForwardBD = 2'b10;
        else if (((RA2D == WAW) && RegWriteW) && (RA2D != 5'd0))
            ForwardBD = 2'b01;
        else
            ForwardBD = 2'b00;
    end

    // EX단계 포워딩 (ALU 입력)
    always @(*) begin
        if (((RA1E == WAM) && RegWriteM) && (RA1E != 5'd0))
            ForwardAE = 2'b10;  // MEM 우선
        else if (((RA1E == WAW) && RegWriteW) && (RA1E != 5'd0))
            ForwardAE = 2'b01;
        else
            ForwardAE = 2'b00;
    end

    always @(*) begin
        if (((RA2E == WAM) && RegWriteM) && (RA2E != 5'd0))
            ForwardBE = 2'b10;
        else if (((RA2E == WAW) && RegWriteW) && (RA2E != 5'd0))
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
    end

    // load-use 스톨: EX에 load가 있고 다음 명령이 그 결과를 즉시 사용할 때 1사이클 대기
    always @(*) begin
        if (RegWriteE && ((RA1D == WAE) || (RA2D == WAE)) && (ResultSrcE == 2'b01) && (WAE != 5'd0))
                Stall = 1;
        else
                Stall = 0;
    end

    // 분기/점프 발생 시 IF/ID 플러시
    always @(*) begin
        if (PCSrcE == 2'b01 || PCSrcE == 2'b10)
            Flush_IF_ID = 1;
        else
            Flush_IF_ID = 0;
    end

    // 스톨 또는 분기/점프 시 ID/EX 플러시
    always @(*) begin
        if (Stall || (PCSrcE == 2'b01) || (PCSrcE == 2'b10))
            Flush_ID_EX = 1;
        else
            Flush_ID_EX = 0;
    end

endmodule
