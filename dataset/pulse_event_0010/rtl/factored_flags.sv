module pulse_event_0010_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire arm,
    input  wire trigger,
    input  wire rearm,
    output reg  disarmed,
    output reg  armed,
    output reg  pulse,
    output reg  spent
);
    localparam [1:0] F_DISARMED     = 2'd0;
    localparam [1:0] F_ARMED        = 2'd1;
    localparam [1:0] F_PULSE        = 2'd2;
    localparam [1:0] F_SPENT        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_disarmed_0 = (arm);
    wire guard_disarmed_1 = (!arm);
    wire guard_armed_0 = (trigger);
    wire guard_armed_1 = (!trigger);
    wire guard_spent_0 = (rearm);
    wire guard_spent_1 = (!rearm);

    always @* begin
        next_state = state;
        case (state)
            F_DISARMED: begin
                if (guard_disarmed_0)
                    next_state = F_ARMED;
                else if (guard_disarmed_1)
                    next_state = F_DISARMED;
            end
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_PULSE;
                else if (guard_armed_1)
                    next_state = F_ARMED;
            end
            F_PULSE: begin
                next_state = F_SPENT;
            end
            F_SPENT: begin
                if (guard_spent_0)
                    next_state = F_ARMED;
                else if (guard_spent_1)
                    next_state = F_SPENT;
            end
            default: next_state = F_DISARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_DISARMED;
        else
            state <= next_state;
    end

    always @* begin
        disarmed = 1'b0;
        armed = 1'b0;
        pulse = 1'b0;
        spent = 1'b0;
        case (state)
            F_DISARMED: begin
                disarmed = 1'b1;
                armed = 1'b0;
                pulse = 1'b0;
                spent = 1'b0;
            end
            F_ARMED: begin
                disarmed = 1'b0;
                armed = 1'b1;
                pulse = 1'b0;
                spent = 1'b0;
            end
            F_PULSE: begin
                disarmed = 1'b0;
                armed = 1'b0;
                pulse = 1'b1;
                spent = 1'b0;
            end
            F_SPENT: begin
                disarmed = 1'b0;
                armed = 1'b0;
                pulse = 1'b0;
                spent = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
