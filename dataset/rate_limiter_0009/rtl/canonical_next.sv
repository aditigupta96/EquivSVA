module rate_limiter_0009_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire admit,
    input  wire return_token,
    output reg  [2:0] tokens,
    output wire allow
);

    reg [2:0] next_tokens;

    always @* begin
        if (return_token && (tokens < 3'd7)) next_tokens = tokens + 3'd1;
        else if (!return_token && admit && (tokens > 3'd0)) next_tokens = tokens - 3'd1;
        else next_tokens = tokens;
    end

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd3;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
endmodule
