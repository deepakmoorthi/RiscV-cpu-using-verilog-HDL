module d_ff (
    input  wire clk,
    input  wire rst,   // Asynchronous active-high reset
    input  wire d,
    output reg  q
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end

endmodule