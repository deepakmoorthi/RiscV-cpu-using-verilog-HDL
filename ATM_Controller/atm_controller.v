
module atm_controller (
    input wire clk,
    input wire reset,
    input wire card_insert,
    input wire [3:0] pin,
    input wire pin_enter,
    input wire [1:0] transaction,
    input wire transaction_select,
    input wire confirm,

    output reg card_valid,
    output reg pin_valid,
    output reg cash_dispense,
    output reg balance_display,
    output reg card_eject,
    output reg error,
    output reg [15:0] balance,
    output reg [3:0] state
);

    // FSM state declarations
    parameter IDLE       = 4'b0000,
              CARD_READ  = 4'b0001,
              PIN_ENTRY  = 4'b0010,
              PIN_VERIFY = 4'b0011,
              MENU       = 4'b0100,
              WITHDRAW   = 4'b0101,
              BALANCE    = 4'b0110,
              EJECT      = 4'b0111,
              ERROR      = 4'b1000;

    // Transaction selection
    parameter WITHDRAW_MONEY = 2'b00,
              CHECK_BALANCE  = 2'b01;

    reg [3:0] entered_pin;
    reg [1:0] attempts;

    reg [3:0] current_state;

    // FSM sequential logic
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            current_state <= IDLE;
            balance <= 16'd5000;
            entered_pin <= 0;
            attempts <= 0;
        end
        else
        begin
            case(current_state)

                IDLE:
                begin
                    if(card_insert)
                        current_state <= CARD_READ;
                end

                CARD_READ:
                begin
                    current_state <= PIN_ENTRY;
                end

                PIN_ENTRY:
                begin
                    if(pin_enter)
                    begin
                        entered_pin <= pin;
                        current_state <= PIN_VERIFY;
                    end
                end

                PIN_VERIFY:
                begin
                    if(entered_pin == 4'd3)
                    begin
                        // This example uses a 4-bit PIN input.
                        // Correct PIN is entered as four digits
                        // in the extended version.
                        current_state <= MENU;
                        attempts <= 0;
                    end
                    else
                    begin
                        attempts <= attempts + 1;

                        if(attempts == 2)
                            current_state <= EJECT;
                        else
                            current_state <= ERROR;
                    end
                end

                MENU:
                begin
                    if(transaction_select)
                    begin
                        if(transaction == WITHDRAW_MONEY)
                            current_state <= WITHDRAW;
                        else if(transaction == CHECK_BALANCE)
                            current_state <= BALANCE;
                        else
                            current_state <= ERROR;
                    end
                end

                WITHDRAW:
                begin
                    if(confirm)
                    begin
                        if(balance >= 16'd1000)
                        begin
                            balance <= balance - 16'd1000;
                            current_state <= EJECT;
                        end
                        else
                            current_state <= ERROR;
                    end
                end

                BALANCE:
                begin
                    current_state <= EJECT;
                end

                ERROR:
                begin
                    current_state <= PIN_ENTRY;
                end

                EJECT:
                begin
                    current_state <= IDLE;
                end

                default:
                    current_state <= IDLE;

            endcase
        end
    end

    // FSM output logic
    always @(*)
    begin
        card_valid = 0;
        pin_valid = 0;
        cash_dispense = 0;
        balance_display = 0;
        card_eject = 0;
        error = 0;

        case(current_state)

            IDLE:
                ;

            CARD_READ:
                card_valid = 1;

            PIN_ENTRY:
                ;

            PIN_VERIFY:
                pin_valid = 1;

            MENU:
                ;

            WITHDRAW:
                cash_dispense = 0;

            BALANCE:
                balance_display = 1;

            EJECT:
                card_eject = 1;

            ERROR:
                error = 1;

            default:
                error = 1;

        endcase
    end

    // Expose current FSM state
    always @(*)
    begin
        state = current_state;
    end

endmodule
