module rate_limiter_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire reset_window,
    output wire ready_first,
    output wire ready_last,
    output wire granted,
    output wire locked
);
    localparam [2:0] S_FIRST  = 3'd0;
    localparam [2:0] S_GRANT1 = 3'd1;
    localparam [2:0] S_LAST   = 3'd2;
    localparam [2:0] S_GRANT2 = 3'd3;
    localparam [2:0] S_LOCKED = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_FIRST;
        end else begin
            if (state == S_FIRST) begin
                state <= (request) ? S_GRANT1 : ((!request) ? S_FIRST : (S_FIRST));
            end
            else if (state == S_GRANT1) begin
                state <= S_LAST;
            end
            else if (state == S_LAST) begin
                state <= (request) ? S_GRANT2 : ((!request) ? S_LAST : (S_LAST));
            end
            else if (state == S_GRANT2) begin
                state <= S_LOCKED;
            end
            else if (state == S_LOCKED) begin
                state <= (reset_window) ? S_FIRST : ((!reset_window) ? S_LOCKED : (S_LOCKED));
            end
            else begin
                state <= S_FIRST;
            end
        end
    end

    assign ready_first = (state == S_FIRST);
    assign ready_last = (state == S_LAST);
    assign granted = (state == S_GRANT1) || (state == S_GRANT2);
    assign locked = (state == S_LOCKED);
endmodule
