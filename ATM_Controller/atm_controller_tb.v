
`timescale 1ns/1ps

module atm_controller_tb;

    reg clk;
    reg reset;
    reg card_insert;
    reg [3:0] pin;
    reg pin_enter;
    reg [1:0] transaction;
    reg transaction_select;
    reg confirm;

    wire card_valid;
    wire pin_valid;
    wire cash_dispense;
    wire balance_display;
    wire card_eject;
    wire error;
    wire [15:0] balance;
    wire [3:0] state;

    // Instantiate ATM controller
    atm_controller uut (
        .clk(clk),
        .reset(reset),
        .card_insert(card_insert),
        .pin(pin),
        .pin_enter(pin_enter),
        .transaction(transaction),
        .transaction_select(transaction_select),
        .confirm(confirm),
        .card_valid(card_valid),
        .pin_valid(pin_valid),
        .cash_dispense(cash_dispense),
        .balance_display(balance_display),
        .card_eject(card_eject),
        .error(error),
        .balance(balance),
        .state(state)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial
    begin
        clk = 0;
        reset = 1;

        card_insert = 0;
        pin = 0;
        pin_enter = 0;
        transaction = 0;
        transaction_select = 0;
        confirm = 0;

        #20;
        reset = 0;

        // Insert ATM card
        #10;
        card_insert = 1;

        #10;
        card_insert = 0;

        // Enter simplified PIN
        #20;
        pin = 4'd3;
        pin_enter = 1;

        #10;
        pin_enter = 0;

        // Select withdrawal
        #30;
        transaction = 2'b00;
        transaction_select = 1;

        #10;
        transaction_select = 0;

        // Confirm withdrawal
        #20;
        confirm = 1;

        #10;
        confirm = 0;

        // Wait for completion
        #100;

        $finish;
    end

    // Monitor output
    initial
    begin
        $monitor(
            "Time=%0t State=%d Balance=%d Card=%b Cash=%b Error=%b",
            $time, state, balance,
            card_valid, cash_dispense, error
        );
    end

endmodule
