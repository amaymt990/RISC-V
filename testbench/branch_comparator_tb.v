`timescale 1ns/1ps

module branch_comparator_tb;

reg [31:0] rs1_data;
reg [31:0] rs2_data;

wire branch_taken;

branch_comparator uut(

    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .branch_taken(branch_taken)

);

initial begin

    rs1_data = 10;
    rs2_data = 10;
    #10;

    $display("Equal   -> Branch = %b", branch_taken);

    rs1_data = 10;
    rs2_data = 20;
    #10;

    $display("Not Equal -> Branch = %b", branch_taken);

    $finish;

end

endmodule