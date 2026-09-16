module rate_limiter_0003_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire refill,
    input  wire consume,
    output reg  [2:0] tokens,
    output wire allow,
    output wire full
);

    reg [2:0] next_tokens;

    always @* begin
        if (consume && (tokens > 3'd0)) next_tokens = tokens - 3'd1;
        else if (!consume && refill && (tokens < 3'd7)) next_tokens = tokens + 3'd1;
        else next_tokens = tokens;
    end

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd4;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule
