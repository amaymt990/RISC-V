`timescale 1ns/1ps

module control_unit(

    input [6:0] opcode,

    output reg RegWrite,
    output reg ALUSrc,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg Branch,
    output reg Jump,
    output reg [1:0] ALUOp

);

always @(*) begin

    // Defaults
    RegWrite = 0;
    ALUSrc   = 0;
    MemRead  = 0;
    MemWrite = 0;
    MemtoReg = 0;
    Branch   = 0;
    Jump     = 0;
    ALUOp    = 2'b00;

    case(opcode)

        // R-Type
        7'b0110011: begin
            RegWrite = 1;
            ALUOp    = 2'b10;
        end

        // I-Type
        7'b0010011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b10;
        end

        // Load
        7'b0000011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            MemRead  = 1;
            MemtoReg = 1;
            ALUOp    = 2'b00;
        end

        // Store
        7'b0100011: begin
            ALUSrc   = 1;
            MemWrite = 1;
            ALUOp    = 2'b00;
        end

        // Branch
        7'b1100011: begin
            Branch = 1;
            ALUOp  = 2'b01;
        end

        // JAL
        7'b1101111: begin
            Jump     = 1;
            RegWrite = 1;
        end

        // LUI
        7'b0110111: begin
            RegWrite = 1;
            ALUSrc   = 1;
        end

    endcase

end

endmodule