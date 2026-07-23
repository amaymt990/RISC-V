`timescale 1ns/1ps

module ex_stage(

    input [31:0] read_data1,
    input [31:0] read_data2,
    input [31:0] immediate,
    input [31:0] pc,

    input [2:0] funct3,
    input [6:0] funct7,

    input ALUSrc,
    input [1:0] ALUOp,

    output [31:0] alu_result,
    output zero,
    output branch_taken,
    output [31:0] branch_target

);

wire [31:0] operand2;
wire [3:0] alu_ctrl;

//-----------------------------------------
// ALU Operand Selection
//-----------------------------------------

assign operand2 = ALUSrc ? immediate : read_data2;
assign branch_target = pc + immediate;

//-----------------------------------------
// ALU Control
//-----------------------------------------

alu_control alu_ctrl_unit(

    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),

    .ALUCtrl(alu_ctrl)

);

//-----------------------------------------
// ALU
//-----------------------------------------

alu alu_unit(

    .a(read_data1),
    .b(operand2),

    .alu_control(alu_ctrl),

    .result(alu_result),
    .zero(zero)

);

//-----------------------------------------
// Branch Comparator
//-----------------------------------------

branch_comparator bc(

    .rs1_data(read_data1),
    .rs2_data(read_data2),

    .branch_taken(branch_taken)

);

endmodule