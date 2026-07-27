`timescale 1ns/1ps

module branch_comparator_tb;

reg [31:0] rs1_data;
reg [31:0] rs2_data;
reg [2:0]  funct3;

wire branch_taken;

branch_comparator uut(

    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .funct3(funct3),
    .branch_taken(branch_taken)

);

initial begin

    // BEQ
    funct3 = 3'b000; rs1_data = 10; rs2_data = 10;
    #10; $display("BEQ  equal      -> %b (expect 1)", branch_taken);
    rs2_data = 20;
    #10; $display("BEQ  not equal  -> %b (expect 0)", branch_taken);

    // BNE
    funct3 = 3'b001; rs1_data = 10; rs2_data = 20;
    #10; $display("BNE  not equal  -> %b (expect 1)", branch_taken);
    rs2_data = 10;
    #10; $display("BNE  equal      -> %b (expect 0)", branch_taken);

    // BLT (signed)
    funct3 = 3'b100; rs1_data = -5; rs2_data = 3;
    #10; $display("BLT  -5 <  3    -> %b (expect 1)", branch_taken);
    rs1_data = 3; rs2_data = -5;
    #10; $display("BLT   3 < -5    -> %b (expect 0)", branch_taken);

    // BGE (signed)
    funct3 = 3'b101; rs1_data = 3; rs2_data = -5;
    #10; $display("BGE   3 >= -5   -> %b (expect 1)", branch_taken);
    rs1_data = -5; rs2_data = 3;
    #10; $display("BGE  -5 >=  3   -> %b (expect 0)", branch_taken);

    // BLTU (unsigned) -- -5 as unsigned is a huge number
    funct3 = 3'b110; rs1_data = 3; rs2_data = -5;
    #10; $display("BLTU  3 < (u)-5 -> %b (expect 1)", branch_taken);
    rs1_data = -5; rs2_data = 3;
    #10; $display("BLTU (u)-5 < 3  -> %b (expect 0)", branch_taken);

    // BGEU (unsigned)
    funct3 = 3'b111; rs1_data = -5; rs2_data = 3;
    #10; $display("BGEU (u)-5 >= 3 -> %b (expect 1)", branch_taken);
    rs1_data = 3; rs2_data = -5;
    #10; $display("BGEU 3 >= (u)-5 -> %b (expect 0)", branch_taken);

    $finish;

end

endmodule