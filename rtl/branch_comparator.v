`timescale 1ns/1ps

module branch_comparator(

    input [31:0] rs1_data,
    input [31:0] rs2_data,

    output branch_taken

);

assign branch_taken = (rs1_data == rs2_data);

endmodule