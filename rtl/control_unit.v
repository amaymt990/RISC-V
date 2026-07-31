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
    output reg JALR,   // 1 = jump target is (rs1 + immediate), not (pc + immediate)
    output reg [1:0] ALUOp,

    // Selects the EX stage's first ALU operand. Needed because AUIPC and
    // LUI are U-type: their instruction[19:15] bits are part of the
    // immediate, not a real source register, so the datapath can't just
    // use "read_data1" for them like every other instruction.
    //   00 = register (normal case, forwarding-aware)
    //   01 = PC        (AUIPC: rd = pc + immediate)
    //   10 = zero       (LUI: rd = 0 + immediate = immediate)
    output reg [1:0] Op1Sel

);

localparam OP1_REG  = 2'b00;
localparam OP1_PC   = 2'b01;
localparam OP1_ZERO = 2'b10;

always @(*) begin

    // Defaults
    RegWrite = 0;
    ALUSrc   = 0;
    MemRead  = 0;
    MemWrite = 0;
    MemtoReg = 0;
    Branch   = 0;
    Jump     = 0;
    JALR     = 0;
    ALUOp    = 2'b00;
    Op1Sel   = OP1_REG;

    case(opcode)

        // R-Type
        7'b0110011: begin
            RegWrite = 1;
            ALUOp    = 2'b10;
        end

        // I-Type ALU (ADDI/ANDI/ORI/XORI/SLTI/SLLI/SRLI/SRAI)
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

        // Branch (BEQ/BNE/BLT/BGE/BLTU/BGEU all share this opcode --
        // branch_comparator distinguishes them using funct3)
        7'b1100011: begin
            Branch = 1;
            ALUOp  = 2'b01;
        end

        // JAL
        7'b1101111: begin
            Jump     = 1;
            RegWrite = 1;
        end

        // JALR: rd = pc+4, target = (rs1 + immediate) & ~1
        // Op1Sel stays REG (default) -- JALR has a real rs1, unlike AUIPC/LUI
        7'b1100111: begin
            Jump     = 1;
            JALR     = 1;
            RegWrite = 1;
            ALUSrc   = 1;
        end

        // LUI: rd = immediate
        7'b0110111: begin
            RegWrite = 1;
            ALUSrc   = 1;
            Op1Sel   = OP1_ZERO;
        end

        // AUIPC: rd = pc + immediate
        7'b0010111: begin
            RegWrite = 1;
            ALUSrc   = 1;
            Op1Sel   = OP1_PC;
        end

        // FENCE: this pipeline is single-issue and in-order with no
        // caching, so there is no memory reordering to fence against --
        // architecturally a NOP. Explicit case kept for documentation;
        // all default control signals already produce a NOP.
        7'b0001111: begin
        end

    endcase

end

endmodule
