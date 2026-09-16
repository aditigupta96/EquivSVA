module rate_limiter_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire reset_window,
    output reg  ready_first,
    output reg  ready_last,
    output reg  granted,
    output reg  locked
);
    localparam [4:0] FIRST = 5'b00001;
    localparam [4:0] GRANT1 = 5'b00010;
    localparam [4:0] LAST  = 5'b00100;
    localparam [4:0] GRANT2 = 5'b01000;
    localparam [4:0] LOCKED = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = FIRST;
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
        ready_first = (state == FIRST);
        ready_last = (state == LAST);
        granted = (state == GRANT1) || (state == GRANT2);
        locked = (state == LOCKED);
    end
endmodule
