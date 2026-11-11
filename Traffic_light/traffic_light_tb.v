
`timescale 1ns/1ps

module traffic_light_tb;

    reg clk;
    reg reset;

    wire red;
    wire yellow;
    wire green;

    // Instantiate traffic light controller
    traffic_light uut (
        .clk(clk),
        .reset(reset),
        .red(red),
        .yellow(yellow),
        .green(green)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial
    begin
        clk = 0;
        reset = 1;

        #20;
        reset = 0;

        // Run simulation
        #500;

        $finish;
    end

    // Display output
    initial
    begin
        $monitor("Time=%0t | RED=%b YELLOW=%b GREEN=%b",
                  $time, red, yellow, green);
    end

endmodule
