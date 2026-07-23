`timescale 1ns/1ps

module if_id_register(

    input clk,
    input reset,

    input stall,   // 1 = hold current contents (load-use hazard)
    input flush,   // 1 = insert bubble (branch/jump resolved taken)

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
    else if(flush) begin
        pc_out <= 32'd0;
        instruction_out <= 32'd0;   // NOP bubble
    end
    else if(!stall) begin
        pc_out <= pc_in;
        instruction_out <= instruction_in;
    end
    // else: stall -> hold current values

end

endmodule