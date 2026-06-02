//`timescale 1ns/1ps

`include "opcode.vh"
`include "mem_path.vh"

// =========================================================================
// RV32IM Pipeline Hazard Stress Testbench
// Assumes 2-cycle MUL and 2-cycle DIV units inside a pipelined CPU.
//
// Test structure (failure diagnosis guide):
//   Section 1 FAIL → fundamental operator correctness bug
//   Section 2 FAIL, Section 1 PASS → stall / forwarding bug (RAW)
//   Section 3 FAIL, Section 2 PASS → impossible (3 is strictly easier)
//   Section 4 FAIL → structural-hazard / scoreboard bug
//   Section 5 FAIL → WAW ordering / writeback arbitration bug
//   Section 6 FAIL → MULHSU sign-mixing bug
//   Section 7 FAIL → DIV/REM sign-truncation bug (spec §M)
//   Section 8 FAIL → deep forwarding chain / accumulator path bug
// =========================================================================

module cpu_tb();
  reg clk, rst;
  parameter CPU_CLOCK_PERIOD = 20;
  parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

  initial clk = 0;
  always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

  SMU_RV32I_System #(
      .RESET_PC(32'h1000_0000),
      .MIF_HEX("")
  ) CPU (
      .CLOCK_50  (clk),
      .BUTTON    ({2'b00, ~rst}),
      .SW        (10'b0),
      .HEX3      (),
      .HEX2      (),
      .HEX1      (),
      .HEX0      (),
      .LEDR      (),
      .UART_TXD  (),
      .UART_RXD  (1'b0)
  );

  // Generous timeout — each check_result_rf call gets this many cycles.
  wire [31:0] timeout_cycle = 100000;

  // M-extension encoding constants
  localparam FNC7_M      = 7'b0000001;
  localparam FNC_MUL     = 3'b000;
  localparam FNC_MULH    = 3'b001;
  localparam FNC_MULHSU  = 3'b010;
  localparam FNC_MULHU   = 3'b011;
  localparam FNC_DIV     = 3'b100;
  localparam FNC_DIVU    = 3'b101;
  localparam FNC_REM     = 3'b110;
  localparam FNC_REMU    = 3'b111;

  // NOP = addi x0, x0, 0 = 32'h0000_0013
  // Fill IMEM with NOPs (not 0) to avoid illegal-instruction traps.
  localparam NOP = 32'h0000_0013;

  reg [31:0]  cycle;
  reg         done;
  reg [31:0]  current_test_id   = 0;
  reg [255:0] current_test_type;
  reg [31:0]  current_output;
  reg [31:0]  current_result;
  reg         all_tests_passed  = 0;

  reg [14:0] INST_ADDR;
  integer i;

  // -----------------------------------------------------------------------
  // Tasks
  // -----------------------------------------------------------------------

  task reset;
    integer j;
    begin
      for (j = 0; j < `RF_PATH.DEPTH;   j = j + 1) `RF_PATH.mem[j]   = 0;
      for (j = 0; j < `DMEM_PATH.DEPTH; j = j + 1) `DMEM_PATH.mem[j] = 0;
      for (j = 0; j < `IMEM_PATH.DEPTH; j = j + 1) `IMEM_PATH.mem[j] = NOP;
    end
  endtask

  task reset_cpu;
    begin
      repeat (3) begin @(negedge clk); rst = 1; end
      @(negedge clk);
      rst = 0;
    end
  endtask

  task check_result_rf;
    input [31:0]  rf_wa;
    input [31:0]  result;
    input [255:0] test_type;
    begin
      done = 0;
      current_test_id   = current_test_id + 1;
      current_test_type = test_type;
      current_result    = result;
      while (`RF_PATH.mem[rf_wa] !== result) begin
        current_output = `RF_PATH.mem[rf_wa];
        @(posedge clk);
      end
      cycle = 0;
      done  = 1;
      $display("[%0d] PASS: %s", current_test_id, test_type);
    end
  endtask

  // Timeout watchdog
  initial begin
    while (all_tests_passed === 0) begin
      @(posedge clk);
      if (cycle === timeout_cycle) begin
        $display("[FAIL] Timeout at test [%0d] '%s'  expected=%h  got=%h",
                 current_test_id, current_test_type,
                 current_result,  current_output);
        $finish();
      end
    end
  end

  always @(posedge clk) begin
    if (done === 0) cycle <= cycle + 1;
    else            cycle <= 0;
  end

  // -----------------------------------------------------------------------
  // Main stimulus
  // -----------------------------------------------------------------------

  initial begin
    `ifndef IVERILOG
      $vcdpluson;
    `endif
    `ifdef IVERILOG
      $dumpfile("cpu_tb.fst");
      $dumpvars(0, cpu_tb);
    `endif
    `ifdef FSDB
      $fsdbDumpfile("wave.fsdb");
      $fsdbDumpvars(0);
    `endif

    #0;
    rst   = 0;
    cycle = 0;
    done  = 0;

    rst = 1;
    repeat (10) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // ===================================================================
    // SECTION 1: Baseline — each M op in isolation (NOP-padded)
    //
    // IMEM is filled with NOPs by reset(); we only write index 0.
    // With ≥3 NOPs after, even zero-forwarding pipelines should pass.
    // FAIL HERE → fundamental arithmetic bug in the operator itself.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 1: Baseline (NOP-padded) ---");

      // 1a  MUL   6 * 7 = 42 = 0x2A
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd6;
      `RF_PATH.mem[2] = 32'd7;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_002A, "Baseline MUL  6*7=42");

      // 1b  MULH  (2^30) * 4 = 2^32  → high word = 1
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h4000_0000;
      `RF_PATH.mem[2] = 32'h0000_0004;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_MULH, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0001, "Baseline MULH (2^30)*4 hi=1");

      // 1c  MULHSU  3(signed) * 0xFFFFFFFF(unsigned) = 12884901885 → high = 2
      //     Contrast: MULH of same operands = 3*(-1)=-3 → high=0xFFFFFFFF
      //     Result must be 0x0000_0002, NOT 0xFFFF_FFFF.
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h0000_0003;
      `RF_PATH.mem[2] = 32'hFFFF_FFFF;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_MULHSU, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0002, "Baseline MULHSU 3*0xFFFF_FFFF hi=2");

      // 1d  MULHU  65536 * 65536 = 2^32  → high word = 1
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h0001_0000;
      `RF_PATH.mem[2] = 32'h0001_0000;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_MULHU, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0001, "Baseline MULHU 65536^2 hi=1");

      // 1e  DIV   100 / 7 = 14
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100;
      `RF_PATH.mem[2] = 32'd7;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_000E, "Baseline DIV  100/7=14");

      // 1f  DIVU  0xFFFFFFFF / 3 = 0x5555_5555
      //     (3 divides 2^32-1 exactly, remainder = 0)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FFFF;
      `RF_PATH.mem[2] = 32'h0000_0003;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_DIVU, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h5555_5555, "Baseline DIVU 0xFFFFFFFF/3");

      // 1g  REM   100 % 7 = 2
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100;
      `RF_PATH.mem[2] = 32'd7;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0002, "Baseline REM  100%7=2");

      // 1h  REMU  0xFFFFFFFF % 3 = 0
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FFFF;
      `RF_PATH.mem[2] = 32'h0000_0003;
      `IMEM_PATH.mem[INST_ADDR] = {FNC7_M, 5'd2, 5'd1, FNC_REMU, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0000, "Baseline REMU 0xFFFFFFFF%3=0");
    end

    // ===================================================================
    // SECTION 2: RAW Hazards — 0 NOPs between producer and consumer
    //
    // Every test writes a register with an M op, then immediately reads
    // it in the next instruction.  The pipeline MUST stall or forward.
    // FAIL HERE (Section 1 passed) → stall / forwarding logic bug.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 2: RAW hazards (0 NOPs) ---");

      // 2a  MUL → ADD   x3=6*7=42, x4=42+8=50=0x32
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd6;  `RF_PATH.mem[2] = 32'd7;  `RF_PATH.mem[5] = 32'd8;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_MUL,      5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0032, "RAW(0NOP) MUL->ADD x4=50");

      // 2b  MUL → MUL   x3=3*4=12, x4=12*4=48=0x30
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd3;  `RF_PATH.mem[2] = 32'd4;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd3, FNC_MUL, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0030, "RAW(0NOP) MUL->MUL x4=48");

      // 2c  MUL → DIV   x3=12*5=60, x4=60/4=15
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd12; `RF_PATH.mem[2] = 32'd5;  `RF_PATH.mem[6] = 32'd4;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd6, 5'd3, FNC_DIV, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_000F, "RAW(0NOP) MUL->DIV x4=15");

      // 2d  DIV → ADD   x3=100/7=14, x4=14+1=15
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100; `RF_PATH.mem[2] = 32'd7; `RF_PATH.mem[5] = 32'd1;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_DIV,      5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_000F, "RAW(0NOP) DIV->ADD x4=15");

      // 2e  DIV → MUL   x3=100/7=14, x4=14*3=42
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100; `RF_PATH.mem[2] = 32'd7; `RF_PATH.mem[5] = 32'd3;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd5, 5'd3, FNC_MUL, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_002A, "RAW(0NOP) DIV->MUL x4=42");

      // 2f  ADD → MUL   (fast ALU result fed into slow unit)
      //     x3=6+7=13, x4=13*5=65=0x41
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd6;  `RF_PATH.mem[2] = 32'd7;  `RF_PATH.mem[5] = 32'd5;
      `IMEM_PATH.mem[INST_ADDR+0] = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M,  5'd5, 5'd3, FNC_MUL,      5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0041, "RAW(0NOP) ADD->MUL x4=65");

      // 2g  MUL → both rs1 AND rs2 simultaneously
      //     x3=4*5=20, x4=20*20=400=0x190
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd4;  `RF_PATH.mem[2] = 32'd5;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd3, 5'd3, FNC_MUL, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0190, "RAW(0NOP) MUL->MUL^2 x4=400");
    end

    // ===================================================================
    // SECTION 3: RAW with 1 and 2 NOPs — must give identical results
    //
    // If Section 2 fails but Section 3 passes → latency mismatch.
    // The exact NOP count that fixes it reveals the forwarding depth.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 3: RAW hazards (1 and 2 NOPs) ---");

      // 3a  MUL →(1NOP)→ ADD  =50
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd6;  `RF_PATH.mem[2] = 32'd7;  `RF_PATH.mem[5] = 32'd8;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_MUL,      5'd3, `OPC_ARI_RTYPE};
      // INST_ADDR+1 stays NOP
      `IMEM_PATH.mem[INST_ADDR+2] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0032, "RAW(1NOP) MUL->ADD x4=50");

      // 3b  MUL →(2NOP)→ ADD  =50  (fully safe for 2-cycle MUL+no fwd)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd6;  `RF_PATH.mem[2] = 32'd7;  `RF_PATH.mem[5] = 32'd8;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_MUL,      5'd3, `OPC_ARI_RTYPE};
      // INST_ADDR+1, +2 stay NOP
      `IMEM_PATH.mem[INST_ADDR+3] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_0032, "RAW(2NOP) MUL->ADD x4=50");

      // 3c  DIV →(1NOP)→ ADD  =15
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100; `RF_PATH.mem[2] = 32'd7; `RF_PATH.mem[5] = 32'd1;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_DIV,      5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_000F, "RAW(1NOP) DIV->ADD x4=15");

      // 3d  DIV →(2NOP)→ ADD  =15
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd100; `RF_PATH.mem[2] = 32'd7; `RF_PATH.mem[5] = 32'd1;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd2, 5'd1, FNC_DIV,      5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+3] = {`FNC7_0, 5'd5, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd4, 32'h0000_000F, "RAW(2NOP) DIV->ADD x4=15");
    end

    // ===================================================================
    // SECTION 4: Structural Hazards — independent ops on the same unit
    //
    // No RAW; both instructions use the same functional unit.
    // The pipeline must stall or pipeline the unit correctly.
    // FAIL HERE → resource-conflict / scoreboard bug.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 4: Structural hazards ---");

      // 4a  Two independent MUL back-to-back
      //     x3=5*7=35=0x23,  x5=3*4=12=0xC
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd5; `RF_PATH.mem[2]=32'd7;
      `RF_PATH.mem[4]=32'd3; `RF_PATH.mem[6]=32'd4;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd6, 5'd4, FNC_MUL, 5'd5, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0023, "Structural 2xMUL x3=5*7=35");
      check_result_rf(5'd5, 32'h0000_000C, "Structural 2xMUL x5=3*4=12");

      // 4b  Four independent MUL back-to-back (stress the scoreboard)
      //     x10=2*3=6, x11=4*5=20, x12=6*7=42, x13=8*9=72
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd2; `RF_PATH.mem[2]=32'd3;
      `RF_PATH.mem[3]=32'd4; `RF_PATH.mem[4]=32'd5;
      `RF_PATH.mem[5]=32'd6; `RF_PATH.mem[6]=32'd7;
      `RF_PATH.mem[7]=32'd8; `RF_PATH.mem[8]=32'd9;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd10, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd4, 5'd3, FNC_MUL, 5'd11, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd6, 5'd5, FNC_MUL, 5'd12, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+3] = {FNC7_M, 5'd8, 5'd7, FNC_MUL, 5'd13, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd10, 32'h0000_0006, "Structural 4xMUL x10=2*3=6");
      check_result_rf(5'd11, 32'h0000_0014, "Structural 4xMUL x11=4*5=20");
      check_result_rf(5'd12, 32'h0000_002A, "Structural 4xMUL x12=6*7=42");
      check_result_rf(5'd13, 32'h0000_0048, "Structural 4xMUL x13=8*9=72");

      // 4c  Two independent DIV back-to-back
      //     x3=100/7=14,  x5=50/6=8
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd100; `RF_PATH.mem[2]=32'd7;
      `RF_PATH.mem[4]=32'd50;  `RF_PATH.mem[6]=32'd6;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd6, 5'd4, FNC_DIV, 5'd5, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_000E, "Structural 2xDIV x3=100/7=14");
      check_result_rf(5'd5, 32'h0000_0008, "Structural 2xDIV x5=50/6=8");

      // 4d  MUL immediately followed by DIV (different units, independent)
      //     x3=6*7=42=0x2A,  x5=100/7=14=0xE
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd6;   `RF_PATH.mem[2]=32'd7;
      `RF_PATH.mem[4]=32'd100; `RF_PATH.mem[6]=32'd7;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd6, 5'd4, FNC_DIV, 5'd5, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_002A, "Structural MUL||DIV x3=6*7=42");
      check_result_rf(5'd5, 32'h0000_000E, "Structural MUL||DIV x5=100/7=14");
    end

    // ===================================================================
    // SECTION 5: WAW Hazards — two ops writing the same destination
    //
    // The LATER instruction must win.  An in-order pipeline with correct
    // writeback arbitration naturally handles this, but bugs in bypass
    // networks or scoreboard release ordering can cause the wrong value
    // to survive.
    // FAIL HERE → writeback arbitration / WAW ordering bug.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 5: WAW hazards ---");

      // 5a  MUL→MUL same dest: x3 final = 3*3=9 (NOT 7*8=56)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd7; `RF_PATH.mem[2]=32'd8;   // first MUL operands
      `RF_PATH.mem[4]=32'd3; `RF_PATH.mem[5]=32'd3;   // second MUL operands
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd5, 5'd4, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0009, "WAW MUL->MUL same dest x3=9");

      // 5b  MUL→DIV same dest: x3 final = 100/7=14 (NOT 5*6=30)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd5;   `RF_PATH.mem[2]=32'd6;  // MUL operands
      `RF_PATH.mem[4]=32'd100; `RF_PATH.mem[5]=32'd7;  // DIV operands
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd5, 5'd4, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_000E, "WAW MUL->DIV same dest x3=14");

      // 5c  DIV→MUL same dest: x3 final = 5*6=30 (NOT 100/7=14)
      //     (reversed order — the MUL issued second must win)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1]=32'd100; `RF_PATH.mem[2]=32'd7;  // DIV operands
      `RF_PATH.mem[4]=32'd5;   `RF_PATH.mem[5]=32'd6;  // MUL operands
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd5, 5'd4, FNC_MUL, 5'd3, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_001E, "WAW DIV->MUL same dest x3=30");
    end

    // ===================================================================
    // SECTION 6: MULHSU sign-isolation
    //
    // MULHSU treats rs1 as signed and rs2 as unsigned.
    // Both test cases below yield three distinct values for
    // MULH / MULHSU / MULHU — the clearest sign-mixing canary.
    // FAIL HERE → MULHSU using wrong sign convention for rs2.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 6: MULHSU sign isolation ---");

      // 6a  rs1=3(+), rs2=0xFFFFFFFF
      //   MULH  : 3*(-1)=-3              → hi = 0xFFFF_FFFF
      //   MULHSU: 3*(4294967295)=12884901885 → hi = 0x0000_0002  ← must differ
      //   MULHU : same as MULHSU          → hi = 0x0000_0002
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h0000_0003;
      `RF_PATH.mem[2] = 32'hFFFF_FFFF;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MULH,   5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_MULHSU, 5'd4, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd2, 5'd1, FNC_MULHU,  5'd5, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'hFFFF_FFFF, "MULHSU-dist(a) MULH  =0xFFFFFFFF");
      check_result_rf(5'd4, 32'h0000_0002, "MULHSU-dist(a) MULHSU=0x00000002");
      check_result_rf(5'd5, 32'h0000_0002, "MULHSU-dist(a) MULHU =0x00000002");

      // 6b  rs1=0xFFFFFFFF(-1), rs2=0x80000000
      //   MULH  : (-1)*(-2^31)=2^31      → hi = 0x0000_0000
      //   MULHSU: (-1)*(2^31)=-(2^31)    → hi = 0xFFFF_FFFF  ← must differ
      //   MULHU : (2^32-1)*(2^31)=2^63-2^31 → hi = 0x7FFF_FFFF  ← all three distinct
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FFFF;
      `RF_PATH.mem[2] = 32'h8000_0000;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MULH,   5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_MULHSU, 5'd4, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd2, 5'd1, FNC_MULHU,  5'd5, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0000, "MULHSU-dist(b) MULH  =0x00000000");
      check_result_rf(5'd4, 32'hFFFF_FFFF, "MULHSU-dist(b) MULHSU=0xFFFFFFFF");
      check_result_rf(5'd5, 32'h7FFF_FFFF, "MULHSU-dist(b) MULHU =0x7FFFFFFF");
    end

    // ===================================================================
    // SECTION 7: DIV/REM sign and rounding rules (spec §M §2)
    //
    // RISC-V mandates truncation toward zero.  Remainder sign follows
    // the dividend.  All four sign combinations are exercised.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 7: DIV/REM sign rules ---");

      // 7a  (-7) / 3 = -2  rem -1    (dividend<0, divisor>0)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FFF9; // -7
      `RF_PATH.mem[2] = 32'h0000_0003;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'hFFFF_FFFE, "DIV-sign (-7)/3 quot=-2");
      check_result_rf(5'd4, 32'hFFFF_FFFF, "DIV-sign (-7)/3 rem=-1");

      // 7b  7 / (-3) = -2  rem +1    (dividend>0, divisor<0)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h0000_0007;
      `RF_PATH.mem[2] = 32'hFFFF_FFFD; // -3
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'hFFFF_FFFE, "DIV-sign 7/(-3) quot=-2");
      check_result_rf(5'd4, 32'h0000_0001, "DIV-sign 7/(-3) rem=+1");

      // 7c  (-7) / (-3) = +2  rem -1   (both negative)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FFF9; // -7
      `RF_PATH.mem[2] = 32'hFFFF_FFFD; // -3
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0002, "DIV-sign (-7)/(-3) quot=+2");
      check_result_rf(5'd4, 32'hFFFF_FFFF, "DIV-sign (-7)/(-3) rem=-1");

      // 7d  3 / 7 = 0  rem 3   (divisor larger than dividend)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h0000_0003;
      `RF_PATH.mem[2] = 32'h0000_0007;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0000, "DIV-sign 3/7 quot=0");
      check_result_rf(5'd4, 32'h0000_0003, "DIV-sign 3/7 rem=3");

      // 7e  Signed vs unsigned interpretation: 0xFFFFFF9C / 9
      //     DIV  (signed -100) / 9 = -11  rem -1
      //     DIVU (unsigned 4294967196) / 9 = 0x1C71C711  rem 3
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'hFFFF_FF9C; // -100 signed / 4294967196 unsigned
      `RF_PATH.mem[2] = 32'h0000_0009;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV,  5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM,  5'd4, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd2, 5'd1, FNC_DIVU, 5'd5, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+3] = {FNC7_M, 5'd2, 5'd1, FNC_REMU, 5'd6, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'hFFFF_FFF5, "DIV-sign DIV  -100/9=-11");
      check_result_rf(5'd4, 32'hFFFF_FFFF, "DIV-sign REM  -100%9=-1");
      check_result_rf(5'd5, 32'h1C71_C711, "DIV-sign DIVU large/9");
      check_result_rf(5'd6, 32'h0000_0003, "DIV-sign REMU large%9=3");

      // 7f  Edge: divide by zero (signed and unsigned, spec §M §2)
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h8000_0000; // INT_MIN
      `RF_PATH.mem[2] = 32'h0000_0000;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV,  5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM,  5'd4, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd2, 5'd1, FNC_DIVU, 5'd5, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+3] = {FNC7_M, 5'd2, 5'd1, FNC_REMU, 5'd6, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'hFFFF_FFFF, "DIV-edge DIV/0 =-1");
      check_result_rf(5'd4, 32'h8000_0000, "DIV-edge REM/0 =dividend");
      check_result_rf(5'd5, 32'hFFFF_FFFF, "DIV-edge DIVU/0=-1");
      check_result_rf(5'd6, 32'h8000_0000, "DIV-edge REMU/0=dividend");

      // 7g  Edge: signed overflow  INT_MIN / -1
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'h8000_0000;
      `RF_PATH.mem[2] = 32'hFFFF_FFFF; // -1
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_DIV, 5'd3, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd2, 5'd1, FNC_REM, 5'd4, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd3, 32'h8000_0000, "DIV-edge INT_MIN/-1=INT_MIN");
      check_result_rf(5'd4, 32'h0000_0000, "DIV-edge INT_MIN%-1=0");
    end

    // ===================================================================
    // SECTION 8: Deep forwarding chains — all-dependent sequences
    //
    // Every instruction is data-dependent on the immediately preceding
    // one.  Exercises forwarding over the full pipeline depth.
    // FAIL HERE (Sections 2-3 passed) → multi-hop forwarding bug.
    // ===================================================================

    if (1) begin
      $display("\n--- Section 8: Deep forwarding chains ---");

      // 8a  9-instruction MUL/ADD chain (all RAW on x2)
      //     x2: 1→2→3→6→9→18→19→38→41→82=0x52
      reset(); reset_cpu(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd2;  // constant multiplier
      `RF_PATH.mem[2] = 32'd1;  // accumulator seed
      `RF_PATH.mem[3] = 32'd1;  // addend A
      `RF_PATH.mem[4] = 32'd3;  // addend B
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M,  5'd1, 5'd2, FNC_MUL,      5'd2, `OPC_ARI_RTYPE}; // *2→2
      `IMEM_PATH.mem[INST_ADDR+1] = {`FNC7_0, 5'd3, 5'd2, `FNC_ADD_SUB, 5'd2, `OPC_ARI_RTYPE}; // +1→3
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M,  5'd1, 5'd2, FNC_MUL,      5'd2, `OPC_ARI_RTYPE}; // *2→6
      `IMEM_PATH.mem[INST_ADDR+3] = {`FNC7_0, 5'd4, 5'd2, `FNC_ADD_SUB, 5'd2, `OPC_ARI_RTYPE}; // +3→9
      `IMEM_PATH.mem[INST_ADDR+4] = {FNC7_M,  5'd1, 5'd2, FNC_MUL,      5'd2, `OPC_ARI_RTYPE}; // *2→18
      `IMEM_PATH.mem[INST_ADDR+5] = {`FNC7_0, 5'd3, 5'd2, `FNC_ADD_SUB, 5'd2, `OPC_ARI_RTYPE}; // +1→19
      `IMEM_PATH.mem[INST_ADDR+6] = {FNC7_M,  5'd1, 5'd2, FNC_MUL,      5'd2, `OPC_ARI_RTYPE}; // *2→38
      `IMEM_PATH.mem[INST_ADDR+7] = {`FNC7_0, 5'd4, 5'd2, `FNC_ADD_SUB, 5'd2, `OPC_ARI_RTYPE}; // +3→41
      `IMEM_PATH.mem[INST_ADDR+8] = {FNC7_M,  5'd1, 5'd2, FNC_MUL,      5'd2, `OPC_ARI_RTYPE}; // *2→82
      reset_cpu();
      check_result_rf(5'd2, 32'h0000_0052, "Chain 9-deep MUL+ADD x2=82");

      // 8b  5-instruction DIV chain (all RAW on x2)
      //     1000000 →/10→ 100000 →/10→ 10000 →/10→ 1000 →/10→ 100 →/10→ 10
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd10;
      `RF_PATH.mem[2] = 32'd1000000;
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd1, 5'd2, FNC_DIV, 5'd2, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd1, 5'd2, FNC_DIV, 5'd2, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd1, 5'd2, FNC_DIV, 5'd2, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+3] = {FNC7_M, 5'd1, 5'd2, FNC_DIV, 5'd2, `OPC_ARI_RTYPE};
      `IMEM_PATH.mem[INST_ADDR+4] = {FNC7_M, 5'd1, 5'd2, FNC_DIV, 5'd2, `OPC_ARI_RTYPE};
      reset_cpu();
      check_result_rf(5'd2, 32'h0000_000A, "Chain 5-deep DIV /10 each =10");

      // 8c  Interleaved MUL/DIV chain (cross-unit RAW)
      //     x3=4*5=20, x3=20/4=5, x3=5*6=30, x3=30/5=6
      reset(); INST_ADDR = 0;
      `RF_PATH.mem[1] = 32'd4;  // MUL rs1
      `RF_PATH.mem[2] = 32'd5;  // MUL rs2 / DIV divisor #1
      `RF_PATH.mem[5] = 32'd4;  // DIV divisor #2
      `RF_PATH.mem[6] = 32'd6;  // MUL rs2 #2
      `RF_PATH.mem[7] = 32'd5;  // DIV divisor #3
      `IMEM_PATH.mem[INST_ADDR+0] = {FNC7_M, 5'd2, 5'd1, FNC_MUL, 5'd3, `OPC_ARI_RTYPE}; // 4*5=20
      `IMEM_PATH.mem[INST_ADDR+1] = {FNC7_M, 5'd5, 5'd3, FNC_DIV, 5'd3, `OPC_ARI_RTYPE}; // 20/4=5
      `IMEM_PATH.mem[INST_ADDR+2] = {FNC7_M, 5'd6, 5'd3, FNC_MUL, 5'd3, `OPC_ARI_RTYPE}; // 5*6=30
      `IMEM_PATH.mem[INST_ADDR+3] = {FNC7_M, 5'd7, 5'd3, FNC_DIV, 5'd3, `OPC_ARI_RTYPE}; // 30/5=6
      reset_cpu();
      check_result_rf(5'd3, 32'h0000_0006, "Chain MUL/DIV interleaved x3=6");
    end

    all_tests_passed = 1'b1;
    repeat (100) @(posedge clk);
    $display("\n=== All RV32IM pipeline hazard stress tests PASSED ===");
    $finish();
  end

endmodule