`timescale 1ns/1ps

module cpu(

    input clk,
    input reset

);

// Program Counter
wire [31:0] pc;
wire [31:0] next_pc;

// Instruction
wire [31:0] instruction;

// Register File
wire [31:0] read_data1;
wire [31:0] read_data2;

// Immediate
wire [31:0] immediate;

// ALU
wire [31:0] alu_result;
wire zero;

// Memory
wire [31:0] memory_data;

// Branch
wire branch_taken;

// Control
wire RegWrite;
wire ALUSrc;
wire MemRead;
wire MemWrite;
wire MemtoReg;
wire Branch;
wire Jump;
wire [1:0] ALUOp;

// ALU Control
wire [3:0] ALUCtrl;

program_counter pc_unit(

    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .pc(pc)

);

instruction_memory imem(

    .pc(pc),
    .instruction(instruction)

);

control_unit control(

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

immediate_generator imm_gen(

    .instruction(instruction),
    .immediate(immediate)

);

register_file rf(

    .clk(clk),
    .we(RegWrite),

    .rs1(instruction[19:15]),
    .rs2(instruction[24:20]),
    .rd(instruction[11:7]),

    .write_data(MemtoReg ? memory_data : alu_result),

    .read_data1(read_data1),
    .read_data2(read_data2)

);

endmodule