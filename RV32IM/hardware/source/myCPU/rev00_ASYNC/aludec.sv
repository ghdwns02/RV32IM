// 명령어 필드 기반 ALU 제어값 디코딩
module aludec(
    input       [6:0]   opcode,
    input       [2:0]   funct3,
    input       [1:0]   ALUop,
    input       [6:0]   funct7,
    output  reg [4:0]   ALUControl
);

    // ALUop로 큰 명령군을 나누고, funct3/funct7로 세부 연산 결정
    always @(*) begin
        if (ALUop == 2'b00) begin
            // load/store 주소 계산: ADD
            ALUControl = 5'b00000;
        end
        else if (ALUop == 2'b01) begin
            // branch 비교용: SUB
            ALUControl = 5'b00001;
        end
        else if (ALUop == 2'b10) begin

            // R-type RV32M: funct7[0]=1이면 MUL/DIV/REM 계열
            if (opcode == 7'b011_0011 && funct7[0] == 1'b1) begin
                case (funct3)
                    3'b000: ALUControl = 5'b10100;
                    3'b001: ALUControl = 5'b10101;
                    3'b010: ALUControl = 5'b10110;
                    3'b011: ALUControl = 5'b10111;
                    3'b100: ALUControl = 5'b11000;
                    3'b101: ALUControl = 5'b11001;
                    3'b110: ALUControl = 5'b11010;
                    3'b111: ALUControl = 5'b11011;
                    default: ALUControl = 5'hx;
                endcase
            end
            else begin
                // 일반 R-type ALU 명령
                case (funct3)
                    3'b000 : ALUControl = (funct7[5]) ? 5'b00001 : 5'b00000;
                    3'b001 : ALUControl = 5'b00110;
                    3'b010 : ALUControl = 5'b00101;
                    3'b011 : ALUControl = 5'b10000;
                    3'b100 : ALUControl = 5'b00100;
                    3'b101 : ALUControl = (funct7[5]) ? 5'b01000 : 5'b00111;
                    3'b110 : ALUControl = 5'b00011;
                    3'b111 : ALUControl = 5'b00010;
                    default : ALUControl = 5'hx;
                endcase
            end
        end
        else if (ALUop == 2'b11) begin
            // I-type ALU 및 JALR 주소 계산
            case (funct3)
                3'b000 : ALUControl = (opcode == 7'b1100111) ? 5'b01001 : 5'b01101;
                3'b001 : ALUControl = 5'b01100;
                3'b010 : ALUControl = 5'b01110;
                3'b011 : ALUControl = 5'b01111;
                3'b100 : ALUControl = 5'b10011;
                3'b101 : ALUControl = (funct7[5]) ? 5'b01010 : 5'b01011;
                3'b110 : ALUControl = 5'b10010;
                3'b111 : ALUControl = 5'b10001;
                default : ALUControl = 5'hx;
            endcase
        end
        else begin
            ALUControl = 5'hx;
        end
    end
endmodule
