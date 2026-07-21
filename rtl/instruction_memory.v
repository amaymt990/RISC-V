`timescale 1ns/1ps

module instruction_memory(

    input  [31:0] pc,
    output [31:0] instruction

);

reg [31:0] memory [0:255];

// Small test program
initial begin
    memory[0] = 32'h00500093; // addi x1, x0, 5
    memory[1] = 32'h00A00113; // addi x2, x0, 10
    memory[2] = 32'h002081B3; // add x3, x1, x2
    memory[3] = 32'h00000013; // nop
end

assign instruction = memory[pc[31:2]];

endmodule