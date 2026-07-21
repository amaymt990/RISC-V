`timescale 1ns/1ps

module alu_control_tb;

reg [1:0] ALUOp;
reg [2:0] funct3;
reg [6:0] funct7;

wire [3:0] ALUCtrl;

alu_control uut(

    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .ALUCtrl(ALUCtrl)

);

initial begin

    // ADD
    ALUOp = 2'b10;
    funct3 = 3'b000;
    funct7 = 7'b0000000;
    #10;
    $display("ADD  -> %b", ALUCtrl);

    // SUB
    funct7 = 7'b0100000;
    #10;
    $display("SUB  -> %b", ALUCtrl);

    // AND
    funct3 = 3'b111;
    funct7 = 7'b0000000;
    #10;
    $display("AND  -> %b", ALUCtrl);

    // OR
    funct3 = 3'b110;
    #10;
    $display("OR   -> %b", ALUCtrl);

    // XOR
    funct3 = 3'b100;
    #10;
    $display("XOR  -> %b", ALUCtrl);

    // SLL
    funct3 = 3'b001;
    #10;
    $display("SLL  -> %b", ALUCtrl);

    // SRL
    funct3 = 3'b101;
    #10;
    $display("SRL  -> %b", ALUCtrl);

    // SLT
    funct3 = 3'b010;
    #10;
    $display("SLT  -> %b", ALUCtrl);

    $finish;

end

endmodule