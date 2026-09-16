module pulse_event_0008_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire enable,
    output reg  armed,
    output reg  pulse,
    output reg  disabled
);
    localparam [1:0] F_DISABLED     = 2'd0;
    localparam [1:0] F_ARMED        = 2'd1;
    localparam [1:0] F_PULSE        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_disabled_0 = (enable);
    wire guard_disabled_1 = (!enable);
    wire guard_armed_0 = (!enable);
    wire guard_armed_1 = (enable && trigger);
    wire guard_armed_2 = (enable && !trigger);
    wire guard_pulse_0 = (enable);
    wire guard_pulse_1 = (!enable);

    always @* begin
        next_state = state;
        case (state)
            F_DISABLED: begin
                if (guard_disabled_0)
                    next_state = F_ARMED;
                else if (guard_disabled_1)
                    next_state = F_DISABLED;
            end
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_DISABLED;
                else if (guard_armed_1)
                    next_state = F_PULSE;
                else if (guard_armed_2)
                    next_state = F_ARMED;
            end
            F_PULSE: begin
                if (guard_pulse_0)
                    next_state = F_ARMED;
                else if (guard_pulse_1)
                    next_state = F_DISABLED;
            end
            default: next_state = F_DISABLED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_DISABLED;
        else
            state <= next_state;
    end

    always @* begin
        armed = 1'b0;
        pulse = 1'b0;
        disabled = 1'b0;
        case (state)
            F_DISABLED: begin
                armed = 1'b0;
                pulse = 1'b0;
                disabled = 1'b1;
            end
            F_ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                disabled = 1'b0;
            end
            F_PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                disabled = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
