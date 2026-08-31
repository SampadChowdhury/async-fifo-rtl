// Directed design demonstration: fill the FIFO to full, then drain to empty.
`timescale 1ns / 1ps

module tb_fifo_write_then_read;

  // Parameters
  parameter DATASIZE = 8;
  parameter ADDRSIZE = 4;
  localparam DEPTH = (1 << ADDRSIZE);

  // Clock and reset signals
  logic wclk, rclk;
  logic wrst_n, rrst_n;

  // FIFO interface signals
  // Write signals
  logic [DATASIZE-1:0] wdata;
  logic                winc;
  logic                wfull, walmost_full;

  // Read signals
  logic [DATASIZE-1:0] rdata;
  logic                rinc;
  logic                rempty, ralmost_empty;

  // FIFO instantiation
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
  
  
  // write data on rising edge of write clock
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

  // read clock generation (~66.7 MHz)
  initial begin
    rclk = 0;
    forever #7.5 rclk = ~rclk;
  end

  // assert resets at time 0ns, deassert at 20 ns
  initial begin
    wrst_n = 0;
    rrst_n = 0;
    winc   = 0;
    rinc   = 0;
    #20;
    wrst_n = 1;
    rrst_n = 1;
  end

  // write until full, then read until empty
  initial begin
    // Wait until FIFO is empty after reset
    wait (rempty == 1);
    $display("[%0t] FIFO is empty at start", $time);

    // 1: start writing
    winc = 1;
    rinc = 0;

    // writing till FIFO asserts full
    @(posedge wfull);
    $display("[%0t] FIFO became full", $time);

    // Stop writing and begin reading
    winc = 0;
    rinc = 1;

    // Keep reading till FIFO is empty again
    wait (rempty == 1);
    $display("[%0t] FIFO is empty again; test complete", $time);
    #10;
    $finish;
  end


  // Portable VCD waveform for GTKWave or another waveform viewer.
  initial begin
    $dumpfile("fifo_fill_drain.vcd");
    $dumpvars(0, tb_fifo_write_then_read);
  end

endmodule
