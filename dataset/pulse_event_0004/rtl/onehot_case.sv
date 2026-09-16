module pulse_event_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire clear,
    output reg  armed,
    output reg  pulse,
    output reg  latched
);
    localparam [2:0] ARMED = 3'b001;
    localparam [2:0] PULSE = 3'b010;
    localparam [2:0] LATCHED = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (trigger) ? PULSE : ((!trigger) ? ARMED : (ARMED));
            PULSE: next_state = LATCHED;
            LATCHED: next_state = (clear) ? ARMED : ((!clear) ? LATCHED : (LATCHED));
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
        latched = (state == LATCHED);
    end
endmodule
