module adder4_ff (
    input wire clk,
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,

    output reg [3:0] sum,
    output reg cout
);

    wire [4:0] result;

    // 4-bit full adder
    assign result = a + b + cin;

    // Store sum and carry in D flip-flops
    always @(posedge clk) begin
        sum  <= result[3:0];
        cout <= result[4];
    end

endmodule