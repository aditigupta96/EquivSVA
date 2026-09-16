module protocol_controller_0006_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire acquire,
    input  wire release,
    output reg  waiting,
    output reg  held
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT         = 2'd1;
    localparam [1:0] F_HELD         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (acquire);
    wire guard_idle_1 = (!acquire);
    wire guard_wait_0 = (acquire);
    wire guard_wait_1 = (!acquire);
    wire guard_held_0 = (release);
    wire guard_held_1 = (!release);

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
                    next_state = F_HELD;
                else if (guard_wait_1)
                    next_state = F_WAIT;
            end
            F_HELD: begin
                if (guard_held_0)
                    next_state = F_IDLE;
                else if (guard_held_1)
                    next_state = F_HELD;
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
        held = 1'b0;
        case (state)
            F_IDLE: begin
                waiting = 1'b0;
                held = 1'b0;
            end
            F_WAIT: begin
                waiting = 1'b1;
                held = 1'b0;
            end
            F_HELD: begin
                waiting = 1'b0;
                held = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
