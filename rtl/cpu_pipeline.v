`timescale 1ns/1ps

module cpu_pipeline(

    input clk,
    input reset

);

//====================================================
// IF Stage Wires
//====================================================

wire [31:0] pc;
wire [31:0] instruction;
wire [31:0] next_pc;

//====================================================
// IF/ID Wires
//====================================================

wire [31:0] if_id_pc;
wire [31:0] if_id_instruction;

//====================================================
// PC Logic
//====================================================

assign next_pc = pc + 32'd4;

//====================================================
// IF Stage
//====================================================

if_stage IF(

    .clk(clk),
    .reset(reset),

    .next_pc(next_pc),

    .pc(pc),
    .instruction(instruction)

);

//====================================================
// IF/ID Register
//====================================================

if_id_register IF_ID(

    .clk(clk),
    .reset(reset),

    .pc_in(pc),
    .instruction_in(instruction),

    .pc_out(if_id_pc),
    .instruction_out(if_id_instruction)

);

endmodule