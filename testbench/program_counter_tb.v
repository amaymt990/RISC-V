`timescale 1ns/1ps

module program_counter_tb;

reg clk;
reg reset;
reg [31:0] next_pc;

wire [31:0] pc;

program_counter uut(
    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .pc(pc)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    reset = 1;
    next_pc = 0;

    #10;

    reset = 0;

    next_pc = 4;
    #10;
    $display("PC = %d", pc);

    next_pc = 8;
    #10;
    $display("PC = %d", pc);

    next_pc = 12;
    #10;
    $display("PC = %d", pc);

    $finish;

end

endmodule