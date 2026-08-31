// Directed design demonstration: concurrent read/write traffic with unrelated clocks.
`timescale 1ns / 1ps

module tb_fifo_simult_read_write;

  // Parameters
  parameter DATASIZE = 8;
  parameter ADDRSIZE = 4;
  localparam DEPTH = (1 << ADDRSIZE);

  // Clock and reset signals
  logic wclk, rclk;
  logic wrst_n, rrst_n;

  // FIFO interface signals
  logic [DATASIZE-1:0] wdata;
  logic                winc;
  logic                wfull, walmost_full;

  logic [DATASIZE-1:0] rdata;
  logic                rinc;
  logic                rempty, ralmost_empty;

  // FIFO instantiations
  fifo_top #(
    .DATASIZE(DATASIZE),
    .ADDRSIZE(ADDRSIZE)
  ) uut (
    .rdata         (rdata),
    .wfull         (wfull),
    .rempty        (rempty),
    .walmost_full  (walmost_full),
    .ralmost_empty (ralmost_empty),
    .wdata         (wdata),
    .winc          (winc),
    .wclk          (wclk),
    .wrst_n        (wrst_n),
    .rinc          (rinc),
    .rclk          (rclk),
    .rrst_n        (rrst_n)
  );


  // Drive write data on each rising edge of wclk
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wdata <= 0;
    end else if (winc) begin
      wdata <= wdata + 1;
    end
  end


  // write clock generation (100 MHz)
  initial begin
    wclk = 0;
    forever #5 wclk = ~wclk;
  end

  // read clock generation(~66.7 MHz)
  initial begin
    rclk = 0;
    forever #7.5 rclk = ~rclk;
  end

  // Apply resets and clear enables
  initial begin
    wrst_n = 0;
    rrst_n = 0;
    winc   = 0;
    rinc   = 0;
    #20;
    wrst_n = 1;
    rrst_n = 1;
  end

  
  initial begin
    // Wait until the reset state is visible in the read domain.
    wait (ralmost_empty == 1);
    $display("[%0t] FIFO is almost empty at start.", $time);

    // Wait until the FIFO becomes fully empty
    wait (rempty == 1);
    $display("[%0t] FIFO is empty at start.", $time);

    // Enable both write and read simultaneously
    winc = 1;
    rinc = 1;

    // Wait for "almost full" to appear
    @(posedge walmost_full);
    $display("[%0t] FIFO became almost full.", $time);

    // Wait for full
    @(posedge wfull);
    $display("[%0t] FIFO became full.", $time);

    // Once full, stop writing but keep reading
    winc = 0;

    // Wait till FIFO empties again
    wait (rempty == 1);
    $display("[%0t] FIFO became empty again.", $time);

    // End test
    #10;
    $display("[%0t] Test complete (empty → almost_full → full → almost_empty → empty).", $time);
    $finish;
  end


  // Portable VCD waveform for GTKWave or another waveform viewer.
  initial begin
    $dumpfile("fifo_concurrent.vcd");
    $dumpvars(0, tb_fifo_simult_read_write);
  end


endmodule
