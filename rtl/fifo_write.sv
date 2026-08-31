// Write-domain control for the asynchronous FIFO.
// Generates the binary memory address and Gray-coded CDC pointer, detects
// full in Gray space, and estimates occupancy for the almost-full flag.
`timescale 1ns / 1ps

module fifo_write #(
    parameter ADDRSIZE = 4,
    parameter ALMOST_FULL_THRESHOLD = 12 // Default: 3/4 full for ADDRSIZE=4 (depth=16)
)(
    output logic wfull,
    output logic walmost_full,
    output logic [ADDRSIZE-1:0] waddr,
    output logic [ADDRSIZE:0] wptr,
    input logic [ADDRSIZE:0] wq2_rptr, // Synced read pointer (Gray code)
    input logic winc, wclk, wrst_n
);

    logic [ADDRSIZE:0] wbin;
    logic [ADDRSIZE:0] wgraynext, wbinnext;
    logic wfull_val, walmost_full_val;
    logic [ADDRSIZE:0] rbin_sync; // Synced read pointer (binary)
    logic [ADDRSIZE:0] fill_level;

    // Gray-to-binary conversion using generate blocks
    generate
        genvar i;
        assign rbin_sync[ADDRSIZE] = wq2_rptr[ADDRSIZE];
        for(i = ADDRSIZE-1; i >= 0; i--) begin : GRAY2BIN
            assign rbin_sync[i] = rbin_sync[i+1] ^ wq2_rptr[i];
        end
    endgenerate

    // Fill level calculation (handles wrap-around)
    assign fill_level = wbin - rbin_sync;

    // Pointer update logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wbin, wptr} <= '0;
        end
        else begin
            {wbin, wptr} <= {wbinnext, wgraynext};
        end
    end

    assign waddr = wbin[ADDRSIZE-1:0];
    assign wbinnext = wbin + (winc & ~wfull);
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    // Full detection logic
    assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});
    assign walmost_full_val = (fill_level >= ALMOST_FULL_THRESHOLD);

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
            walmost_full <= 1'b0;
        end
        else begin
            wfull <= wfull_val;
            walmost_full <= walmost_full_val;
        end
    end

endmodule
