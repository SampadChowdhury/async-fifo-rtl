
// Top-level asynchronous FIFO integration.
// Connects the storage array, domain-local pointer/flag logic, and the two
// Gray-pointer synchronizers used for clock-domain crossing.
`timescale 1ns / 1ps

module fifo_top #(
    parameter DATASIZE = 8,
    parameter ADDRSIZE = 4,
    parameter ALMOST_FULL_THRESHOLD = 12,
    parameter ALMOST_EMPTY_THRESHOLD = 4
)(
    output logic [DATASIZE-1:0] rdata,  
    output logic wfull,
    output logic rempty,
    output logic walmost_full,
    output logic ralmost_empty,
    input logic [DATASIZE-1:0] wdata,
    input logic winc, wclk, wrst_n,
    input logic rinc, rclk, rrst_n
);

    logic [ADDRSIZE-1:0] waddr, raddr;  
    logic [ADDRSIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

    // Return the Gray-coded read pointer to the write clock domain.
    fifo_sync_r2w #(.ADDRSIZE(ADDRSIZE)) sync_r2w (
        .wq2_rptr(wq2_rptr),
        .rptr(rptr),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

    // Forward the Gray-coded write pointer to the read clock domain.
    fifo_sync_w2r #(.ADDRSIZE(ADDRSIZE)) sync_w2r (
        .rq2_wptr(rq2_wptr),
        .wptr(wptr),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    fifo_memory #(
        .DATASIZE(DATASIZE),            // Memory data word width
        .ADDRSIZE(ADDRSIZE)             // Memory address width
    ) fifomem (
        .rdata(rdata),
        .wdata(wdata),
        .waddr(waddr),
        .raddr(raddr),
        .wclken(winc),
        .wfull(wfull),
        .wclk(wclk)
    );

    fifo_read #(
        .ADDRSIZE(ADDRSIZE),
        .ALMOST_EMPTY_THRESHOLD(ALMOST_EMPTY_THRESHOLD)
    ) rptr_empty (
        .rempty(rempty),
        .ralmost_empty(ralmost_empty),
        .raddr(raddr),
        .rptr(rptr),
        .rq2_wptr(rq2_wptr),
        .rinc(rinc),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    fifo_write #(
        .ADDRSIZE(ADDRSIZE),
        .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD)
    ) wptr_full (
        .wfull(wfull),
        .walmost_full(walmost_full),
        .waddr(waddr),
        .wptr(wptr),
        .wq2_rptr(wq2_rptr),
        .winc(winc),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

endmodule

