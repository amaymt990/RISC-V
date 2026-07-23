`timescale 1ns/1ps

module cpu_pipeline_tb;

reg clk;
reg reset;

cpu_pipeline uut(
    .clk(clk),
    .reset(reset)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("pipeline.vcd");
    $dumpvars(0, cpu_pipeline_tb);

    clk = 0;
    reset = 1;

    #10;
    reset = 0;

    #50;

    $display("PC = %d", uut.pc);
    $display("Fetched Instruction = %h", uut.instruction);
    $display("IF/ID PC = %d", uut.if_id_pc);
    $display("IF/ID Instruction = %h", uut.if_id_instruction);

    $finish;
end

endmodule