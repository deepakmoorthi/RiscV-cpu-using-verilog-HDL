
module traffic_light (
    input wire clk,
    input wire reset,
    output reg red,
    output reg yellow,
    output reg green
);

    // FSM state declaration
    parameter RED        = 2'b00,
              RED_YELLOW = 2'b01,
              GREEN      = 2'b10,
              YELLOW     = 2'b11;

    reg [1:0] state;
    reg [3:0] count;

    // State transition logic
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            state <= RED;
            count <= 0;
        end
        else
        begin
            case(state)

                RED:
                begin
                    if(count == 9)
                    begin
                        state <= RED_YELLOW;
                        count <= 0;
                    end
                    else
                        count <= count + 1;
                end

                RED_YELLOW:
                begin
                    if(count == 1)
                    begin
                        state <= GREEN;
                        count <= 0;
                    end
                    else
                        count <= count + 1;
                end

                GREEN:
                begin
                    if(count == 9)
                    begin
                        state <= YELLOW;
                        count <= 0;
                    end
                    else
                        count <= count + 1;
                end

                YELLOW:
                begin
                    if(count == 1)
                    begin
                        state <= RED;
                        count <= 0;
                    end
                    else
                        count <= count + 1;
                end

                default:
                begin
                    state <= RED;
                    count <= 0;
                end

            endcase
        end
    end

    // Output logic
    always @(*)
    begin
        red = 0;
        yellow = 0;
        green = 0;

        case(state)

            RED:
                red = 1;

            RED_YELLOW:
            begin
                red = 1;
                yellow = 1;
            end

            GREEN:
                green = 1;

            YELLOW:
                yellow = 1;

            default:
            begin
                red = 1;
            end

        endcase
    end

endmodule
