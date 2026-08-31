// Write-to-read clock-domain crossing.
// Samples the Gray-coded write pointer through two read-clocked flip-flops so
// the read-side empty and occupancy logic receives a synchronized value.
`timescale 1ns / 1ps

module fifo_sync_w2r #(
    parameter ADDRSIZE = 4
)(
    output logic [ADDRSIZE:0] rq2_wptr,
    input  logic [ADDRSIZE:0] wptr,
    input  logic rclk,
    input  logic rrst_n
);

    logic [ADDRSIZE:0] rq1_wptr;

    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin
            {rq2_wptr, rq1_wptr} <= '0;  
        end
        else begin
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
        end
    end

endmodule
