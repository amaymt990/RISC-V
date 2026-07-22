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

always @(posedge clk) begin
    if (mem_write)
        memory[address] <= write_data;
end

always @(*) begin
    if (mem_read)
        read_data = memory[address];
    else
        read_data = 32'b0;
end

endmodule