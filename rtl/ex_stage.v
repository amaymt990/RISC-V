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
    input [1:0] Op1Sel,   // 00=register, 01=PC (AUIPC), 10=zero (LUI)

    // Forwarding control (from forwarding_unit)
    input [1:0] forwardA,
    input [1:0] forwardB,
    input [31:0] ex_mem_alu_result,   // value sitting in EX/MEM (forward = 2'b10)
    input [31:0] wb_write_back_data,  // value being written back this cycle (forward = 2'b01)

    output [31:0] alu_result,
    output zero,
    output branch_taken,
    output [31:0] branch_target,
    output [31:0] store_data,   // forwarded rs2 value, for SW
    output [31:0] pc_plus4      // for JAL link value

);

wire [31:0] operand1_fwd;
wire [31:0] operand1;
wire [31:0] operand2_base;   // forwarded rs2, before the ALUSrc/immediate mux
wire [31:0] operand2;
wire [3:0] alu_ctrl;

//-----------------------------------------
// Forwarding Muxes
//-----------------------------------------
// 2'b00 = no hazard, use value latched in ID/EX
// 2'b10 = forward from EX/MEM (previous instruction's ALU result)
// 2'b01 = forward from MEM/WB (instruction two ahead, about to write back)

assign operand1_fwd = (forwardA == 2'b10) ? ex_mem_alu_result :
                       (forwardA == 2'b01) ? wb_write_back_data :
                                             read_data1;

// AUIPC and LUI are U-type: instruction[19:15] is part of their immediate,
// not a real rs1, so forwarding into operand1 must be overridden for them
// regardless of what the (meaningless, for these instructions) forwarding
// comparison happened to produce.
assign operand1 = (Op1Sel == 2'b01) ? pc :      // AUIPC
                   (Op1Sel == 2'b10) ? 32'd0 :   // LUI
                                       operand1_fwd;

assign operand2_base = (forwardB == 2'b10) ? ex_mem_alu_result :
                        (forwardB == 2'b01) ? wb_write_back_data :
                                              read_data2;

//-----------------------------------------
// ALU Operand Selection
//-----------------------------------------

assign operand2    = ALUSrc ? immediate : operand2_base;
assign store_data  = operand2_base;      // SW always stores the (forwarded) rs2 value
assign branch_target = pc + immediate;
assign pc_plus4     = pc + 32'd4;

//-----------------------------------------
// ALU Control
//-----------------------------------------

alu_control alu_ctrl_unit(

    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .is_itype(ALUSrc),

    .ALUCtrl(alu_ctrl)

);

//-----------------------------------------
// ALU
//-----------------------------------------

alu alu_unit(

    .a(operand1),
    .b(operand2),

    .alu_control(alu_ctrl),

    .result(alu_result),
    .zero(zero)

);

//-----------------------------------------
// Branch Comparator
//-----------------------------------------
// Uses forwarded operands too, so a branch depending on the immediately
// preceding instruction's result still compares the correct values.

branch_comparator bc(

    .rs1_data(operand1),
    .rs2_data(operand2_base),
    .funct3(funct3),

    .branch_taken(branch_taken)

);

endmodule