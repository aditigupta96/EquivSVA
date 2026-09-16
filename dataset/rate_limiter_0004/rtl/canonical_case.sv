module rate_limiter_0004_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire reset_window,
    output reg  ready_first,
    output reg  ready_last,
    output reg  granted,
    output reg  locked
);
    localparam [2:0] FIRST = 3'd0;
    localparam [2:0] GRANT1 = 3'd1;
    localparam [2:0] LAST  = 3'd2;
    localparam [2:0] GRANT2 = 3'd3;
    localparam [2:0] LOCKED = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            FIRST: next_state = (request) ? GRANT1 : ((!request) ? FIRST : (FIRST));
            GRANT1: next_state = LAST;
            LAST: next_state = (request) ? GRANT2 : ((!request) ? LAST : (LAST));
            GRANT2: next_state = LOCKED;
            LOCKED: next_state = (reset_window) ? FIRST : ((!reset_window) ? LOCKED : (LOCKED));
            default: next_state = FIRST;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= FIRST;
        else
            state <= next_state;
    end

    always @* begin
        ready_first = 1'b0;
        ready_last = 1'b0;
        granted = 1'b0;
        locked = 1'b0;
        case (state)
            FIRST: begin
                ready_first = 1'b1;
                ready_last = 1'b0;
                granted = 1'b0;
                locked = 1'b0;
            end
            GRANT1: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b1;
                locked = 1'b0;
            end
            LAST: begin
                ready_first = 1'b0;
                ready_last = 1'b1;
                granted = 1'b0;
                locked = 1'b0;
            end
            GRANT2: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b1;
                locked = 1'b0;
            end
            LOCKED: begin
                ready_first = 1'b0;
                ready_last = 1'b0;
                granted = 1'b0;
                locked = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
