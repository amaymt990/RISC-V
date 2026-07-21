`timescale 1ns/1ps

module immediate_generator_tb;

reg [31:0] instruction;
wire [31:0] immediate;

immediate_generator uut(
    .instruction(instruction),
    .immediate(immediate)
);

initial begin

    // addi x1,x0,5
    instruction = 32'h00500093;
    #10;
    $display("Immediate = %d", immediate);

    // sw x1,8(x0)
    instruction = 32'h00102423;
    #10;
    $display("Immediate = %d", immediate);

    $finish;

end

endmodule