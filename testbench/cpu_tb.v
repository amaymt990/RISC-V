`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg reset;

cpu uut(
    .clk(clk),
    .reset(reset)
);

// Clock
always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;

    #10;
    reset = 0;

    // Run for a few clock cycles
    #100;

    $display("----------------------------");
    $display("x1 = %0d", uut.rf.registers[1]);
    $display("x2 = %0d", uut.rf.registers[2]);
    $display("x3 = %0d", uut.rf.registers[3]);
    $display("----------------------------");

    $finish;
end

endmodule