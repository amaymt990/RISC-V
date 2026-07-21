`timescale 1ns/1ps

module control_unit_tb;

reg [6:0] opcode;

wire RegWrite;
wire ALUSrc;
wire MemRead;
wire MemWrite;
wire MemtoReg;
wire Branch;
wire [1:0] ALUOp;

control_unit uut(
    .opcode(opcode),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .Branch(Branch),
    .ALUOp(ALUOp)
);

initial begin

    opcode = 7'b0110011;
    #10;
    $display("R-Type: RegWrite=%b ALUSrc=%b ALUOp=%b", RegWrite, ALUSrc, ALUOp);

    opcode = 7'b0000011;
    #10;
    $display("Load: RegWrite=%b MemRead=%b MemtoReg=%b", RegWrite, MemRead, MemtoReg);

    opcode = 7'b0100011;
    #10;
    $display("Store: MemWrite=%b", MemWrite);

    opcode = 7'b1100011;
    #10;
    $display("Branch: Branch=%b", Branch);

    $finish;

end

endmodule