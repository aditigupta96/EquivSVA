module rate_limiter_0001_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire refill,
    input  wire consume,
    output reg  [2:0] tokens,
    output wire allow,
    output wire full
);

    always @(posedge clk) begin
        if (rst) begin
            tokens <= 3'd0;
        end
        else begin
            if (refill && (tokens < 3'd7)) tokens <= tokens + 3'd1;
            else if (!refill && consume && (tokens > 3'd0)) tokens <= tokens - 3'd1;
            else tokens <= tokens;
        end
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule
