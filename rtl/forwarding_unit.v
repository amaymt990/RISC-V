`timescale 1ns/1ps

// Decides whether the EX stage should use the values latched in ID/EX,
// or forward a more recent (not-yet-written-back) result instead.
module forwarding_unit(

    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,

    input [4:0] ex_mem_rd,
    input ex_mem_regwrite,

    input [4:0] mem_wb_rd,
    input mem_wb_regwrite,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB

);

// 2'b00 = no forwarding, use ID/EX value
// 2'b10 = forward from EX/MEM (result is 1 instruction ahead)
// 2'b01 = forward from MEM/WB (result is 2 instructions ahead)
//
// EX/MEM is checked first: it holds the *more recent* result, so if both
// an EX/MEM and a MEM/WB match the same register, EX/MEM wins.

always @(*) begin

    // ForwardA (rs1)
    if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
        forwardA = 2'b10;
    else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
        forwardA = 2'b01;
    else
        forwardA = 2'b00;

    // ForwardB (rs2)
    if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
        forwardB = 2'b10;
    else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
        forwardB = 2'b01;
    else
        forwardB = 2'b00;

end

endmodule