`timescale 1ns/1ps

module id_ex_register(

    input clk,
    input reset,
    input flush,   // 1 = insert bubble (load-use stall or branch/jump taken)

    // Data
    input [31:0] pc_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] immediate_in,

    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,

    input [2:0] funct3_in,
    input [6:0] funct7_in,

    // Control
    input RegWrite_in,
    input ALUSrc_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,
    input Branch_in,
    input Jump_in,
    input [1:0] ALUOp_in,
    input [1:0] Op1Sel_in,
 

    // Outputs
    output reg [31:0] pc_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] immediate_out,

    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,

    output reg [2:0] funct3_out,
    output reg [6:0] funct7_out,

    output reg RegWrite_out,
    output reg ALUSrc_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out,
    output reg Branch_out,
    output reg Jump_out,
    output reg [1:0] ALUOp_out,
    output reg [1:0] Op1Sel_out
    
);

always @(posedge clk or posedge reset) begin

    if(reset || flush) begin

        pc_out <= 0;
        read_data1_out <= 0;
        read_data2_out <= 0;
        immediate_out <= 0;

        rs1_out <= 0;
        rs2_out <= 0;
        rd_out <= 0;

        funct3_out <= 0;
        funct7_out <= 0;

        RegWrite_out <= 0;
        ALUSrc_out <= 0;
        MemRead_out <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
        Branch_out <= 0;
        Jump_out <= 0;
        ALUOp_out <= 0;
        Op1Sel_out <= 0;
        

    end
    else begin

        pc_out <= pc_in;
        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        immediate_out <= immediate_in;

        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;

        funct3_out <= funct3_in;
        funct7_out <= funct7_in;

        RegWrite_out <= RegWrite_in;
        ALUSrc_out <= ALUSrc_in;
        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        MemtoReg_out <= MemtoReg_in;
        Branch_out <= Branch_in;
        Jump_out <= Jump_in;
        ALUOp_out <= ALUOp_in;
        Op1Sel_out <= Op1Sel_in;
        

    end

end

endmodule