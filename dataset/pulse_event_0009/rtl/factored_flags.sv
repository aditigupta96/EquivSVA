module pulse_event_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire complete,
    output reg  waiting,
    output reg  pulse,
    output reg  idle
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT         = 2'd1;
    localparam [1:0] F_PULSE        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (request);
    wire guard_idle_1 = (!request);
    wire guard_wait_0 = (complete);
    wire guard_wait_1 = (!complete);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_WAIT;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_WAIT: begin
                if (guard_wait_0)
                    next_state = F_PULSE;
                else if (guard_wait_1)
                    next_state = F_WAIT;
            end
            F_PULSE: begin
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
        waiting = 1'b0;
        pulse = 1'b0;
        idle = 1'b0;
        case (state)
            F_IDLE: begin
                waiting = 1'b0;
                pulse = 1'b0;
                idle = 1'b1;
            end
            F_WAIT: begin
                waiting = 1'b1;
                pulse = 1'b0;
                idle = 1'b0;
            end
            F_PULSE: begin
                waiting = 1'b0;
                pulse = 1'b1;
                idle = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
