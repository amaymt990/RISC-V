`timescale 1ns/1ps

module cpu_pipeline(

    input clk,
    input reset

);

//==============================
// IF Stage
//==============================

wire [31:0] pc;
wire [31:0] next_pc;
wire [31:0] instruction;

assign next_pc = pc + 4;

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

//==============================
// IF/ID Pipeline Register
//==============================

wire [31:0] if_id_pc;
wire [31:0] if_id_instruction;

if_id_register if_id(

    .clk(clk),
    .reset(reset),

    .pc_in(pc),
    .instruction_in(instruction),

    .pc_out(if_id_pc),
    .instruction_out(if_id_instruction)

);

endmodule