`timescale 1ns/1ps

module cpu_pipeline(

    input clk,
    input reset,

    // Debug/monitor ports -- synthesis-only. Without at least some
    // observable output, a synthesis tool correctly (if unhelpfully)
    // optimizes the entire design away as unreachable dead logic, since
    // every real port on the functional cpu_pipeline module is clk/reset
    // only and all state lives in internal register/memory arrays.
    output [31:0] dbg_pc,
    output [31:0] dbg_wb_data,
    output [4:0]  dbg_wb_rd,
    output        dbg_wb_regwrite

);

//========================================================================
// All signal declarations up front (avoids implicit-wire / declare-
// after-use issues in strict Verilog toolchains).
//========================================================================

// Hazard / forwarding / flush control
wire hazard_stall;
wire pipeline_flush;
wire [1:0] forwardA, forwardB;

// IF stage
wire [31:0] pc;
wire [31:0] if_pc_plus4;
wire [31:0] instruction;
wire [31:0] next_pc;
wire        pc_write;

// IF/ID register
wire [31:0] if_id_pc;
wire [31:0] if_id_instruction;
wire [4:0]  if_id_rs1;
wire [4:0]  if_id_rs2;

// ID stage
wire [31:0] id_read_data1, id_read_data2, id_immediate;
wire [4:0]  id_rs1, id_rs2, id_rd;
wire [2:0]  id_funct3;
wire [6:0]  id_funct7;
wire        id_RegWrite, id_ALUSrc, id_MemRead, id_MemWrite;
wire        id_MemtoReg, id_Branch, id_Jump;
wire        id_JALR;
wire [1:0]  id_ALUOp;
wire [1:0]  id_Op1Sel;

// ID/EX register
wire [31:0] id_ex_pc, id_ex_read_data1, id_ex_read_data2, id_ex_immediate;
wire [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
wire [2:0]  id_ex_funct3;
wire [6:0]  id_ex_funct7;
wire        id_ex_RegWrite, id_ex_ALUSrc, id_ex_MemRead, id_ex_MemWrite;
wire        id_ex_MemtoReg, id_ex_Branch, id_ex_Jump;
wire        id_ex_JALR;
wire [1:0]  id_ex_ALUOp;
wire [1:0]  id_ex_Op1Sel;

// EX stage
wire [31:0] ex_alu_result, ex_branch_target, ex_store_data, ex_pc_plus4;
wire        ex_zero, ex_branch_taken;

// EX/MEM register
wire [31:0] ex_mem_alu_result, ex_mem_write_data, ex_mem_pc_plus4;
wire [4:0]  ex_mem_rd;
wire        ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite, ex_mem_MemtoReg;
wire        ex_mem_Branch, ex_mem_Jump, ex_mem_branch_taken;
wire [31:0] ex_mem_branch_target;

// MEM stage
wire [31:0] mem_read_data;

// MEM/WB register
wire [31:0] mem_wb_read_data, mem_wb_alu_result, mem_wb_pc_plus4;
wire [4:0]  mem_wb_rd;
wire        mem_wb_RegWrite, mem_wb_MemtoReg, mem_wb_Jump;

// WB stage
wire [31:0] wb_write_back_data;

//========================================================================
// IF Stage
//========================================================================

assign if_pc_plus4 = pc + 32'd4;
assign pc_write    = ~hazard_stall;
assign next_pc     = pipeline_flush ? ex_branch_target : if_pc_plus4;

program_counter PC(
    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .pc_write(pc_write),
    .pc(pc)
);

instruction_memory IM(
    .pc(pc),
    .instruction(instruction)
);

//========================================================================
// IF/ID Register
//========================================================================

if_id_register IF_ID(
    .clk(clk),
    .reset(reset),
    .stall(hazard_stall),
    .flush(pipeline_flush),
    .pc_in(pc),
    .instruction_in(instruction),
    .pc_out(if_id_pc),
    .instruction_out(if_id_instruction)
);

// Source registers of the instruction currently in ID, needed one cycle
// early by the hazard detection unit.
assign if_id_rs1 = if_id_instruction[19:15];
assign if_id_rs2 = if_id_instruction[24:20];

//========================================================================
// ID Stage
//========================================================================

id_stage ID(
    .clk(clk),
    .reset(reset),

    .instruction(if_id_instruction),

    .write_data(wb_write_back_data),
    .write_reg(mem_wb_rd),
    .reg_write(mem_wb_RegWrite),

    .read_data1(id_read_data1),
    .read_data2(id_read_data2),
    .immediate(id_immediate),

    .rs1(id_rs1),
    .rs2(id_rs2),
    .rd(id_rd),

    .funct3(id_funct3),
    .funct7(id_funct7),

    .RegWrite(id_RegWrite),
    .ALUSrc(id_ALUSrc),
    .MemRead(id_MemRead),
    .MemWrite(id_MemWrite),
    .MemtoReg(id_MemtoReg),
    .Branch(id_Branch),
    .Jump(id_Jump),
    .JALR(id_JALR),
    .ALUOp(id_ALUOp),
    .Op1Sel(id_Op1Sel)
);

//========================================================================
// Hazard Detection Unit
//========================================================================
// Looks at the load (if any) currently in EX (held in ID/EX) versus the
// source registers of the instruction currently in ID (held in IF/ID).

hazard_detection_unit HDU(
    .id_ex_memread(id_ex_MemRead),
    .id_ex_rd(id_ex_rd),

    .if_id_rs1(if_id_rs1),
    .if_id_rs2(if_id_rs2),

    .stall(hazard_stall)
);

//========================================================================
// ID/EX Register
//========================================================================

id_ex_register ID_EX(
    .clk(clk),
    .reset(reset),
    .flush(pipeline_flush || hazard_stall),

    .pc_in(if_id_pc),
    .read_data1_in(id_read_data1),
    .read_data2_in(id_read_data2),
    .immediate_in(id_immediate),

    .rs1_in(id_rs1),
    .rs2_in(id_rs2),
    .rd_in(id_rd),

    .funct3_in(id_funct3),
    .funct7_in(id_funct7),

    .RegWrite_in(id_RegWrite),
    .ALUSrc_in(id_ALUSrc),
    .MemRead_in(id_MemRead),
    .MemWrite_in(id_MemWrite),
    .MemtoReg_in(id_MemtoReg),
    .Branch_in(id_Branch),
    .Jump_in(id_Jump),
    .JALR_in(id_JALR),
    .ALUOp_in(id_ALUOp),
    .Op1Sel_in(id_Op1Sel),

    .pc_out(id_ex_pc),
    .read_data1_out(id_ex_read_data1),
    .read_data2_out(id_ex_read_data2),
    .immediate_out(id_ex_immediate),

    .rs1_out(id_ex_rs1),
    .rs2_out(id_ex_rs2),
    .rd_out(id_ex_rd),

    .funct3_out(id_ex_funct3),
    .funct7_out(id_ex_funct7),

    .RegWrite_out(id_ex_RegWrite),
    .ALUSrc_out(id_ex_ALUSrc),
    .MemRead_out(id_ex_MemRead),
    .MemWrite_out(id_ex_MemWrite),
    .MemtoReg_out(id_ex_MemtoReg),
    .Branch_out(id_ex_Branch),
    .Jump_out(id_ex_Jump),
    .JALR_out(id_ex_JALR),
    .ALUOp_out(id_ex_ALUOp),
    .Op1Sel_out(id_ex_Op1Sel)
);

//========================================================================
// Forwarding Unit
//========================================================================

forwarding_unit FU(
    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),

    .ex_mem_rd(ex_mem_rd),
    .ex_mem_regwrite(ex_mem_RegWrite),

    .mem_wb_rd(mem_wb_rd),
    .mem_wb_regwrite(mem_wb_RegWrite),

    .forwardA(forwardA),
    .forwardB(forwardB)
);

//========================================================================
// EX Stage
//========================================================================

ex_stage EX(
    .read_data1(id_ex_read_data1),
    .read_data2(id_ex_read_data2),
    .immediate(id_ex_immediate),
    .pc(id_ex_pc),

    .funct3(id_ex_funct3),
    .funct7(id_ex_funct7),

    .ALUSrc(id_ex_ALUSrc),
    .ALUOp(id_ex_ALUOp),
    .Op1Sel(id_ex_Op1Sel),
    .JALR(id_ex_JALR),

    .forwardA(forwardA),
    .forwardB(forwardB),
    .ex_mem_alu_result(ex_mem_alu_result),
    .wb_write_back_data(wb_write_back_data),

    .alu_result(ex_alu_result),
    .zero(ex_zero),
    .branch_taken(ex_branch_taken),
    .branch_target(ex_branch_target),
    .store_data(ex_store_data),
    .pc_plus4(ex_pc_plus4)
);

// A taken branch or a jump, both resolved here in EX, redirect the PC and
// flush the two instructions already fetched down the wrong path.
assign pipeline_flush = (id_ex_Branch && ex_branch_taken) || id_ex_Jump;

//========================================================================
// EX/MEM Register
//========================================================================

ex_mem_register EX_MEM(
    .clk(clk),
    .reset(reset),

    .alu_result_in(ex_alu_result),
    .write_data_in(ex_store_data),
    .rd_in(id_ex_rd),
    .branch_target_in(ex_branch_target),
    .branch_taken_in(ex_branch_taken),
    .pc_plus4_in(ex_pc_plus4),

    .RegWrite_in(id_ex_RegWrite),
    .MemRead_in(id_ex_MemRead),
    .MemWrite_in(id_ex_MemWrite),
    .MemtoReg_in(id_ex_MemtoReg),
    .Branch_in(id_ex_Branch),
    .Jump_in(id_ex_Jump),

    .alu_result_out(ex_mem_alu_result),
    .write_data_out(ex_mem_write_data),
    .rd_out(ex_mem_rd),
    .branch_target_out(ex_mem_branch_target),
    .branch_taken_out(ex_mem_branch_taken),
    .pc_plus4_out(ex_mem_pc_plus4),

    .RegWrite_out(ex_mem_RegWrite),
    .MemRead_out(ex_mem_MemRead),
    .MemWrite_out(ex_mem_MemWrite),
    .MemtoReg_out(ex_mem_MemtoReg),
    .Branch_out(ex_mem_Branch),
    .Jump_out(ex_mem_Jump)
);

//========================================================================
// MEM Stage
//========================================================================

mem_stage MEM(
    .clk(clk),

    .MemRead(ex_mem_MemRead),
    .MemWrite(ex_mem_MemWrite),

    .address(ex_mem_alu_result),
    .write_data(ex_mem_write_data),

    .read_data(mem_read_data)
);

//========================================================================
// MEM/WB Register
//========================================================================

mem_wb_register MEM_WB(
    .clk(clk),
    .reset(reset),

    .read_data_in(mem_read_data),
    .alu_result_in(ex_mem_alu_result),
    .pc_plus4_in(ex_mem_pc_plus4),
    .rd_in(ex_mem_rd),

    .RegWrite_in(ex_mem_RegWrite),
    .MemtoReg_in(ex_mem_MemtoReg),
    .Jump_in(ex_mem_Jump),

    .read_data_out(mem_wb_read_data),
    .alu_result_out(mem_wb_alu_result),
    .pc_plus4_out(mem_wb_pc_plus4),
    .rd_out(mem_wb_rd),

    .RegWrite_out(mem_wb_RegWrite),
    .MemtoReg_out(mem_wb_MemtoReg),
    .Jump_out(mem_wb_Jump)
);

//========================================================================
// WB Stage
//========================================================================

wb_stage WB(
    .read_data(mem_wb_read_data),
    .alu_result(mem_wb_alu_result),
    .pc_plus4(mem_wb_pc_plus4),

    .MemtoReg(mem_wb_MemtoReg),
    .Jump(mem_wb_Jump),

    .write_back_data(wb_write_back_data)
);

// Debug/monitor port wiring (synthesis-only)
assign dbg_pc          = pc;
assign dbg_wb_data     = wb_write_back_data;
assign dbg_wb_rd       = mem_wb_rd;
assign dbg_wb_regwrite = mem_wb_RegWrite;

endmodule
