module extend(
    input       [2:0]   ImmSrc,
    input       [31:0]  in,
    output  reg [31:0]  out

);

    wire [2:0] funct3;
    wire [6:0] opcode;

    assign opcode = in[6:0];
    assign funct3 = in[14:12];

    always@(*) begin
        if (ImmSrc == 3'b000)
            if ((opcode == 7'b0010011) & (funct3 == 3'b001 | funct3 == 3'b101))
                out = {{27{1'b0}},in[24:20]};
            else
                out = {{20{in[31]}}, in[31:20]};
        else if (ImmSrc == 3'b001)
            out = {{20{in[31]}}, in[31:25], in[11:7]};
        else if (ImmSrc == 3'b010)
            out = {{20{in[31]}}, in[7], in[30:25], in[11:8], 1'b0};
        else if (ImmSrc == 3'b011)
            out = {{12{in[31]}}, in[19:12], in[20], in[30:21], 1'b0};
        else if (ImmSrc == 3'b100)
            out = in[31:12] << 12;
        else if (ImmSrc == 3'b101)
            out = {{20{1'b0}}, in[19:15]};
        else
            out = 32'h0;
    end

endmodule