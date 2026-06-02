module adder(
    a,
    b,
    ci,
    sum,
    N,
    Z,
    C,
    V
);

    input [31:0] a, b;
    input ci;
    output [31:0] sum;
    output N, Z, C, V;

    wire c_msb;
    wire c_30;
    wire [2:0] w_carry;

    cla_8bit CLA_8bit_01 (.a(a[7:0]), .b(b[7:0]), .ci(ci), .s(sum[7:0]), .co(w_carry[0]), .c_30());
    cla_8bit CLA_8bit_02 (.a(a[15:8]),  .b(b[15:8]),  .ci(w_carry[0]), .s(sum[15:8]), .co(w_carry[1]), .c_30());
    cla_8bit CLA_8bit_03 (.a(a[23:16]), .b(b[23:16]), .ci(w_carry[1]), .s(sum[23:16]), .co(w_carry[2]), .c_30());
    cla_8bit CLA_8bit_04 (.a(a[31:24]), .b(b[31:24]), .ci(w_carry[2]), .s(sum[31:24]), .co(c_msb), .c_30(c_30));

    assign N = sum[31];
    assign Z = (sum == 32'h0) ? 1'b1 : 1'b0;
    assign C = c_msb;
    assign V = c_msb ^ c_30;

endmodule

module cla_8bit(
    a,
    b,
    ci,
    s,
    co,
    c_30
);
    input [7:0] a, b;
    input ci;
    output [7:0] s;
    output co, c_30;

    wire [7:0] g, p;
    wire [7:0] c;

    full_adder fa0(.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .g(g[0]), .p(p[0]));
    full_adder fa1(.a(a[1]), .b(b[1]), .ci(c[0]), .s(s[1]), .g(g[1]), .p(p[1]));
    full_adder fa2(.a(a[2]), .b(b[2]), .ci(c[1]), .s(s[2]), .g(g[2]), .p(p[2]));
    full_adder fa3(.a(a[3]), .b(b[3]), .ci(c[2]), .s(s[3]), .g(g[3]), .p(p[3]));
    full_adder fa4(.a(a[4]), .b(b[4]), .ci(c[3]), .s(s[4]), .g(g[4]), .p(p[4]));
    full_adder fa5(.a(a[5]), .b(b[5]), .ci(c[4]), .s(s[5]), .g(g[5]), .p(p[5]));
    full_adder fa6(.a(a[6]), .b(b[6]), .ci(c[5]), .s(s[6]), .g(g[6]), .p(p[6]));
    full_adder fa7(.a(a[7]), .b(b[7]), .ci(c[6]), .s(s[7]), .g(g[7]), .p(p[7]));

    cla_unit_8bit u_cla_unit(
        .g(g),
        .p(p),
        .ci(ci),
        .c(c)
    );

    assign co = c[7];
    assign c_30 = c[6];

endmodule

module cla_unit_8bit(
    g,
    p,
    ci,
    c
);
    input [7:0] g, p;
    input ci;
    output [7:0] c;

    assign c[0] = g[0] | (p[0]&ci);
    assign c[1] = g[1] | (p[1]&c[0]);
    assign c[2] = g[2] | (p[2]&c[1]);
    assign c[3] = g[3] | (p[3]&c[2]);
    assign c[4] = g[4] | (p[4]&c[3]);
    assign c[5] = g[5] | (p[5]&c[4]);
    assign c[6] = g[6] | (p[6]&c[5]);
    assign c[7] = g[7] | (p[7]&c[6]);

endmodule

module full_adder(
    a,
    b,
    ci,
    s,
    g,
    p
);
    input a, b, ci;
    output s, g, p;

    assign s = p^ci;
    assign g = a&b;
    assign p = a^b;

endmodule
