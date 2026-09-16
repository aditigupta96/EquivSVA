module pulse_event_0002_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  armed,
    output reg  pulse,
    output reg  blocked
);
    localparam [2:0] ARMED = 3'b001;
    localparam [2:0] PULSE = 3'b010;
    localparam [2:0] BLOCKED = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (event_in) ? PULSE : ((!event_in) ? ARMED : (ARMED));
            PULSE: next_state = BLOCKED;
            BLOCKED: next_state = (event_in) ? BLOCKED : ((!event_in) ? ARMED : (BLOCKED));
            default: next_state = ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = (state == ARMED);
        pulse = (state == PULSE);
        blocked = (state == BLOCKED);
    end
endmodule
