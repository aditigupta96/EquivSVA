module pulse_event_0005_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  armed,
    output reg  qualifying,
    output reg  pulse,
    output reg  rearming
);
    localparam [2:0] F_ARMED        = 3'd0;
    localparam [2:0] F_HIGH1        = 3'd1;
    localparam [2:0] F_PULSE        = 3'd2;
    localparam [2:0] F_WAIT_LOW     = 3'd3;
    localparam [2:0] F_LOW1         = 3'd4;

    reg [2:0] state, next_state;

    wire guard_armed_0 = (event_in);
    wire guard_armed_1 = (!event_in);
    wire guard_high1_0 = (event_in);
    wire guard_high1_1 = (!event_in);
    wire guard_wait_low_0 = (!event_in);
    wire guard_wait_low_1 = (event_in);
    wire guard_low1_0 = (!event_in);
    wire guard_low1_1 = (event_in);

    always @* begin
        next_state = state;
        case (state)
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_HIGH1;
                else if (guard_armed_1)
                    next_state = F_ARMED;
            end
            F_HIGH1: begin
                if (guard_high1_0)
                    next_state = F_PULSE;
                else if (guard_high1_1)
                    next_state = F_ARMED;
            end
            F_PULSE: begin
                next_state = F_WAIT_LOW;
            end
            F_WAIT_LOW: begin
                if (guard_wait_low_0)
                    next_state = F_LOW1;
                else if (guard_wait_low_1)
                    next_state = F_WAIT_LOW;
            end
            F_LOW1: begin
                if (guard_low1_0)
                    next_state = F_ARMED;
                else if (guard_low1_1)
                    next_state = F_WAIT_LOW;
            end
            default: next_state = F_ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = 1'b0;
        qualifying = 1'b0;
        pulse = 1'b0;
        rearming = 1'b0;
        case (state)
            F_ARMED: begin
                armed = 1'b1;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b0;
            end
            F_HIGH1: begin
                armed = 1'b0;
                qualifying = 1'b1;
                pulse = 1'b0;
                rearming = 1'b0;
            end
            F_PULSE: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b1;
                rearming = 1'b0;
            end
            F_WAIT_LOW: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b1;
            end
            F_LOW1: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
