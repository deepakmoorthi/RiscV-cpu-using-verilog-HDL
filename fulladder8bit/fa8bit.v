
module full_adder_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       Cin,
    output wire [7:0] Sum,
    output wire       Cout
);

    wire [8:0] result;

    assign result = {1'b0, A} + {1'b0, B} + Cin;

    assign Sum  = result[7:0];
    assign Cout = result[8];

endmodule
