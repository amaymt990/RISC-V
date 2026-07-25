`timescale 1ns/1ps

module program_counter(

    input clk,
    input reset,
    input [31:0] next_pc,
    input pc_write,      // 0 = hold current PC (load-use stall)

    output reg [31:0] pc

);

always @(posedge clk or posedge reset) begin
    if(reset)
        pc <= 32'd0;
    else if(pc_write)
        pc <= next_pc;
    // else: hold current value
end

endmodule