// FIFO storage array.
// Writes are synchronous to wclk and blocked when the FIFO is full. The read
// port is asynchronous so rdata reflects the word selected by raddr.
`timescale 1ns / 1ps

module fifo_memory #(
    parameter DATASIZE = 8,  // Memory data word width
    parameter ADDRSIZE = 4   // Number of mem address bits
)(
    output logic [DATASIZE-1:0] rdata,
    input  logic [DATASIZE-1:0] wdata,
    input  logic [ADDRSIZE-1:0] waddr, raddr,
    input  logic wclken, wfull, wclk
);

    localparam DEPTH = 1 << ADDRSIZE;
    logic [DATASIZE-1:0] mem [0:DEPTH-1];

    always_ff @(posedge wclk) begin
        if (wclken && !wfull) begin
            mem[waddr] <= wdata;
        end
    end
    assign rdata = mem[raddr];

endmodule
