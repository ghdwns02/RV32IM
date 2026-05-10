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

    always @(*) begin
        if (jalE) begin
            PCSrc = 2'b01;
        end else if (jalrE) begin
            PCSrc = 2'b10;
        end else if (Branch) begin
            PCSrc = 2'b00;
            case (funct3)
                3'b000 : if (Z_flag) PCSrc = 2'b01;
                3'b001 : if (~Z_flag) PCSrc = 2'b01;
                3'b100 : if (N_flag ^ V_flag) PCSrc = 2'b01;
                3'b101 : if (~(N_flag ^ V_flag)) PCSrc = 2'b01;
                3'b110 : if (~C_flag) PCSrc = 2'b01;
                3'b111 : if (C_flag) PCSrc = 2'b01;
            endcase
        end else begin
            PCSrc = 2'b00;
        end
    end

endmodule