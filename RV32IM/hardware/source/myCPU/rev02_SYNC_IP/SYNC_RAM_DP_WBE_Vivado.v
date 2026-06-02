module SYNC_RAM_DP_WBE_Vivado (q0, d0, addr0, wen0, wbe0, q1, d1, addr1, wen1, wbe1, clk);
  parameter DWIDTH  = 32;
  parameter AWIDTH  = 14;
  parameter DEPTH   = (1 << AWIDTH);
  parameter MIF_HEX = "";
  parameter MIF_BIN = "";

  localparam NUM_BYTES = DWIDTH / 8;

  input clk;
  input  [DWIDTH-1:0]    d0;
  input  [AWIDTH-1:0]    addr0;
  input  [NUM_BYTES-1:0] wbe0;
  input                  wen0;
  output [DWIDTH-1:0]    q0;

  input  [DWIDTH-1:0]    d1;
  input  [AWIDTH-1:0]    addr1;
  input  [NUM_BYTES-1:0] wbe1;
  input                  wen1;
  output [DWIDTH-1:0]    q1;

  genvar b;
  generate
    for (b = 0; b < NUM_BYTES; b = b + 1) begin : gen_byte_lane

      (* ram_style = "block" *) reg [7:0] mem [0:DEPTH-1];
      reg [7:0] rdata0, rdata1;

      integer idx;
      initial begin
        // 1) 0으로 초기화
        for (idx = 0; idx < DEPTH; idx = idx + 1)
          mem[idx] = 8'h00;

        // 2) HEX/BIN 파일 로드
        if (MIF_HEX != "") begin : load_hex
          reg [DWIDTH-1:0] tmp [0:DEPTH-1];
          $readmemh(MIF_HEX, tmp);
          for (idx = 0; idx < DEPTH; idx = idx + 1)
            mem[idx] = tmp[idx][b*8 +: 8];  // lane b의 byte만 추출
        end
        else if (MIF_BIN != "") begin : load_bin
          reg [DWIDTH-1:0] tmp [0:DEPTH-1];
          $readmemb(MIF_BIN, tmp);
          for (idx = 0; idx < DEPTH; idx = idx + 1)
            mem[idx] = tmp[idx][b*8 +: 8];
        end
      end

      always @(posedge clk) begin
        if (wen0 && wbe0[b])
          mem[addr0] <= d0[b*8 +: 8];
        rdata0 <= mem[addr0];
      end

      always @(posedge clk) begin
        if (wen1 && wbe1[b])
          mem[addr1] <= d1[b*8 +: 8];
        rdata1 <= mem[addr1];
      end

      assign q0[b*8 +: 8] = rdata0;
      assign q1[b*8 +: 8] = rdata1;
    end
  endgenerate

endmodule