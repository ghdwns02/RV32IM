// Testbench Manager
//
// Lets you:
// - print out to the simulation console
// - halt simulation, with an exit code
//
// Via an APB interface.
//
// It also has a read-only register with the values of some Verilog defines,
// e.g. FPGA, SIM, which allows software to ascertain which platform it is
// running on and act accordingly.
// (e.g. print to sim console in sim, print to UART on FPGA)

module tbman_wrap (
    input wire clk,
    input wire rst_n,

    // Native Port
    input wire tbman_sel,  // High Active
    input wire tbman_write, // Write : 1, Read : 0
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
