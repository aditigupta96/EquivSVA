module rate_limiter_0009_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire admit,
    input  wire return_token,
    output reg  [2:0] tokens,
    output wire allow
);

    wire [2:0] next_tokens;

    assign next_tokens = (return_token && (tokens < 3'd7)) ? (tokens + 3'd1) : ((!return_token && admit && (tokens > 3'd0)) ? (tokens - 3'd1) : (tokens));

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd3;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
endmodule
