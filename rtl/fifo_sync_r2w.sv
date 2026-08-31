// Read-to-write clock-domain crossing.
// Samples the Gray-coded read pointer through two write-clocked flip-flops so
// the write-side full and occupancy logic receives a synchronized value.
`timescale 1ns / 1ps
module fifo_sync_r2w #(
    parameter ADDRSIZE = 4
)(
    output logic [ADDRSIZE:0] wq2_rptr,
    input  logic [ADDRSIZE:0] rptr,
    input  logic wclk, wrst_n
);

    logic [ADDRSIZE:0] wq1_rptr;

    always_ff @(posedge wclk, negedge wrst_n) begin
        if (!wrst_n) begin
            {wq2_rptr, wq1_rptr} <= '0;  
        end
        else begin
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
        end
    end

endmodule
