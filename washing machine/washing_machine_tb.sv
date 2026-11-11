`timescale 1ns/1ps

module washing_machine_tb;

    logic clk;
    logic reset;
    logic start;
    logic door_closed;
    logic water_full;

    logic water_valve;
    logic wash_motor;
    logic drain_pump;
    logic spin_motor;
    logic done;

    washing_machine #(
        .FILL_TIME(20),
        .WASH_TIME(50),
        .DRAIN_TIME(20),
        .RINSE_TIME(30),
        .SPIN_TIME(40)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .door_closed(door_closed),
        .water_full(water_full),
        .water_valve(water_valve),
        .wash_motor(wash_motor),
        .drain_pump(drain_pump),
        .spin_motor(spin_motor),
        .done(done)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        reset = 1;
        start = 0;
        door_closed = 1;
        water_full = 0;

        #20;
        reset = 0;

        // Start washing cycle
        #10;
        start = 1;

        // Simulate water reaching full level
        #40;
        water_full = 1;

        // Complete the washing cycle
        #1500;
        start = 0;

        #50;
        $finish;
    end

endmodule