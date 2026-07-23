`timescale 1ns/1ps

module if_id_register(

    input clk,
    input reset,

    input [31:0] pc_in,
    input [31:0] instruction_in,

    output reg [31:0] pc_out,
    output reg [31:0] instruction_out

);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        pc_out <= 32'd0;
        instruction_out <= 32'd0;
    end
    else begin
        pc_out <= pc_in;
        instruction_out <= instruction_in;
    end

end

endmodule