`timescale 1ns/1ps

module mem_wb_register(

    input clk,
    input reset,

    // Data
    input [31:0] read_data_in,
    input [31:0] alu_result_in,
    input [4:0] rd_in,

    // Control
    input RegWrite_in,
    input MemtoReg_in,

    // Outputs
    output reg [31:0] read_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemtoReg_out

);

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin
        read_data_out <= 32'd0;
        alu_result_out <= 32'd0;
        rd_out <= 5'd0;

        RegWrite_out <= 1'b0;
        MemtoReg_out <= 1'b0;
    end
    else
    begin
        read_data_out <= read_data_in;
        alu_result_out <= alu_result_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        MemtoReg_out <= MemtoReg_in;
    end

end

endmodule