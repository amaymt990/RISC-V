module register_file(

    input clk,
    input we,
    input reset,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input [31:0] write_data,

    output [31:0] read_data1,
    output [31:0] read_data2

);

reg [31:0] registers [0:31];

assign read_data1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
assign read_data2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

integer i;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] <= 32'd0;
    end
    else if (we && (rd != 5'd0)) begin
        registers[rd] <= write_data;
    end
end

endmodule