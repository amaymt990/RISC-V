`timescale 1ns/1ps

module instruction_memory(

    input  [31:0] pc,
    output [31:0] instruction

);

reg [31:0] memory [0:255];

// Small test program
initial begin
    memory[0] = 32'h06400093; // addi x1,x0,100
    memory[1] = 32'h03700113; // addi x2,x0,55
    memory[2] = 32'h0020A023; // sw x2,0(x1)
    memory[3] = 32'h0000A183; // lw x3,0(x1)
    memory[4] = 32'h00000013; // nop
end

assign instruction = memory[pc[31:2]];

endmodule