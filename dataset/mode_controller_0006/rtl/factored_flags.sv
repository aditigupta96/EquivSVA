module mode_controller_0006_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire unlock,
    input  wire lock,
    input  wire operate,
    output reg  locked,
    output reg  ready,
    output reg  active
);
    localparam [1:0] F_LOCKED       = 2'd0;
    localparam [1:0] F_READY        = 2'd1;
    localparam [1:0] F_ACTIVE       = 2'd2;

    reg [1:0] state, next_state;

    wire guard_locked_0 = (unlock);
    wire guard_locked_1 = (!unlock);
    wire guard_ready_0 = (lock);
    wire guard_ready_1 = (!lock && operate);
    wire guard_ready_2 = (!lock && !operate);
    wire guard_active_0 = (lock);
    wire guard_active_1 = (!lock && !operate);
    wire guard_active_2 = (!lock && operate);

    always @* begin
        next_state = state;
        case (state)
            F_LOCKED: begin
                if (guard_locked_0)
                    next_state = F_READY;
                else if (guard_locked_1)
                    next_state = F_LOCKED;
            end
            F_READY: begin
                if (guard_ready_0)
                    next_state = F_LOCKED;
                else if (guard_ready_1)
                    next_state = F_ACTIVE;
                else if (guard_ready_2)
                    next_state = F_READY;
            end
            F_ACTIVE: begin
                if (guard_active_0)
                    next_state = F_LOCKED;
                else if (guard_active_1)
                    next_state = F_READY;
                else if (guard_active_2)
                    next_state = F_ACTIVE;
            end
            default: next_state = F_LOCKED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_LOCKED;
        else
            state <= next_state;
    end

    always @* begin
        locked = 1'b0;
        ready = 1'b0;
        active = 1'b0;
        case (state)
            F_LOCKED: begin
                locked = 1'b1;
                ready = 1'b0;
                active = 1'b0;
            end
            F_READY: begin
                locked = 1'b0;
                ready = 1'b1;
                active = 1'b0;
            end
            F_ACTIVE: begin
                locked = 1'b0;
                ready = 1'b0;
                active = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
