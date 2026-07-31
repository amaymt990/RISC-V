`timescale 1ns/1ps

module cpu_pipeline_jalr_tb;

reg clk;
reg reset;

cpu_pipeline uut(.clk(clk), .reset(reset));

always #5 clk = ~clk;

initial begin
    uut.IM.memory[0]  = 32'h00300093; // addi x1,x0,3
    uut.IM.memory[1]  = 32'hfff00113; // addi x2,x0,-1
    uut.IM.memory[2]  = 32'h0020b1b3; // sltu  x3,x1,x2   -> 3 <u 0xFFFFFFFF = 1
    uut.IM.memory[3]  = 32'h0050b213; // sltiu x4,x1,5    -> 3 <u 5         = 1
    uut.IM.memory[4]  = 32'h00513293; // sltiu x5,x2,5    -> 0xFFFFFFFF <u 5 = 0
    uut.IM.memory[5]  = 32'h06400393; // addi  x7,x0,100
    uut.IM.memory[6]  = 32'h00838367; // jalr  x6,8(x7)   -> x6=pc+4=28, pc=(100+8)&~1=108
    uut.IM.memory[7]  = 32'h0de00413; // addi  x8,x0,222  (SKIPPED -- must not execute)
    uut.IM.memory[27] = 32'h03700493; // addi  x9,x0,55   (jump target, word 27 = byte 108)

    $dumpfile("pipeline_jalr.vcd");
    $dumpvars(0, cpu_pipeline_jalr_tb);

    clk = 0; reset = 1;
    #10; reset = 0;
    #200;

    $display("---------------------------------------------");
    $display("x1 = %0d (expect 3)",   uut.ID.rf.registers[1]);
    $display("x2 = %0d (expect -1 / 0xffffffff)", $signed(uut.ID.rf.registers[2]));
    $display("x3 = %0d (expect 1, SLTU 3 <u -1)",  uut.ID.rf.registers[3]);
    $display("x4 = %0d (expect 1, SLTIU 3 <u 5)",  uut.ID.rf.registers[4]);
    $display("x5 = %0d (expect 0, SLTIU -1 <u 5)", uut.ID.rf.registers[5]);
    $display("x6 = %0d (expect 28, JALR link = pc+4)", uut.ID.rf.registers[6]);
    $display("x7 = %0d (expect 100)", uut.ID.rf.registers[7]);
    $display("x8 = %0d (expect 0, must be skipped by JALR)", uut.ID.rf.registers[8]);
    $display("x9 = %0d (expect 55, confirms JALR landed at (x7+8)&~1=108)", uut.ID.rf.registers[9]);
    $display("---------------------------------------------");

    $finish;
end

endmodule
