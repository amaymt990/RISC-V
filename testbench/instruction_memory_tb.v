`timescale 1ns/1ps

module instruction_memory_tb;

reg [31:0] pc;
wire [31:0] instruction;

instruction_memory uut(
    .pc(pc),
    .instruction(instruction)
);

initial begin

    pc = 0;
    #10;
    $display("PC = %d | Instruction = %h", pc, instruction);

    pc = 4;
    #10;
    $display("PC = %d | Instruction = %h", pc, instruction);

    pc = 8;
    #10;
    $display("PC = %d | Instruction = %h", pc, instruction);

    pc = 12;
    #10;
    $display("PC = %d | Instruction = %h", pc, instruction);

    $finish;

end

endmodule