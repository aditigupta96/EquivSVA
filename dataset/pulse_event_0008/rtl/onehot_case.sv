module pulse_event_0008_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire enable,
    output reg  armed,
    output reg  pulse,
    output reg  disabled
);
    localparam [2:0] DISABLED = 3'b001;
    localparam [2:0] ARMED = 3'b010;
    localparam [2:0] PULSE = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = DISABLED;
        case (state)
            DISABLED: next_state = (enable) ? ARMED : ((!enable) ? DISABLED : (DISABLED));
            ARMED: next_state = (!enable) ? DISABLED : ((enable && trigger) ? PULSE : ((enable && !trigger) ? ARMED : (ARMED)));
            PULSE: next_state = (enable) ? ARMED : ((!enable) ? DISABLED : (PULSE));
            default: next_state = DISABLED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= DISABLED;
        else
            state <= next_state;
    end

    always @* begin
        armed = (state == ARMED);
        pulse = (state == PULSE);
        disabled = (state == DISABLED);
    end
endmodule
