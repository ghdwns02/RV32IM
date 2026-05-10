module alu(
    input         [31:0] a_in,
    input         [31:0] b_in,
    input         [4:0]  ALUControl,
    output reg    [31:0] result,
    output reg           aN, aZ, aC, aV
);

    wire [31:0] adder_result;
    wire        N, Z, C, V;
    wire sub_ctrl =
              (ALUControl == 5'b00001)
           || (ALUControl == 5'b00101)
           || (ALUControl == 5'b01110)
           || (ALUControl == 5'b10000)
           || (ALUControl == 5'b01111);

    adder u_adder (
        .a  (a_in),
        .b  (sub_ctrl ? ~b_in : b_in),
        .ci (sub_ctrl),
        .sum(adder_result),
        .N  (N),
        .Z  (Z),
        .C  (C),
        .V  (V)
    );

    always @(*) begin
        case (ALUControl)

            5'b00000: result = adder_result;
            5'b00001: result = adder_result;
            5'b00010: result = a_in & b_in;
            5'b00011: result = a_in | b_in;
            5'b00100: result = a_in ^ b_in;
            5'b00101: result = ($signed(a_in) < $signed(b_in)) ? 32'd1 : 32'd0;
            5'b00110: result = a_in << b_in[4:0];
            5'b00111: result = a_in >> b_in[4:0];
            5'b01000: result = $signed(a_in) >>> b_in[4:0];
            5'b01001: result = (a_in + b_in) & 32'hFFFF_FFFE;
            5'b01010: result = $signed(a_in) >>> b_in[4:0];
            5'b01011: result = a_in >> b_in[4:0];
            5'b01100: result = a_in << b_in[4:0];
            5'b01101: result = adder_result;
            5'b01110: result = ($signed(a_in) < $signed(b_in)) ? 32'd1 : 32'd0;
            5'b01111: result = ($unsigned(a_in) < $unsigned(b_in)) ? 32'd1 : 32'd0;
            5'b10000: result = ($unsigned(a_in) < $unsigned(b_in)) ? 32'd1 : 32'd0;
            5'b10001: result = a_in & b_in;
            5'b10010: result = a_in | b_in;
            5'b10011: result = a_in ^ b_in;

            default:  result = 32'h0;
        endcase
    end

    always @(*) begin
        case (ALUControl)

            5'b00000, 5'b00001, 5'b01101,
            5'b00101, 5'b01110, 5'b10000, 5'b01111:
                {aN, aZ, aC, aV} = {N, Z, C, V};

            5'b00110, 5'b00111, 5'b01000,
            5'b01010, 5'b01011, 5'b01100: begin
                aN = result[31];
                aZ = (result == 32'h0);
                aC = 1'b0;
                aV = 1'b0;
            end

            default: begin
                aN = result[31];
                aZ = (result == 32'h0);
                aC = 1'b0;
                aV = 1'b0;
            end
        endcase
    end

endmodule