`timescale 1ns/1ps

// Detects a load-use hazard: the instruction currently in EX (held in
// ID/EX) is a load, and the instruction currently in ID (held in IF/ID)
// needs that load's result *this* cycle -- one cycle too early for
// forwarding to save it. We stall PC/IF-ID for one cycle and bubble ID/EX.
module hazard_detection_unit(

    input id_ex_memread,
    input [4:0] id_ex_rd,

    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output reg stall

);

always @(*) begin
    if (id_ex_memread &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
        stall = 1'b1;
    else
        stall = 1'b0;
end

endmodule