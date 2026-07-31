`timescale 1ns/1ps

module alu_control(

    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    input is_itype,   // 1 for I-type ALU ops (ADDI family), 0 for R-type

    output reg [3:0] ALUCtrl

);

// funct7[5] legitimately distinguishes SRL/SRA for *both* R-type and
// I-type shift-immediates -- SLLI/SRLI/SRAI correctly place this bit at
// the same position in their encoding, by RISC-V's design.
//
// It must NOT be used to distinguish ADD/SUB for I-type ops in general,
// though: there is no "SUBI" instruction -- funct3=000 with an immediate
// is always ADDI -- and a negative immediate's upper bits can coincidentally
// look like funct7==0100000, which would wrongly trigger a subtract.
wire sub_alt   = funct7[5] && !is_itype;
wire shift_alt = funct7[5];

always @(*) begin

    case(ALUOp)

        // Load / Store / AUIPC / JAL link / LUI (operand1 is overridden
        // upstream for AUIPC/LUI -- this ALUOp value just always means "ADD")
        2'b00:
            ALUCtrl = 4'b0000;   // ADD

        // Branch -- alu_result itself is unused for branches (the
        // branch_comparator does the real funct3-aware comparison), this
        // is kept only for backward compatibility with anything that
        // still reads ALUOp==01 as "subtract".
        2'b01:
            ALUCtrl = 4'b0001;   // SUB

        // R-Type / I-Type ALU ops, decoded by funct3 (RV32I encoding)
        2'b10: begin

            case(funct3)

                3'b000: ALUCtrl = sub_alt ? 4'b0001 : 4'b0000;    // SUB : ADD
                3'b001: ALUCtrl = 4'b0101;                        // SLL
                3'b010: ALUCtrl = 4'b0111;                        // SLT
                3'b011: ALUCtrl = 4'b1001;                        // SLTU
                3'b100: ALUCtrl = 4'b0100;                        // XOR
                3'b101: ALUCtrl = shift_alt ? 4'b1000 : 4'b0110;  // SRA : SRL
                3'b110: ALUCtrl = 4'b0011;                        // OR
                3'b111: ALUCtrl = 4'b0010;                        // AND

                default: ALUCtrl = 4'b0000;

            endcase

        end

        default:
            ALUCtrl = 4'b0000;

    endcase

end

endmodule
