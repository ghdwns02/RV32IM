module div_unit (
    input               clk,
    input               n_rst,
    input      [31:0]   a_in,
    input      [31:0]   b_in,
    input      [4:0]    ALUControl,
    input               start,
    output     [31:0]   result,
    output              done
);

    wire is_signed_op = (ALUControl == 5'b11000) | (ALUControl == 5'b11010);
    wire div_by_zero  = (b_in == 32'd0);
    wire signed_ovfl  = (a_in == 32'h8000_0000) & (b_in == 32'hFFFF_FFFF) & is_signed_op;

    wire [31:0] a_abs = (a_in[31] & is_signed_op) ? (~a_in + 32'd1) : a_in;
    wire [31:0] b_abs = (b_in[31] & is_signed_op) ? (~b_in + 32'd1) : b_in;
    wire        a_neg = a_in[31] & is_signed_op;
    wire        b_neg = b_in[31] & is_signed_op;

    wire [34:0] b1 = {3'b000, b_abs};
    wire [34:0] b2 = {2'b00,  b_abs, 1'b0};
    wire [34:0] b3 = b2 + b1;
    wire [34:0] b4 = {1'b0,   b_abs, 2'b00};
    wire [34:0] b5 = b4 + b1;
    wire [34:0] b6 = b4 + b2;
    wire [34:0] b7 = b4 + b3;

    wire [32:0] a_pad = {1'b0, a_abs};

    wire [35:0] rem_s  [0:11];
    wire [32:0] quot_s [0:11];

    assign rem_s[0]  = 36'd0;
    assign quot_s[0] = 33'd0;

    genvar gi;
    generate
        for (gi = 0; gi < 11; gi = gi + 1) begin : STAGE

            localparam integer BIT = 10 - gi;

            wire [35:0] rem_sh = {rem_s[gi][32:0], a_pad[3*BIT+2], a_pad[3*BIT+1], a_pad[3*BIT]};

            wire [35:0] d7 = rem_sh - {1'b0, b7};
            wire [35:0] d6 = rem_sh - {1'b0, b6};
            wire [35:0] d5 = rem_sh - {1'b0, b5};
            wire [35:0] d4 = rem_sh - {1'b0, b4};
            wire [35:0] d3 = rem_sh - {1'b0, b3};
            wire [35:0] d2 = rem_sh - {1'b0, b2};
            wire [35:0] d1 = rem_sh - {1'b0, b1};

            wire ge7 = ~d7[35];
            wire ge6 = ~d6[35];
            wire ge5 = ~d5[35];
            wire ge4 = ~d4[35];
            wire ge3 = ~d3[35];
            wire ge2 = ~d2[35];
            wire ge1 = ~d1[35];

            wire [2:0]  qd;
            wire [35:0] rem_next;

            assign {qd, rem_next} =
                ge7 ? {3'd7, d7} :
                ge6 ? {3'd6, d6} :
                ge5 ? {3'd5, d5} :
                ge4 ? {3'd4, d4} :
                ge3 ? {3'd3, d3} :
                ge2 ? {3'd2, d2} :
                ge1 ? {3'd1, d1} :
                      {3'd0, rem_sh};

            assign rem_s[gi+1]  = rem_next;
            assign quot_s[gi+1] = quot_s[gi] | ({{30{1'b0}}, qd} << (3 * BIT));
        end
    endgenerate

    wire [31:0] quot_raw = quot_s[11][31:0];
    wire [31:0] rem_raw  = rem_s[11][31:0];

    wire [31:0] quot_corr = (a_neg ^ b_neg) ? (~quot_raw + 32'd1) : quot_raw;
    wire [31:0] rem_corr  =  a_neg          ? (~rem_raw  + 32'd1) : rem_raw;

    reg [31:0] comb_result;
    always @(*) begin
        if (div_by_zero)
            comb_result = ALUControl[1] ? a_in : 32'hFFFF_FFFF;
        else if (signed_ovfl)
            comb_result = ALUControl[1] ? 32'h0 : 32'h8000_0000;
        else
            case (ALUControl)
                5'b11000: comb_result = quot_corr;
                5'b11001: comb_result = quot_raw;
                5'b11010: comb_result = rem_corr;
                5'b11011: comb_result = rem_raw;
                default:  comb_result = 32'h0;
            endcase
    end

    reg [31:0] s1_result;
    reg        s1_valid;

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst)     begin s1_result <= 32'h0; s1_valid <= 1'b0; end
        else if (start) begin s1_result <= comb_result; s1_valid <= 1'b1; end
        else            begin s1_result <= 32'h0;        s1_valid <= 1'b0; end
    end

    assign result = s1_result;
    assign done   = s1_valid;

endmodule