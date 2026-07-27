`timescale 1ns/1ps

module cpu_pipeline_v11_tb;

reg clk;
reg reset;

cpu_pipeline uut(.clk(clk), .reset(reset));

always #5 clk = ~clk;

initial begin
    uut.IM.memory[0]  = 32'h00500093; // addi x1,x0,5
    uut.IM.memory[1]  = 32'h00a00113; // addi x2,x0,10
    uut.IM.memory[2]  = 32'h00209463; // bne  x1,x2,+8
    uut.IM.memory[3]  = 32'h06f00193; // addi x3,x0,111 (SKIP)
    uut.IM.memory[4]  = 32'h00700193; // addi x3,x0,7
    uut.IM.memory[5]  = 32'h0020c463; // blt  x1,x2,+8
    uut.IM.memory[6]  = 32'h0de00213; // addi x4,x0,222 (SKIP)
    uut.IM.memory[7]  = 32'h00800213; // addi x4,x0,8
    uut.IM.memory[8]  = 32'h00115463; // bge  x2,x1,+8
    uut.IM.memory[9]  = 32'h0e900293; // addi x5,x0,233 (SKIP)
    uut.IM.memory[10] = 32'h00900293; // addi x5,x0,9
    uut.IM.memory[11] = 32'hfff00313; // addi x6,x0,-1
    uut.IM.memory[12] = 32'h0060e463; // bltu x1,x6,+8
    uut.IM.memory[13] = 32'h0f400393; // addi x7,x0,244 (SKIP)
    uut.IM.memory[14] = 32'h00b00393; // addi x7,x0,11
    uut.IM.memory[15] = 32'h00137463; // bgeu x6,x1,+8
    uut.IM.memory[16] = 32'h0ff00413; // addi x8,x0,255 (SKIP)
    uut.IM.memory[17] = 32'h00c00413; // addi x8,x0,12
    uut.IM.memory[18] = 32'hff000513; // addi x10,x0,-16
    uut.IM.memory[19] = 32'h40255593; // srai x11,x10,2
    uut.IM.memory[20] = 32'h00435613; // srli x12,x6,4
    uut.IM.memory[21] = 32'h401556b3; // sra  x13,x10,x1
    uut.IM.memory[22] = 32'h00001717; // auipc x14,0x1
    uut.IM.memory[23] = 32'h000087b7; // lui   x15,0x8
    uut.IM.memory[24] = 32'h0000000f; // fence
    uut.IM.memory[25] = 32'h00500493; // addi x9,x0,5  (sentinel: must execute normally right after fence)

    $dumpfile("pipeline_v11.vcd");
    $dumpvars(0, cpu_pipeline_v11_tb);

    clk = 0; reset = 1;
    #10; reset = 0;
    #400;

    $display("---------------------------------------------");
    $display("x1  = %0d (expect 5)",     uut.ID.rf.registers[1]);
    $display("x2  = %0d (expect 10)",    uut.ID.rf.registers[2]);
    $display("x3  = %0d (expect 7, must skip 111)",  uut.ID.rf.registers[3]);
    $display("x4  = %0d (expect 8, must skip 222)",  uut.ID.rf.registers[4]);
    $display("x5  = %0d (expect 9, must skip 233)",  uut.ID.rf.registers[5]);
    $display("x6  = %0d (expect -1 / 0xffffffff)",   $signed(uut.ID.rf.registers[6]));
    $display("x7  = %0d (expect 11, must skip 244)", uut.ID.rf.registers[7]);
    $display("x8  = %0d (expect 12, must skip 255)", uut.ID.rf.registers[8]);
    $display("x9  = %0d (expect 5, sentinel: executes normally right after fence)", uut.ID.rf.registers[9]);
    $display("x10 = %0d (expect -16)",   $signed(uut.ID.rf.registers[10]));
    $display("x11 = %0d (expect -4, SRAI)",  $signed(uut.ID.rf.registers[11]));
    $display("x12 = %0d (expect 268435455, SRLI)", uut.ID.rf.registers[12]);
    $display("x13 = %0d (expect -1, SRA)",   $signed(uut.ID.rf.registers[13]));
    $display("x14 = %0d (expect 4184, AUIPC)", uut.ID.rf.registers[14]);
    $display("x15 = %0d (expect 32768, LUI -- regression test for the old rs1-garbage bug)", uut.ID.rf.registers[15]);
    $display("---------------------------------------------");

    $finish;
end

endmodule