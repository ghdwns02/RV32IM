// 분기 조건 기반 다음 PC 선택값 생성
module branch_logic(

    input               N_flag,
    input               Z_flag,
    input               C_flag,
    input               V_flag,
    input       [2:0]   funct3,
    input               Branch,
    input               jalE,
    input               jalrE,

    output  reg [1:0]   PCSrc
);

    // PCSrc: 00=PC+4, 01=branch/jal target, 10=jalr target(ALUResult)
    always @(*) begin
        if (jalE) begin
            PCSrc = 2'b01;
        end else if (jalrE) begin
            PCSrc = 2'b10;
        end else if (Branch) begin
            PCSrc = 2'b00;
            case (funct3)
                // BEQ/BNE
                3'b000 : if (Z_flag) PCSrc = 2'b01;
                3'b001 : if (~Z_flag) PCSrc = 2'b01;
                // BLT/BGE: 이 버전은 ALU의 N flag 기준
                3'b100 : if (N_flag) PCSrc = 2'b01;
                3'b101 : if (~N_flag) PCSrc = 2'b01;
                // BLTU/BGEU: unsigned 비교는 carry flag 사용
                3'b110 : if (~C_flag) PCSrc = 2'b01;
                3'b111 : if (C_flag) PCSrc = 2'b01;
            endcase
        end else begin
            PCSrc = 2'b00;
        end
    end

endmodule
