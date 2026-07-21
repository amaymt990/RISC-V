`timescale 1ns/1ps

module data_memory(

    input clk,
    input mem_write,
    input mem_read,
    input [31:0] address,
    input [31:0] write_data,

    output reg [31:0] read_data

);

reg [31:0] memory [0:255];

// Read (Combinational)
always @(*) begin
    if (mem_read)
        read_data = memory[address[31:2]];
    else
        read_data = 32'd0;
end

// Write (Synchronous)
always @(posedge clk) begin
    if (mem_write)
        memory[address[31:2]] <= write_data;
end

endmodule