module pulse_event_0003_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  waiting_high,
    output reg  pulse,
    output reg  waiting_low
);
    localparam [1:0] F_WAIT_HIGH    = 2'd0;
    localparam [1:0] F_PULSE        = 2'd1;
    localparam [1:0] F_WAIT_LOW     = 2'd2;

    reg [1:0] state, next_state;

    wire guard_wait_high_0 = (event_in);
    wire guard_wait_high_1 = (!event_in);
    wire guard_wait_low_0 = (!event_in);
    wire guard_wait_low_1 = (event_in);

    always @* begin
        next_state = state;
        case (state)
            F_WAIT_HIGH: begin
                if (guard_wait_high_0)
                    next_state = F_WAIT_LOW;
                else if (guard_wait_high_1)
                    next_state = F_WAIT_HIGH;
            end
            F_PULSE: begin
                next_state = F_WAIT_HIGH;
            end
            F_WAIT_LOW: begin
                if (guard_wait_low_0)
                    next_state = F_PULSE;
                else if (guard_wait_low_1)
                    next_state = F_WAIT_LOW;
            end
            default: next_state = F_WAIT_HIGH;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_WAIT_HIGH;
        else
            state <= next_state;
    end

    always @* begin
        waiting_high = 1'b0;
        pulse = 1'b0;
        waiting_low = 1'b0;
        case (state)
            F_WAIT_HIGH: begin
                waiting_high = 1'b1;
                pulse = 1'b0;
                waiting_low = 1'b0;
            end
            F_PULSE: begin
                waiting_high = 1'b0;
                pulse = 1'b1;
                waiting_low = 1'b0;
            end
            F_WAIT_LOW: begin
                waiting_high = 1'b0;
                pulse = 1'b0;
                waiting_low = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
