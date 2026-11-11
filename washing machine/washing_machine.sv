module washing_machine #(
    parameter integer FILL_TIME  = 20,
    parameter integer WASH_TIME  = 50,
    parameter integer DRAIN_TIME = 20,
    parameter integer RINSE_TIME = 30,
    parameter integer SPIN_TIME  = 40
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic door_closed,
    input  logic water_full,

    output logic water_valve,
    output logic wash_motor,
    output logic drain_pump,
    output logic spin_motor,
    output logic done
);

    typedef enum logic [2:0] {
        IDLE,
        FILL,
        WASH,
        DRAIN,
        RINSE,
        SPIN,
        DONE
    } state_t;

    state_t state, next_state;

    logic [31:0] timer;

    // State register and timer
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            timer <= 0;
        end
        else begin
            state <= next_state;

            if (state != next_state)
                timer <= 0;
            else
                timer <= timer + 1;
        end
    end

    // Next-state logic
    always_comb begin
        next_state = state;

        // Safety interlock
        if (!door_closed && state != IDLE &&
            state != DONE) begin
            next_state = IDLE;
        end
        else begin
            case (state)

                IDLE: begin
                    if (start && door_closed)
                        next_state = FILL;
                end

                FILL: begin
                    if (water_full ||
                        timer >= FILL_TIME - 1)
                        next_state = WASH;
                end

                WASH: begin
                    if (timer >= WASH_TIME - 1)
                        next_state = DRAIN;
                end

                DRAIN: begin
                    if (timer >= DRAIN_TIME - 1)
                        next_state = RINSE;
                end

                RINSE: begin
                    if (timer >= RINSE_TIME - 1)
                        next_state = SPIN;
                end

                SPIN: begin
                    if (timer >= SPIN_TIME - 1)
                        next_state = DONE;
                end

                DONE: begin
                    if (!start)
                        next_state = IDLE;
                end

                default: next_state = IDLE;

            endcase
        end
    end

    // Output logic
    always_comb begin
        water_valve = 0;
        wash_motor  = 0;
        drain_pump  = 0;
        spin_motor  = 0;
        done        = 0;

        case (state)

            FILL: begin
                water_valve = 1;
            end

            WASH: begin
                wash_motor = 1;
            end

            DRAIN: begin
                drain_pump = 1;
            end

            RINSE: begin
                water_valve = 1;
            end

            SPIN: begin
                spin_motor = 1;
            end

            DONE: begin
                done = 1;
            end

            default: begin
                // All outputs remain off
            end

        endcase
    end

endmodule