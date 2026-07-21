`timescale 1ns/1ps

module data_memory_tb;

reg clk;
reg mem_write;
reg mem_read;
reg [31:0] address;
reg [31:0] write_data;

wire [31:0] read_data;

data_memory uut(
    .clk(clk),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .address(address),
    .write_data(write_data),
    .read_data(read_data)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    mem_write = 0;
    mem_read = 0;
    address = 0;
    write_data = 0;

    #10;

    // Write 1234 to address 0
    mem_write = 1;
    address = 0;
    write_data = 1234;
    #10;

    mem_write = 0;

    // Read address 0
    mem_read = 1;
    #10;

    $display("Memory[0] = %d", read_data);

    $finish;

end

endmodule