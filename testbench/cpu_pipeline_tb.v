`timescale 1ns/1ps

module cpu_pipeline_tb;

reg clk;
reg reset;

cpu_pipeline uut(
    .clk(clk),
    .reset(reset)
);

always #5 clk = ~clk;

// Load a small test program directly into instruction memory.
// This exercises: back-to-back RAW hazard (forwarding), a load-use
// hazard (stall), and a taken branch (flush).
initial begin
    // x1 = 5
    uut.IM.memory[0]  = 32'h00500093; // addi x1, x0, 5
    // x2 = x1 + x1        -> needs EX/MEM forward of x1 (back-to-back RAW)
    uut.IM.memory[1]  = 32'h00108133; // add  x2, x1, x1
    // x3 = x2 + x0         -> needs MEM/WB forward of x2 (distance-2 RAW)
    uut.IM.memory[2]  = 32'h00010193; // addi x3, x2, 0
    // sw x2, 0(x0)         -> store x2 to address 0
    uut.IM.memory[3]  = 32'h0020a023; // sw   x2, 0(x1)
    // lw x4, 0(x1)         -> load it back
    uut.IM.memory[4]  = 32'h0000a203; // lw   x4, 0(x1)
    // x5 = x4 + x0         -> load-use hazard, must stall 1 cycle
    uut.IM.memory[5]  = 32'h00020293; // addi x5, x4, 0
    // beq x1, x1, +8       -> always taken, should flush 2 bubbles
    uut.IM.memory[6]  = 32'h00108463; // beq  x1, x1, +8 (skips memory[7])
    uut.IM.memory[7]  = 32'h05500313; // addi x6, x0, 85  (should be SKIPPED)
    uut.IM.memory[8]  = 32'h06300393; // addi x7, x0, 99  (branch target)

    $dumpfile("pipeline.vcd");
    $dumpvars(0, cpu_pipeline_tb);

    clk = 0;
    reset = 1;
    #10;
    reset = 0;

    // Run long enough for the whole program to drain through WB.
    #200;

    $display("---------------------------------------------");
    $display("x1 = %0d (expect 5)",  uut.ID.rf.registers[1]);
    $display("x2 = %0d (expect 10)", uut.ID.rf.registers[2]);
    $display("x3 = %0d (expect 10)", uut.ID.rf.registers[3]);
    $display("x4 = %0d (expect 10)", uut.ID.rf.registers[4]);
    $display("x5 = %0d (expect 10)", uut.ID.rf.registers[5]);
    $display("x6 = %0d (expect 0, must be skipped by branch)", uut.ID.rf.registers[6]);
    $display("x7 = %0d (expect 99)", uut.ID.rf.registers[7]);
    $display("---------------------------------------------");

    $finish;
end

endmodule