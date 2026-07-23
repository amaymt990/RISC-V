`timescale 1ns/1ps

module wb_stage(

    input [31:0] read_data,
    input [31:0] alu_result,
    input [31:0] pc_plus4,

    input MemtoReg,
    input Jump,

    output [31:0] write_back_data

);

assign write_back_data =
        Jump     ? pc_plus4 :
        MemtoReg ? read_data :
                   alu_result;

endmodule