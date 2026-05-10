module be_logic (
    input       [1:0]   AddrLast2M,
    input       [2:0]   funct3M,
    input       [1:0]   AddrLast2W,
    input       [2:0]   funct3W,
    input       [31:0]  WD,
    input       [31:0]  RD,
    output reg  [31:0]  BE_WD,
    output reg  [31:0]  BE_RD,
    output reg  [3:0]   ByteEnable
);

    always @(*) begin
        ByteEnable = 4'b0000;

        case (funct3M)
            3'b000 : begin
                case (AddrLast2M)
                    2'b00 : ByteEnable = 4'b0001;
                    2'b01 : ByteEnable = 4'b0010;
                    2'b10 : ByteEnable = 4'b0100;
                    2'b11 : ByteEnable = 4'b1000;
                endcase
            end
            3'b001 : begin
                case (AddrLast2M[1])
                    1'b0 : ByteEnable = 4'b0011;
                    1'b1 : ByteEnable = 4'b1100;
                endcase
            end
            3'b010 : begin
                ByteEnable = 4'b1111;
            end
            default: ByteEnable = 4'b0000;
        endcase
    end

    always @(*) begin
        BE_WD = 32'b0;

        case (funct3M)
            3'b000 : begin
                case (AddrLast2M)
                    2'b00 : BE_WD = {24'b0, WD[7:0]};
                    2'b01 : BE_WD = {16'b0, WD[7:0], 8'b0};
                    2'b10 : BE_WD = {8'b0, WD[7:0], 16'b0};
                    2'b11 : BE_WD = {WD[7:0], 24'b0};
                endcase
            end
            3'b001 : begin
                case (AddrLast2M[1])
                    1'b0 : BE_WD = {16'b0, WD[15:0]};
                    1'b1 : BE_WD = {WD[15:0], 16'b0};
                endcase
            end
            3'b010 : begin
                BE_WD = WD;
            end
        endcase
    end

    always @(*) begin
        BE_RD = 32'b0;

        case (funct3W)
            3'b000 : begin
                case (AddrLast2W)
                    2'b00 : BE_RD = {{24{RD[7]}}, RD[7:0]};
                    2'b01 : BE_RD = {{24{RD[15]}}, RD[15:8]};
                    2'b10 : BE_RD = {{24{RD[23]}}, RD[23:16]};
                    2'b11 : BE_RD = {{24{RD[31]}}, RD[31:24]};
                endcase
            end
            3'b100 : begin
                case (AddrLast2W)
                    2'b00 : BE_RD = {24'b0, RD[7:0]};
                    2'b01 : BE_RD = {24'b0, RD[15:8]};
                    2'b10 : BE_RD = {24'b0, RD[23:16]};
                    2'b11 : BE_RD = {24'b0, RD[31:24]};
                endcase
            end
            3'b001 : begin
                case (AddrLast2W[1])
                    1'b0 : BE_RD = {{16{RD[15]}}, RD[15:0]};
                    1'b1 : BE_RD = {{16{RD[31]}}, RD[31:16]};
                endcase
            end
            3'b101 : begin
                case (AddrLast2W[1])
                    1'b0 : BE_RD = {16'b0, RD[15:0]};
                    1'b1 : BE_RD = {16'b0, RD[31:16]};
                endcase
            end
            3'b010 : begin
                BE_RD = RD;
            end
        endcase
    end

endmodule
