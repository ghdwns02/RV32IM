module tbman_wrap (
    input wire clk,
    input wire rst_n,

    input wire tbman_sel,
    input wire tbman_write,
    input wire [15:0] tbman_addr,
    input wire [31:0] tbman_wdata,
    output wire [31:0] tbman_rdata
);

    tbman_apbs u_tbman_apbs (
        .clk          (clk),
        .rst_n        (rst_n),

        .apbs_psel    (tbman_sel),
        .apbs_penable (tbman_sel),
        .apbs_pwrite  (tbman_write),
        .apbs_paddr   (tbman_addr),
        .apbs_pwdata  (tbman_wdata),
        .apbs_prdata  (tbman_rdata),
        .apbs_pready  (),
        .apbs_pslverr (),

        .irq_force ()
    );

endmodule
