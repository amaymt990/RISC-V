`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0] alu_control;

    wire [31:0] result;
    wire zero;

    // Instantiate the ALU
    alu uut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    initial begin

        // ADD
        a = 10;
        b = 20;
        alu_control = 4'b0000;
        #10;
        $display("ADD: %d", result);

        // SUB
        a = 20;
        b = 10;
        alu_control = 4'b0001;
        #10;
        $display("SUB: %d", result);

        // AND
        a = 15;
        b = 7;
        alu_control = 4'b0010;
        #10;
        $display("AND: %d", result);

        // OR
        alu_control = 4'b0011;
        #10;
        $display("OR : %d", result);

        // XOR
        alu_control = 4'b0100;
        #10;
        $display("XOR: %d", result);

        // SLL
        a = 5;
        b = 2;
        alu_control = 4'b0101;
        #10;
        $display("SLL: %d", result);

        // SRL
        a = 20;
        b = 2;
        alu_control = 4'b0110;
        #10;
        $display("SRL: %d", result);

        // SLT (true)
        a = 5;
        b = 10;
        alu_control = 4'b0111;
        #10;
        $display("SLT: %d", result);

        // Zero Flag
        a = 10;
        b = 10;
        alu_control = 4'b0001;
        #10;
        $display("ZERO = %b", zero);

        $finish;

    end

endmodule