`timescale 1ns/1ps

module alu_control(

    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,

    output reg [3:0] ALUCtrl

);

always @(*) begin

    case(ALUOp)

        // Load / Store
        2'b00:
            ALUCtrl = 4'b0000;   // ADD

        // Branch
        2'b01:
            ALUCtrl = 4'b0001;   // SUB

        // R-Type / I-Type
        2'b10: begin

            case(funct3)

                3'b000:
                    if(funct7 == 7'b0100000)
                        ALUCtrl = 4'b0001;    // SUB
                    else
                        ALUCtrl = 4'b0000;    // ADD

                3'b111:
                    ALUCtrl = 4'b0010;        // AND

                3'b110:
                    ALUCtrl = 4'b0011;        // OR

                3'b100:
                    ALUCtrl = 4'b0100;        // XOR

                3'b001:
                    ALUCtrl = 4'b0101;        // SLL

                3'b101:
                    ALUCtrl = 4'b0110;        // SRL

                3'b010:
                    ALUCtrl = 4'b0111;        // SLT

                default:
                    ALUCtrl = 4'b0000;

            endcase

        end

        default:
            ALUCtrl = 4'b0000;

    endcase

end

endmodule