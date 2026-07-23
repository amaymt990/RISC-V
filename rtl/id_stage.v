`timescale 1ns/1ps

module id_stage(

    input clk,
    input reset,

    input [31:0] instruction,

    input [31:0] write_data,
    input [4:0] write_reg,
    input reg_write,

    output [31:0] read_data1,
    output [31:0] read_data2,
    output [31:0] immediate,

    output RegWrite,
    output ALUSrc,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output Branch,
    output Jump,
    output [1:0] ALUOp

);

register_file rf(

    .clk(clk),
    .reset(reset),
    .we(reg_write),

    .rs1(instruction[19:15]),
    .rs2(instruction[24:20]),
    .rd(write_reg),

    .write_data(write_data),

    .read_data1(read_data1),
    .read_data2(read_data2)

);

control_unit cu(

    .opcode(instruction[6:0]),

    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .Branch(Branch),
    .Jump(Jump),
    .ALUOp(ALUOp)

);

immediate_generator ig(

    .instruction(instruction),
    .immediate(immediate)

);

endmodule