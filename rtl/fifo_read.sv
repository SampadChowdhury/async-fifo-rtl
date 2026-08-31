// Read-domain control for the asynchronous FIFO.
// Generates the binary memory address and Gray-coded CDC pointer, detects
// empty in Gray space, and estimates occupancy for the almost-empty flag.
`timescale 1ns / 1ps

module fifo_read #(
    parameter ADDRSIZE = 4,
    parameter ALMOST_EMPTY_THRESHOLD = 4  // Default: 1/4 full for ADDRSIZE=4 (depth=16)
)(
    output logic rempty,
    output logic ralmost_empty,  // New almost empty flag
    output logic [ADDRSIZE-1:0] raddr,
    output logic [ADDRSIZE:0] rptr,
    input logic [ADDRSIZE:0] rq2_wptr,  
    input logic rinc, rclk, rrst_n
);

    logic [ADDRSIZE:0] rbin;
    logic [ADDRSIZE:0] rgraynext, rbinnext;
    logic rempty_val;
    logic [ADDRSIZE:0] wbin_sync;  // Synced write pointer (binary)
    logic [ADDRSIZE:0] fill_level;
    logic ralmost_empty_val;

    // Gray-to-binary conversion for synced write pointer
    generate
        genvar i;
        assign wbin_sync[ADDRSIZE] = rq2_wptr[ADDRSIZE];
        for(i = ADDRSIZE-1; i >= 0; i--) begin : GRAY2BIN
            assign wbin_sync[i] = wbin_sync[i+1] ^ rq2_wptr[i];
        end
    endgenerate

    // Fill level calculation (handles wrap-around)
    assign fill_level = wbin_sync - rbin;

    // Almost empty condition
    assign ralmost_empty_val = (fill_level <= ALMOST_EMPTY_THRESHOLD);

    // Pointer update logic
    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin
            {rbin, rptr} <= '0;
        end
        else begin
            {rbin, rptr} <= {rbinnext, rgraynext};
        end
    end

    assign raddr = rbin[ADDRSIZE-1:0];
    assign rbinnext = rbin + (rinc & ~rempty);
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    // Empty detection
    assign rempty_val = (rgraynext == rq2_wptr);

    // Output registers
    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
            ralmost_empty <= 1'b1;  // FIFO starts empty
        end
        else begin
            rempty <= rempty_val;
            ralmost_empty <= ralmost_empty_val;
        end
    end

endmodule
