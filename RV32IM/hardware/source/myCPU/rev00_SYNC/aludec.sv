// 명령어 필드 기반 ALU 제어값 디코딩
module aludec(
    input       [6:0]   opcode,
    input       [2:0]   funct3,
    input       [1:0]   ALUop,
    input       [6:0]   funct7,
    output  reg [4:0]   ALUControl
);

    always @(*) begin
        // ALUop: maindec에서 만든 큰 분류값
        // 00: 주소 계산(load/store), 01: branch 비교용 뺄셈
        if (ALUop == 2'b00) begin
            ALUControl = 5'b00000;       // ADD 주소 계산: load/store
        end
        else if (ALUop == 2'b01) begin
            ALUControl = 5'b00001;       // SUB 비교: branch
        end
        else if (ALUop == 2'b10) begin

            // R-type funct7=0000001: RV32M 곱셈/나눗셈 명령
            if (opcode == 7'b011_0011 && funct7 == 7'b000_0001) begin
                case (funct3)
                    3'b000: ALUControl = 5'b10100;   // MUL
                    3'b001: ALUControl = 5'b10101;   // MULH
                    3'b010: ALUControl = 5'b10110;   // MULHSU
                    3'b011: ALUControl = 5'b10111;   // MULHU
                    3'b100: ALUControl = 5'b11000;   // DIV
                    3'b101: ALUControl = 5'b11001;   // DIVU
                    3'b110: ALUControl = 5'b11010;   // REM
                    3'b111: ALUControl = 5'b11011;   // REMU
                    default: ALUControl = 5'hx;
                endcase
            end
            else begin
                // 일반 R-type ALU 명령: funct3와 funct7[5]로 세부 연산 구분
                case (funct3)
                    3'b000 : ALUControl = (funct7[5]) ? 5'b00001 : 5'b00000; // SUB / ADD
                    3'b001 : ALUControl = 5'b00110;                          // SLL
                    3'b010 : ALUControl = 5'b00101;                          // SLT
                    3'b011 : ALUControl = 5'b10000;                          // SLTU
                    3'b100 : ALUControl = 5'b00100;                          // XOR
                    3'b101 : ALUControl = (funct7[5]) ? 5'b01000 : 5'b00111; // SRA / SRL
                    3'b110 : ALUControl = 5'b00011;                          // OR
                    3'b111 : ALUControl = 5'b00010;                          // AND
                    default : ALUControl = 5'hx;
                endcase
            end
        end
        else if (ALUop == 2'b11) begin
            // I-type ALU와 jalr: 같은 ALUop, opcode로 jalr 구분
            case (funct3)
                3'b000 : ALUControl = (opcode == 7'b1100111) ? 5'b01001 : 5'b00000; // JALR / ADDI
                3'b001 : ALUControl = 5'b00110;                                     // SLLI
                3'b010 : ALUControl = 5'b00101;                                     // SLTI
                3'b011 : ALUControl = 5'b10000;                                     // SLTIU
                3'b100 : ALUControl = 5'b00100;                                     // XORI
                3'b101 : ALUControl = (funct7[5]) ? 5'b01000 : 5'b00111;            // SRAI / SRLI
                3'b110 : ALUControl = 5'b00011;                                     // ORI
                3'b111 : ALUControl = 5'b00010;                                     // ANDI
                default : ALUControl = 5'hx;
            endcase
        end
        else begin
            ALUControl = 5'hx;
        end
    end
endmodule
