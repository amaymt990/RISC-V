`timescale 1ns/1ps

module wb_stage(

    input [31:0] read_data,
    input [31:0] alu_result,

    input MemtoReg,

    output [31:0] write_back_data

);

assign write_back_data =
        MemtoReg ? read_data : alu_result;

endmodule