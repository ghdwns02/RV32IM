module reg_file_async (
    input clk,
    input clkb,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    parameter DEPTH = 32;
    reg [31:0] mem [0:31];
    assign rd1 = (ra1 != 5'd0) ? mem[ra1] : 32'd0;
    assign rd2 = (ra2 != 5'd0) ? mem[ra2] : 32'd0;

`ifdef SIM
    initial
    begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end
`endif

    genvar i;
    generate
        for(i = 1; i < 32 ; i = i+1) begin : REG_FILE
            always @(posedge clkb) begin
                if(i == wa && we) begin
                    mem[i] <= wd;                    
                end
            end
        end
    endgenerate

`ifdef SIM
    wire [31:0]  x1  = mem[1 ];
    wire [31:0]  x2  = mem[2 ];
    wire [31:0]  x3  = mem[3 ];
    wire [31:0]  x4  = mem[4 ];
    wire [31:0]  x5  = mem[5 ];
    wire [31:0]  x6  = mem[6 ];
    wire [31:0]  x7  = mem[7 ];
    wire [31:0]  x8  = mem[8 ];
    wire [31:0]  x9  = mem[9 ];
    wire [31:0]  x10 = mem[10];
    wire [31:0]  x11 = mem[11];
    wire [31:0]  x12 = mem[12];
    wire [31:0]  x13 = mem[13];
    wire [31:0]  x14 = mem[14];
    wire [31:0]  x15 = mem[15];
    wire [31:0]  x16 = mem[16];
    wire [31:0]  x17 = mem[17];
    wire [31:0]  x18 = mem[18];
    wire [31:0]  x19 = mem[19];
    wire [31:0]  x20 = mem[20];
    wire [31:0]  x21 = mem[21];
    wire [31:0]  x22 = mem[22];
    wire [31:0]  x23 = mem[23];
    wire [31:0]  x24 = mem[24];
    wire [31:0]  x25 = mem[25];
    wire [31:0]  x26 = mem[26];
    wire [31:0]  x27 = mem[27];
    wire [31:0]  x28 = mem[28];
    wire [31:0]  x29 = mem[29];
    wire [31:0]  x30 = mem[30];
    wire [31:0]  x31 = mem[31];

`endif

endmodule
