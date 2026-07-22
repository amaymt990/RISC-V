`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg reset;

cpu uut(
    .clk(clk),
    .reset(reset)
);

// Clock
// Clock
always #5 clk = ~clk;

initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, cpu_tb);

    clk = 0;
    reset = 1;

    #10;
    reset = 0;

    #100;

    $display("x1 = %d", uut.rf.registers[1]);
    $display("x2 = %d", uut.rf.registers[2]);
    $display("x3 = %d", uut.rf.registers[3]);

    $display("Memory[100] = %d", uut.dmem.memory[100]);

    $finish;
end

endmodule