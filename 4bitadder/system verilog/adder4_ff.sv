module adder4_ff (
    input  logic       clk,
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,

    output logic [3:0] sum,
    output logic       cout
);

    logic [4:0] result;

    // Combinational full adder
    assign result = {1'b0, a} + {1'b0, b} + cin;

    // Five D flip-flops
    always_ff @(posedge clk) begin
        sum  <= result[3:0];
        cout <= result[4];
    end

endmodule