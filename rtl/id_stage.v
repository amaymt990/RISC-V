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

// Register fields
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,

    // Instruction fields
    output [2:0] funct3,
    output [6:0] funct7,

    output RegWrite,
    output ALUSrc,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output Branch,
    output Jump,
    output JALR,
    output [1:0] ALUOp,
    output [1:0] Op1Sel

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
    .JALR(JALR),
    .ALUOp(ALUOp),
    .Op1Sel(Op1Sel)

);

immediate_generator ig(

    .instruction(instruction),
    .immediate(immediate)

);


//-----------------------------------------
// Instruction Fields
//-----------------------------------------

assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

endmodule