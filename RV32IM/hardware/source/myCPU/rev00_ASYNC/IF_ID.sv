module IF_ID (

    input               clk,
    input               n_rst,
    input               Stall,
    input               Flush_IF_ID,

    input       [31:0]  RD,
    input       [31:0]  PC,
    input       [31:0]  PCPlus4,

    output  reg [31:0]  InstrD,
    output  reg [31:0]  PCD,
    output  reg [31:0]  PCPlus4D
);

    parameter RESET_PC = 32'h1000_0000;

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            InstrD <= 32'h00000013;
            PCD <= RESET_PC;
            PCPlus4D <= 32'd0;
        end else begin
            if (Flush_IF_ID) begin
                InstrD <= 32'h00000013;
            end else begin
                if (Stall) begin
                    InstrD <= InstrD;
                    PCD <= PCD;
                    PCPlus4D <= PCPlus4D;
                end else begin
                    InstrD <= RD;
                    PCD <= PC;
                    PCPlus4D <= PCPlus4;
                end
            end
        end
    end

endmodule
