`timescale 1ns/1ps

module cpu(

    input clk,
    input reset

);

// Program Counter
wire [31:0] pc;
wire [31:0] next_pc;
wire [31:0] pc_plus_4;
wire [31:0] branch_target;

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
wire [31:0] write_back_data;


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
wire JALR;
wire [1:0] ALUOp;
wire [1:0] Op1Sel;

// ALU Control
wire [3:0] ALUCtrl;
wire [31:0] alu_input_a;
wire [31:0] alu_input_b;

// AUIPC/LUI are U-type: instruction[19:15] is part of their immediate, not
// a real rs1, so operand A must be overridden rather than using read_data1.
assign alu_input_a  = (Op1Sel == 2'b01) ? pc :      // AUIPC
                       (Op1Sel == 2'b10) ? 32'd0 :   // LUI
                                            read_data1;
assign alu_input_b   = ALUSrc ? immediate : read_data2;
assign write_back_data =
    Jump     ? pc_plus_4 :
    MemtoReg ? memory_data :
               alu_result;
assign pc_plus_4     = pc + 4;

// branch_target is (pc + immediate) for branches and JAL, but for JALR
// it's (alu_input_a + immediate) with the LSB cleared per the RISC-V spec.
assign branch_target = JALR ? ((alu_input_a + immediate) & ~32'd1)
                             : (pc + immediate);
assign next_pc =
    Jump ? branch_target :
    (Branch && branch_taken) ? branch_target :
    pc_plus_4;
program_counter pc_unit(

    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .pc_write(1'b1),
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
    .JALR(JALR),
    .ALUOp(ALUOp),
    .Op1Sel(Op1Sel)

);

immediate_generator imm_gen(

    .instruction(instruction),
    .immediate(immediate)

);

register_file rf(

    .clk(clk),
    .reset(reset),
    .we(RegWrite),

    .rs1(instruction[19:15]),
    .rs2(instruction[24:20]),
    .rd(instruction[11:7]),

    .write_data(write_back_data),

    .read_data1(read_data1),
    .read_data2(read_data2)

);

alu_control alu_ctrl(

    .ALUOp(ALUOp),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .is_itype(ALUSrc),

    .ALUCtrl(ALUCtrl)

);


alu alu_unit(

    .a(alu_input_a),
    .b(alu_input_b),
    .alu_control(ALUCtrl),

    .result(alu_result),
    .zero(zero)

);



data_memory dmem(

    .clk(clk),
    .mem_write(MemWrite),
    .mem_read(MemRead),

    .address(alu_result),
    .write_data(read_data2),

    .read_data(memory_data)

);


branch_comparator branch_cmp(

    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .funct3(instruction[14:12]),

    .branch_taken(branch_taken)

);



endmodule