`timescale 1ns/1ps

module alu_control_tb;

reg [1:0] ALUOp;
reg [2:0] funct3;
reg [6:0] funct7;
reg is_itype;

wire [3:0] ALUCtrl;

alu_control uut(

    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .is_itype(is_itype),
    .ALUCtrl(ALUCtrl)

);

initial begin

    // ---- R-type (is_itype = 0) ----
    is_itype = 0;

    // ADD
    ALUOp = 2'b10; funct3 = 3'b000; funct7 = 7'b0000000;
    #10; $display("ADD  -> %b", ALUCtrl);

    // SUB
    funct7 = 7'b0100000;
    #10; $display("SUB  -> %b", ALUCtrl);

    // AND
    funct3 = 3'b111; funct7 = 7'b0000000;
    #10; $display("AND  -> %b", ALUCtrl);

    // OR
    funct3 = 3'b110;
    #10; $display("OR   -> %b", ALUCtrl);

    // XOR
    funct3 = 3'b100;
    #10; $display("XOR  -> %b", ALUCtrl);

    // SLL
    funct3 = 3'b001;
    #10; $display("SLL  -> %b", ALUCtrl);

    // SRL
    funct3 = 3'b101; funct7 = 7'b0000000;
    #10; $display("SRL  -> %b", ALUCtrl);

    // SRA
    funct7 = 7'b0100000;
    #10; $display("SRA  -> %b", ALUCtrl);

    // SLT
    funct3 = 3'b010; funct7 = 7'b0000000;
    #10; $display("SLT  -> %b", ALUCtrl);

    // ---- I-type (is_itype = 1) ----
    // Regression check: a negative-looking immediate's upper bits must
    // NOT be misread as funct7==0100000 and trigger a false SUB for ADDI.
    is_itype = 1;
    funct3 = 3'b000; funct7 = 7'b1111111; // looks like it could be "SUB", but this is ADDI
    #10; $display("ADDI (funct7 all-1s, must stay ADD) -> %b", ALUCtrl);

    // SRAI vs SRLI: for I-type shifts, funct7[5] IS meaningful (real
    // encoding, not immediate noise), so this must still distinguish them.
    funct3 = 3'b101; funct7 = 7'b0000000;
    #10; $display("SRLI -> %b", ALUCtrl);

    funct7 = 7'b0100000;
    #10; $display("SRAI -> %b", ALUCtrl);

    $finish;

end

endmodule