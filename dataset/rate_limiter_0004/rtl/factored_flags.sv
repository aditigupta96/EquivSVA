module rate_limiter_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire reset_window,
    output reg  ready_first,
    output reg  ready_last,
    output reg  granted,
    output reg  locked
);
    localparam [2:0] F_FIRST        = 3'd0;
    localparam [2:0] F_GRANT1       = 3'd1;
    localparam [2:0] F_LAST         = 3'd2;
    localparam [2:0] F_GRANT2       = 3'd3;
    localparam [2:0] F_LOCKED       = 3'd4;

    reg [2:0] state, next_state;

    wire guard_first_0 = (request);
    wire guard_first_1 = (!request);
    wire guard_last_0 = (request);
    wire guard_last_1 = (!request);
    wire guard_locked_0 = (reset_window);
    wire guard_locked_1 = (!reset_window);

    always @* begin
        next_state = state;
        case (state)
            F_FIRST: begin
                if (guard_first_0)
                    next_state = F_GRANT1;
                else if (guard_first_1)
                    next_state = F_FIRST;
            end
            F_GRANT1: begin
                next_state = F_LAST;
            end
            F_LAST: begin
                if (guard_last_0)
                    next_state = F_GRANT2;
                else if (guard_last_1)
                    next_state = F_LAST;
            end
            F_GRANT2: begin
                next_state = F_LOCKED;
            end
            F_LOCKED: begin
                if (guard_locked_0)
                    next_state = F_FIRST;
                else if (guard_locked_1)
                    next_state = F_LOCKED;
            end
            default: next_state = F_FIRST;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_FIRST;
        else
            state <= next_state;
    end

    always @* begin
        ready_first = 1'b0;
        ready_last = 1'b0;
        granted = 1'b0;
        locked = 1'b0;
        case (state)
            F_FIRST: begin
                ready_first = 1'b1;
                ready_last = 1'b0;
                granted = 1'b0;
                locked = 1'b0;
            end
            F_GRANT1: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b1;
                locked = 1'b0;
            end
            F_LAST: begin
                ready_first = 1'b0;
                ready_last = 1'b1;
                granted = 1'b0;
                locked = 1'b0;
            end
            F_GRANT2: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b1;
                locked = 1'b0;
            end
            F_LOCKED: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b0;
                locked = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
