
`timescale 1ns/1ps

module fa8bit_tb;

    reg  [7:0] A, B;
    reg        Cin;

    wire [7:0] Sum;
    wire       Cout;

    // Connect the full-adder design
    full_adder_8bit DUT (
        .A(A),
        .B(B),
        .Cin(Cin),
        .Sum(Sum),
        .Cout(Cout)
    );

    reg [8:0] expected;

    initial begin

        A = 10;
        B = 20;
        Cin = 0;
        #10;

        A = 15;
        B = 15;
        Cin = 1;
        #10;

        A = 255;
        B = 1;
        Cin = 0;
        #10;

        A = 255;
        B = 255;
        Cin = 1;
        #10;

        A = 0;
        B = 0;
        Cin = 0;
        #10;

        $finish;
    end

    // Check the output after each input change
    always @(A or B or Cin) begin
        #1;
        expected = {1'b0, A} + {1'b0, B} + Cin;

        if ({Cout, Sum} !== expected)
            $display("ERROR: A=%d B=%d", A, B);
        else
            $display("PASS: A=%d B=%d Sum=%d Cout=%b",
                     A, B, Sum, Cout);
    end

endmodule
