module rate_limiter_0003_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire refill,
    input  wire consume,
    output reg  [2:0] tokens,
    output wire allow,
    output wire full
);

    wire [2:0] next_tokens;

    assign next_tokens = (consume && (tokens > 3'd0)) ? (tokens - 3'd1) : ((!consume && refill && (tokens < 3'd7)) ? (tokens + 3'd1) : (tokens));

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd4;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule
