`timescale 1ns/1ps

module instruction_memory(

    input  [31:0] pc,
    output [31:0] instruction

);

reg [31:0] memory [0:255];

// Small test program
initial begin
    memory[0] = 32'h00A00093; // addi x1, x0, 10
    memory[1] = 32'h00A00113; // addi x2, x0, 10
    memory[2] = 32'h00208463; // beq  x1, x2, +8
    memory[3] = 32'h00100193; // addi x3, x0, 1   (should be skipped)
    memory[4] = 32'h06300213; // addi x4, x0, 99
end

assign instruction = memory[pc[31:2]];

endmodule