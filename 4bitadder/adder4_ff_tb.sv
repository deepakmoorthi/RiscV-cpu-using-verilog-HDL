`timescale 1ns/1ps

module adder4_ff_tb;

    logic clk;
    logic [3:0] a, b;
    logic cin;

    logic [3:0] sum;
    logic cout;

    // Instantiate the design
    adder4_ff uut (
        .clk(clk),
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    // Generate clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Apply test inputs
    initial begin
        a = 4'd3;
        b = 4'd5;
        cin = 0;

        #10;
        a = 4'd15;
        b = 4'd1;

        #10;
        a = 4'd10;
        b = 4'd5;
        cin = 1;

        #10;
        a = 4'd15;
        b = 4'd15;
        cin = 1;

        #20;
        $finish;
    end

endmodule