`timescale 1ns/1ps

module mem_stage(

    input clk,

    input MemRead,
    input MemWrite,

    input [31:0] address,
    input [31:0] write_data,

    output [31:0] read_data

);

data_memory dm(

    .clk(clk),

    .mem_write(MemWrite),
    .mem_read(MemRead),

    .address(address),
    .write_data(write_data),

    .read_data(read_data)

);

endmodule