module pulse_event_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  pulse,
    output reg  armed
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_FIRE         = 2'd1;
    localparam [1:0] F_WAIT_LOW     = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (event_in);
    wire guard_idle_1 = (!event_in);
    wire guard_wait_low_0 = (event_in);
    wire guard_wait_low_1 = (!event_in);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_FIRE;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_FIRE: begin
                next_state = F_WAIT_LOW;
            end
            F_WAIT_LOW: begin
                if (guard_wait_low_0)
                    next_state = F_WAIT_LOW;
                else if (guard_wait_low_1)
                    next_state = F_IDLE;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        pulse = 1'b0;
        armed = 1'b0;
        case (state)
            F_IDLE: begin
                pulse = 1'b0;
                armed = 1'b1;
            end
            F_FIRE: begin
                pulse = 1'b1;
                armed = 1'b0;
            end
            F_WAIT_LOW: begin
                pulse = 1'b0;
                armed = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
