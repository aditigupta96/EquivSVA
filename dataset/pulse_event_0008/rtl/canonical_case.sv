module pulse_event_0008_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire enable,
    output reg  armed,
    output reg  pulse,
    output reg  disabled
);
    localparam [1:0] DISABLED = 2'd0;
    localparam [1:0] ARMED = 2'd1;
    localparam [1:0] PULSE = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
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
        armed = 1'b0;
        pulse = 1'b0;
        disabled = 1'b0;
        case (state)
            DISABLED: begin
                armed = 1'b0;
                pulse = 1'b0;
                disabled = 1'b1;
            end
            ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                disabled = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                disabled = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
