`timescale 1ns/1ps

module register_file_tb;

    reg clk;
    reg we;

    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [4:0] rd;

    reg [31:0] write_data;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Instantiate Register File
    register_file uut (
        .clk(clk),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

        // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

        initial begin

        // Initialize signals
        we = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        write_data = 0;

        // Wait a little
        #10;

        // Write 100 to x5
        we = 1;
        rd = 5;
        write_data = 100;
        #10;

        // Read x5
        we = 0;
        rs1 = 5;
        #10;
        $display("x5 = %d", read_data1);

        // Write 200 to x10
        we = 1;
        rd = 10;
        write_data = 200;
        #10;

        // Read x10
        we = 0;
        rs2 = 10;
        #10;
        $display("x10 = %d", read_data2);

        // Try writing to x0 (should fail)
        we = 1;
        rd = 0;
        write_data = 999;
        #10;

        // Read x0
        we = 0;
        rs1 = 0;
        #10;
        $display("x0 = %d", read_data1);

        $finish;
    end

endmodule